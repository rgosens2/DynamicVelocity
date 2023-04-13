//=============================================================================
//  MuseScore
//  
//  Dynamic Velocity Plugin
//  
//  See: https://musescore.org/en/node/320499
//  Home Developers' handbook Plugin development Plugins for 3.x Boilerplates, snippets, use cases and QML notes
//  Use Case: Element Explorer
//  
//  rgos
//  HACK: We are using this code as a boilerplate to find each note's absolute velocity.
//  We print a note's velocity as set by the dynamics in the score as staff text.
//  This will be the same as a note's Absolute Velocity as seen in the Piano Roll editor
//  minus any modifications by veloOffset and/or hairpins and cresc./dim.
//  
//  Requires a selection. Only tested with one staff. No grace notes.
//  
//  Version 1.0
//=============================================================================


//=============================================================================
//  MuseScore Plugin
//
//  This plugin will list to the console window the key -> value pairs for 
//  individual items (elements) selected on a score. E.g., open a score,
//  select an individual note, then run this plugin from the Plugin Creator
//  window to see that note's properties list in the console output.
//
//  IF you intend to examine more than a few elements at once you might want
//  to modify this to have it write the results out to a text file rather
//  than the console window.
//
//  I use this to examine what properties are available to my plugin for a
//  given element (e.g., what can I learn about a 'note,' or a 
//  'time signature')?
//=============================================================================



//------------------------------------------------------------------------------
//  1.0: 04/24/2021 | First created
//------------------------------------------------------------------------------

// Am assuming QtQuick version 5.9 for Musescore 3.x plugins.
import QtQuick 2.0
import QtQuick.Dialogs 1.1
import MuseScore 3.0

MuseScore {
    // version:  "1.0"
    // description: "Examine an Element"
    // menuPath: "Plugins.DEV.Examine an Element"
    version:  "1.0"
    description: "Print each note's dynamic velocity as staff text"
    menuPath: "Plugins.DEV.Dynamic Velocity"

    // JS global var
    property var velo: 80
    property var dynalist: []
    property var oElementsListOrig: []

    function showObject(mscoreElement) {
        //	PURPOSE: Lists all key -> value pairs of the passed in
        //element to the console.
        //	NOTE: To reduce clutter I am filtering out any 
        //'undefined' properties. (The MuseScore 'element' object
        //is very flat - it will show many, many properties for any
        //given element type; but for any given element many, if not 
        //most, of these properties will return 'undefined' as they 
        //are not all valid for all element types. If you want to see 
        //this comment out the filter.)


        // TEST: If it is a dynamic find out the velocity and which note it is
        // attached to. Then print that velocity above the note.
        // Also need to find out the note's tick if we want to build a dynamics list.
        // TEST2: Would it be possible to do this with a cursor: run over every note
        // and find if there is a dynamic attached. If so, print out the velocity.
        // If that is possible it would be much easier to find velocity in Notelist.
        // If not we first have to create a dynamics list using selection and then
        // check every note against that list.
        // YESS: method 1 (selection) works. We can find dynamics, velocity and tick.
        if (mscoreElement.name == 'Dynamic') {
            console.log('Dyna')
            console.log(mscoreElement['velocity'])
            console.log(mscoreElement['parent'].name) // A Dynamic's parent is a Segment
            console.log(mscoreElement['parent'].tick) // And Segments have a tick

            // Add text via cursor
            // var cursor = curScore.newCursor()
            // cursor.rewindToTick(mscoreElement['parent'].tick)
            // var text = newElement(Element.STAFF_TEXT);
            // text.text = '<font size="8"/>' + mscoreElement['velocity']
            // cursor.add(text)

            // save for following notes
            velo = mscoreElement['velocity']

            // build dynamics list
            var tick = mscoreElement['parent'].tick
            if (!dynalist[tick]) // only the first dynamic per tick
                dynalist[tick] = velo
        }

        // NOTE: This works OK now except when there is a dynamic in voice 2 or higher
        // Every dynamic in every voice should reset the velocity for the entire channel
        // So to find the correct velocity we better create a dynamics list with ticks
        // ALSO: when there is a whole rest in voice 1, text position is off for other voices
        // WHY?: tick position is OK
        // OKOK: probably because we forgot to indicate the correct voice
        // YESS: text is now correctly placed and in correct color
        // ALSO: When there are conflicting dynamics on a note or chord (e.g. ppp and fff)
        // the first one added has priority. How can we check that?
        // OKOK: Seems the first we find here was also added first. So for every tick
        // we should only take the first dynamic encountered.
        // ALSO: the text for the first note is positioned higher and if we select all
        // it prints an extra 33 velo (probably from the last Dynamic in voice 1). Why?
        // OKOK: printing higher was because of a stray empty staff text; the printing
        // 33 is because selecting all sets tick to 0
        if (mscoreElement.name == 'Note') {
            // TODO: how can we find a note's tick
            // It has Chord as parent which has no tick
            // So must we use a cursor?
            // NONO: we can take the parent's parent
            var p = mscoreElement['parent'] // Chord
            var pp = p['parent']            // Segment
            console.log(pp.name) // YESS: Segment <- Chord <- Note
            // But see: https://musescore.github.io/MuseScore_PluginAPI_Docs/plugins/html/inherits.html
            // This is not the same as the class inheritance relation

            // Add text via cursor
            var cursor = curScore.newCursor()
            cursor.voice = mscoreElement['voice']
            cursor.rewindToTick(pp.tick)
            var text = newElement(Element.STAFF_TEXT);
            text.text = '<font size="8"/>' + velo
            //cursor.add(text)
            //console.log('Add')
            //console.log(mscoreElement['parent'].name) // Chord has no tick
            // NONO: we can add via note itself
            // ALAS: Note::add() does not work for staff text
            //var text = newElement(Element.STAFF_TEXT);
            //text.text = '<font size="8"/>' + 'QQQ'
            //mscoreElement.add(text)
            
            // Interesting:
            // QQmlListProperty< Ms::PluginAPI::Element > 	elements
            // List of other elements attached to this note: fingerings, symbols, bends etc. More...
            // NOGO:
            // for (var el in mscoreElement['elements']) {
            //     console.log(el.type + ' ' + el.name);
            // }
        }
        /////////////////////////////


        
        if (Object.keys(mscoreElement).length > 0) {
            Object.keys(mscoreElement)
                .filter(function(key) {
                    return mscoreElement[key] != null;
                })
                .forEach(function eachKey(key) {
                    console.log("---- ---- ", key, " : <", mscoreElement[key], ">");
                    // TEST: get spannerTick(s)
                    // ALAS: this is always 0/1 so the Plugin API does not give access to
                    // a spanner's start and duration
                    // See: https://musescore.org/en/node/299997
                    //if (key == "spannerTick") console.log('spannerTick.ticks: ' + mscoreElement[key].ticks + ' spannerTick.str: ' + mscoreElement[key].str)
                    //if (key == "spannerTicks") console.log('spannerTicks.ticks: ' + mscoreElement[key].ticks)
                });
        }
    }

    function printVelo(mscoreElement) {
        // SHIT: dynamics attached to a rest will not enter here but they must 
        // be considered for they will reset the velo
        // Mmm, dynalist werkt toch niet zo lekker. We hebben toch Dynamic nodig
        // om de velo te resetten.
        // HELL: zo werkt het nog steeds niet goed voor voices.
        // Probleem is dat we door voices loopen maar dat elke dynamic
        // voor het hele kanaal (dus alle voices) geldt.
        // We zouden juist Dynamic niet meer nodig hebben, daarvoor hebben we dynalist
        // OKOK: looks good now: this takes care of a Dynamic attached to a Rest
        // which should also reset the velocity
        if (mscoreElement.name == 'Dynamic') {
            for (var key in dynalist) {
                if (key == mscoreElement['parent'].tick) {
                    velo = dynalist[key]
                }
            }
        }

        if (mscoreElement.name == 'Note') {
            //console.log('QQQ')
            // TODO: how can we find a note's tick
            // It has Chord as parent which has no tick
            // So must we use a cursor?
            // NONO: we can take the parent's parent
            var p = mscoreElement['parent'] // Chord
            var pp = p['parent']            // Segment
            console.log(pp.name) // YESS: Segment <- Chord <- Note
            // But see: https://musescore.github.io/MuseScore_PluginAPI_Docs/plugins/html/inherits.html
            // This is not the same as the class inheritance relation

            // Add text via cursor
            var cursor = curScore.newCursor()
            cursor.voice = mscoreElement['voice']
            // TEST: set the correct staff
            // YESS: works 
            // TODO: need to rebuild the dynalist for every staff
            cursor.staffIdx = mscoreElement['track']/4
            cursor.rewindToTick(pp.tick)
            var text = newElement(Element.STAFF_TEXT);
            // TODO: dit gaat fout bij een selection waarvan de beginnoot geen dynamic heeft
            // en volgt op een noot met elke andere dynamic dan mf. We moeten dus eigenlijk
            // een dynalist maken voor de gehele staff en dan terugzoeken naar de laatste
            // dynamic voor de selection
            // Of itereren over de hele staff en alleen bij de geselecteerde noten text
            // printen. Dan gaat het ook goed.
            // TODO: het gaat ook fout als we geen range selection hebben maar alleen noten
            // selecteren
            // Het beste is eerst programmatisch de hele score selecteren, dan van elke staff
            // een dynalist maken (grand staff as one), en dan itereren over de noten.
            // Probleem is dat je dan waarschijnlijk wel je oorsponkelijke selectie verliest.
            // HELL: we kunnen het ook hierbij laten: als er geen dynamic is geselecteerd
            // defaulten we gewoon tot velo 80 (mf)
            text.text = '<font size="12"/>' + 80 // default velo 80

            for (var key in dynalist) {
                if (pp.tick == key) {
                    text.text = '<font size="12"/>' + dynalist[key]
                    // save for following notes
                    // SHIT: dit gaat fout wanneer er een Dynamic aan een Rest is 
                    // verbonden. We komen hier dan helemaal niet in
                    // DONE: see above: we check for Dynamic
                    velo = dynalist[key]
                    break
                }
            }
            for (var key in dynalist) {
                if (pp.tick > key) {
                    text.text = '<font size="12"/>' + velo
                    //break
                }
            }

            // Only print velo for notes in original selection
            // ALAS: cannot compare objects, probably because we made a shallow copy
            // HACK: compare tick and pitch
            for (var i=0; i<oElementsListOrig.length; i++) {
                //curScore.startCmd()
                if (pp.tick == oElementsListOrig[i]['parent']['parent'].tick &&
                    mscoreElement['pitch'] == oElementsListOrig[i]['pitch'])
                    cursor.add(text)
                //curScore.endCmd()
            }
        }

        // TEST: print velo by iterating over notes

        //////
    }


//==== PLUGIN RUN-TIME ENTRY POINT =============================================

    onRun: {
        console.log("********** RUNNING **********\n");

        // NONO
        //var velo = 80 // default velocity

        var oCursor = curScore.newCursor() // now used

        // TEST: programmatically select all to build a staff's complete dynalist
        // OKOK: Works but we lose the original selection so must save that first
        // and then reselect with curScore.selection.select() or curScore.selection.selectRange()
        // What a hassle. But let's try it because we can use the saved selection to find out
        // which notes need velo text and then only print those.
        // NOTE: cannot save like this: it is just a pointer
        // See: https://www.freecodecamp.org/news/how-to-clone-an-array-in-javascript-1d3183468f6a/
        // save original selection
        //var oElementsListOrig = []  
        //oElementsListOrig = [...curScore.selection.elements] // Alas: ES6 too modern
        // NOTE: this only makes a shallow copy
        for (var i=0; i<curScore.selection.elements.length; i++) {
            oElementsListOrig[i] = curScore.selection.elements[i]
        }
        //console.log(oElementsListOrig.length) // OK here
        //Qt.quit(); // OK to check but why is this not really quitting?
        var startTick = 0
        var endTick = 0
        oCursor.rewind(0)
        while (oCursor.next()) {
            if (oCursor.segment) {
                endTick = oCursor.segment.tick
            }
            //console.log(endTick)
        }
        // NOTE: need start/endCmd() around every score modification otherwise plugin sees nothing selected
        // ALSO: this fucks up Undo/Redo wheras it should make that work
        // OKOK: works now: we also had to put start/endCmd() round printVelo()
        curScore.startCmd()        
        curScore.selection.selectRange(startTick, endTick, 0, curScore.nstaves)
        curScore.endCmd()
        // ////////////////////////

        
        //Make sure something is selected.
        if (curScore.selection.elements.length==0) {
            console.log("**** NOTHING SELECTED");
            console.log("**** Select an element on the score and try again");
            console.log("****");
        }
        //We have a selection, now explode it...
        else { 
            var oElementsList = curScore.selection.elements;

            // TODO: in order to make multiple staff selection work we have to check
            // for staffIdx = mscoreElement['track']/4 here and split up oElementsList
            // per staff

            console.log("");
            console.log("---- | Number of Selected Elements to Examine: [", oElementsList.length, "]");
            console.log("");
            for (var i=0; i<oElementsList.length; i++) {
                console.log("------------------------------------------------------------------------");
                console.log("---- Element# [", i, "] is a || ", oElementsList[i].name, " ||");
                console.log("");
                showObject(oElementsList[i]);
                console.log("");
                console.log("---- END Element# [", i, "]");
                console.log("------------------------------------------------------------------------");
                console.log("");
            }

            //////////
            curScore.startCmd()
            for (var i=0; i<oElementsList.length; i++) {                
                printVelo(oElementsList[i])                
            }
            curScore.endCmd()
            //////////
        }

        // show dynamics list
        for (var key in dynalist) {
            console.log("tick " + key + " has velo " + dynalist[key])			
        }

        // restore original selection
        // TODO: print velo text only for notes in the original selection
        curScore.startCmd()
        //curScore.selection.clear()
        // HELL: why are we getting length 289 here and the correct number at the start
        // Even with a global var
        // OKOK: it is a pointer, so if we set a select all, this get automatically updated
        // We must save the selection list to a new array
        console.log(oElementsListOrig.length)
        for (var i=0; i<oElementsListOrig.length; i++) {
            if (i==0)
                curScore.selection.select(oElementsListOrig[i], false)
            else
                curScore.selection.select(oElementsListOrig[i], true)
        }
        curScore.endCmd()
        //////////

        console.log("********** QUITTING **********\n");
        Qt.quit();

    } //END OnRun


} // END Musescore
