(
var root=thisProcess.nowExecutingPath.dirname.dirname,menu;
(root+/+"MicroMS-01.scd").load;
AppClock.sched(0.5,{
    try {
        menu=~microMS[\window].view.children.detect { |v| v.isKindOf(PopUpMenu) and: { v.items.size==53 } };
        if(menu.isNil or: { ~microMS[\factoryPresetFiles].size!=50 }) { Error("Factory menu is missing presets").throw };
        menu.value=3; menu.doAction;
        if(~microMS[\edo]!=19 or: { ~microMS[\message].beginsWith("Loaded 01-").not }) { Error("First menu preset failed to load").throw };
        menu.value=52; menu.doAction;
        if(~microMS[\edo]!=96 or: { ~microMS[\channels]!=32 } or: { ~microMS[\message].beginsWith("Loaded 50-").not }) { Error("Last menu preset failed to load").throw };
        "PASS: all fifty factory entries are visible; first and last load from the native preset menu.".postln;
        ~microMS[\close].value; 0.exit
    } { |error| error.reportError; ~microMS[\close].value; 1.exit };
    nil
})
)
