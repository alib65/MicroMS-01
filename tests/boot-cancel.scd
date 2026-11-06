(
var root=thisProcess.nowExecutingPath.dirname.dirname,tries=0;
(root+/+"MicroMS-01.scd").load;
~microMS[\boot].value;
~microMS[\close].value;
AppClock.sched(1,{
    tries=tries+1;
    if(~microMS[\server].serverBooting or: { ~microMS[\server].serverRunning }) {
        if(tries>20) { "FAIL: closing while booting left a server running".postln; 1.exit; nil } { 1 }
    } {
        "PASS: closing while booting leaves no audio server running".postln;
        0.exit; nil
    }
});
)
