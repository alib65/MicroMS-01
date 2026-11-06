(
var root=thisProcess.nowExecutingPath.dirname.dirname;
(root+/+"MicroMS-01.scd").load;
AppClock.sched(3,{
    if(~microMS[\window].notNil) {
        "PASS: native window created.".postln;
        Image.fromWindow(~microMS[\window]).write(root+/+"assets/MicroMS-01.png");
        ~microMS[\save].value("/tmp/microms-gui-patch.microms");
        ~microMS[\load].value("/tmp/microms-gui-patch.microms");
        ("After load modules: "++~microMS[\modules].size).postln;
    };
    ~microMS[\close].value;
    0.exit; nil
});
)
