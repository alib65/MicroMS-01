(
var root=thisProcess.nowExecutingPath.dirname.dirname,assert,hit,clock,seq,param,old;
assert={ |value,msg| if(value.not) { Error(msg).throw } { ("PASS: "++msg).postln } };
(root+/+"MicroMS-01.scd").load;
AppClock.sched(1,{
    try {
        clock=~microMS[\modules].detect { |m| m[\type]==\clock };
        seq=~microMS[\modules].detect { |m| m[\type]==\sequencer };
        hit={ |id,kind,key,direction| ~microMS[\hitRegions].detect { |h|
            (h[\module][\id]==id) and: { h[\kind]==kind } and: { if(kind==\jack){h[\port][\key]==key and: { h[\direction]==direction }}{true} }
        } };
        param=hit.value(clock[\id],\knob); old=clock[\params][\bpm];
        ~microMS[\rack].mouseDownAction.value(~microMS[\rack],param[\rect].center.x,param[\rect].center.y,0,0,1);
        ~microMS[\rack].mouseMoveAction.value(~microMS[\rack],param[\rect].center.x,param[\rect].center.y-30,0);
        ~microMS[\rack].mouseUpAction.value(~microMS[\rack],param[\rect].center.x,param[\rect].center.y-30);
        assert.value(clock[\params][\bpm]>old,"native knob gesture changes parameter");
        param=hit.value(seq[\id],\jack,\clock,\in);
        ~microMS[\rack].mouseDownAction.value(~microMS[\rack],param[\point].x,param[\point].y,0,1,1);
        assert.value(~microMS[\cables].any { |c| c[\to]==seq[\id] and: { c[\input]==\clock } }.not,"right-click removes input cable");
        param=hit.value(clock[\id],\jack,\clock,\out);
        ~microMS[\rack].mouseDownAction.value(~microMS[\rack],param[\point].x,param[\point].y,0,0,1);
        param=hit.value(seq[\id],\jack,\clock,\in);
        ~microMS[\rack].mouseMoveAction.value(~microMS[\rack],param[\point].x,param[\point].y,0);
        ~microMS[\rack].mouseUpAction.value(~microMS[\rack],param[\point].x,param[\point].y);
        assert.value(~microMS[\cables].any { |c| c[\to]==seq[\id] and: { c[\input]==\clock } },"dragging between native jacks connects cable");
        ~microMS[\clear].value;
        ~microMS[\catalog].keys.do { |id| ~microMS[\add].value(id) };
        ~microMS[\window].bounds=Rect(25,40,1320,780);
        AppClock.sched(1,{
            assert.value(~microMS[\modules].size==81,"all module panels instantiate");
            ~microMS[\preset].value(\orbit);
            AppClock.sched(0.5,{
                Image.fromWindow(~microMS[\window]).write(root+/+"assets/MicroMS-01-compact.png");
                ~microMS[\close].value; "PASS: native interaction checks completed.".postln; 0.exit; nil
            }); nil
        }); nil
    } { |err| err.reportError; ~microMS[\close].value; 1.exit; nil }
});
)
