(
var root=thisProcess.nowExecutingPath.dirname.dirname, checks=0;
(root+/+"MicroMS-01.scd").load;
~microMS[\volume]=0; ~microMS[\boot].value;
AppClock.sched(1,{
    if(~microMS[\running]) {
        "PASS: private audio server booted, rack instantiated.".postln;
        ~microMS[\play].value(true);
        ~microMS[\server].sendMsg(\g_queryTree,~microMS[\group].nodeID,0);
        AppClock.sched(2,{
            ~microMS[\preset].value(\glass);
            ~microMS[\save].value("/tmp/microms-realtime-patch.microms");
            ~microMS[\load].value(root+/+"presets/Orbital-19.microms");
            ~microMS[\volume]=0; ~microMS[\play].value(true);
            AppClock.sched(2,{
                ~microMS[\record].value;
                AppClock.sched(3,{
                    ~microMS[\record].value;
                    ~microMS[\selected]=~microMS[\modules].detect { |m| m[\type]==\ambisonic };
                    ~microMS[\recordSource]=1;
                    AppClock.sched(0.3,{
                        ~microMS[\record].value;
                        AppClock.sched(3,{
                            ~microMS[\record].value; ~microMS[\close].value;
                            "PASS: transport, preset switch, save/load, monitor recording, AmbiX export and shutdown.".postln;
                            AppClock.sched(1,{ 0.exit; nil }); nil
                        }); nil
                    }); nil
                }); nil
            }); nil
        }); nil
    } {
        checks=checks+1;
        if(checks>35) { "FAIL: realtime engine did not boot".postln; ~microMS[\close].value; 1.exit; nil } { 1 }
    }
});
)
