(
var root=thisProcess.nowExecutingPath.dirname.dirname,tries=0;
(root+/+"MicroMS-01.scd").load;
~microMS[\volume]=0; ~microMS[\boot].value;
AppClock.sched(1,{
    if(~microMS[\running]) {
        ~microMS[\selected]=~microMS[\modules].detect { |m| m[\type]==\vco };
        ~microMS[\window].view.children.detect { |v| v.isKindOf(Button) and: { v.states[0][0]=="SCOPE" } }.doAction;
        AppClock.sched(1,{
            if(~microMS[\scopeWindow].notNil) { "PASS: live native ScopeView opened on private server".postln };
            ~microMS[\close].value;
            AppClock.sched(1,{ 0.exit; nil }); nil
        }); nil
    } {
        tries=tries+1;
        if(tries>30) { "FAIL: scope engine did not start".postln; ~microMS[\close].value; 1.exit; nil } { 1 }
    }
});
)
