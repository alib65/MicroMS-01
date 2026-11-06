{
    |a|
    var globals, nodeArgs, allocate, order, json, quote, parseNumbers;
    a[\defs]=IdentityDictionary.new;
    a[\status] = { |msg| a[\message]=msg; msg.postln; if(a[\statusView].notNil) { a[\statusView].string=msg } };
    a[\redraw] = { if(a[\rack].notNil) { a[\rack].refresh }; if(a[\refreshUI].notNil) { a[\refreshUI].value } };
    a[\find] = { |id| a[\modules].detect { |m| m[\id]==id } };
    a[\spec] = { |m| a[\catalog][m[\type]] };
    globals = {
        [\global_edo,a[\edo],\global_root,a[\rootHz],\global_channels,a[\channels],\global_play,a[\playing].binaryValue,
            \global_mode,a[\mode],\global_volume,a[\volume],\global_hardware,a[\hardware],\global_inputs,a[\inputs] ? 0]
    };
    nodeArgs = { |m|
        var spec=a[\spec].value(m), args=globals.value ++ [\moduleID,m[\id]];
        spec[\params].do { |p| args=args++[p[\key],m[\params][p[\key]]] };
        spec[\inputs].do { |p| args=args++[("inputBus_"++p[\key]).asSymbol,a[\zero].index,("has_"++p[\key]).asSymbol,0] };
        spec[\outputs].do { |p| args=args++[("outputBus_"++p[\key]).asSymbol,m[\buses][p[\key]].index] };
        if(spec[\family]==\sequencer) { args=args++[\steps,m[\steps],\gates,m[\gates]] };
        if(spec[\family]==\gates) { 4.do { |j| args=args++[("lane"++j).asSymbol,m[\patterns][j]] } };
        if(spec[\family]==\sampler) { args=args++[\buf,(m[\buffer] ? a[\sample]).bufnum] };
        args
    };
    allocate = { |m|
        m[\buses]=IdentityDictionary.new;
        a[\spec].value(m)[\outputs].do { |p| m[\buses][p[\key]]=Bus.audio(a[\server],p[\channels]) };
        m[\node]=Synth.tail(a[\group],("mms_"++m[\type]).asSymbol,nodeArgs.value(m))
    };
    order = { |mods,cables|
        var pending=mods.copy, done=List.new, sorted=List.new, ready;
        while { pending.notEmpty and: { ready=pending.detect { |m|
            (a[\catalog][m[\type]][\family]==\feedback) or: {
                cables.select { |c| c[\to]==m[\id] }.every { |c| done.includes(c[\from]) }
            }
        }; ready.notNil } } {
            pending.remove(ready); sorted.add(ready); done.add(ready[\id])
        };
        if(pending.isEmpty) { sorted } { nil }
    };
    a[\order]=order;
    a[\route] = {
        var sorted=order.value(a[\modules],a[\cables]);
        if(a[\running] and: { sorted.notNil }) {
            a[\server].makeBundle(nil, {
                a[\modules].do { |m| a[\spec].value(m)[\inputs].do { |p|
                    m[\node].set(("inputBus_"++p[\key]).asSymbol,a[\zero].index,("has_"++p[\key]).asSymbol,0)
                } };
                a[\cables].do { |c|
                    var src=a[\find].value(c[\from]), dst=a[\find].value(c[\to]);
                    dst[\node].set(("inputBus_"++c[\input]).asSymbol,src[\buses][c[\output]].index,("has_"++c[\input]).asSymbol,1)
                };
                sorted.do { |m| m[\node].moveToTail(a[\group]) }
            })
        };
        a[\dirty]=true; a[\redraw].value
    };
    a[\add] = { |type|
        var spec=a[\catalog][type],m;
        if(spec.notNil and: { (spec[\family]!=\monitor) or: { a[\modules].every { |q| a[\spec].value(q)[\family]!=\monitor } } }) {
            m=(id:a[\nextID],type:type,params:IdentityDictionary.new,step:0,
                steps:[0,6,11,16,19,11,8,3],gates:Array.fill(8,1),
                patterns:Array.fill(4,{ |j| Array.fill(16,{ |k| if((k%(j+2))==0){1}{0} }) }));
            spec[\params].do { |p| m[\params][p[\key]]=p[\default] };
            if(spec[\family]==\quantizer) { m[\params][\edo]=a[\edo] };
            if(type==\unity) { (1..4).do { |j| m[\params][("gain"++j).asSymbol]=1 } };
            if(type==\inverter) { (1..3).do { |j| m[\params][("gain"++j).asSymbol] = -1 } };
            a[\nextID]=a[\nextID]+1; a[\modules].add(m); a[\selected]=m;
            if(a[\running]) { allocate.value(m); a[\route].value };
            a[\dirty]=true;
            if(a[\layout].notNil) { a[\layout].value };
            a[\redraw].value
        } { a[\status].value("One OUTS / MONITOR is available per rack.") };
        m
    };
    a[\remove] = { |m|
        if(m.notNil) {
            if((a[\recording] ? false) and: { a[\recordModule]==m[\id] }) { a[\record].value };
            a[\cables]=a[\cables].reject { |c| (c[\from]==m[\id]) or: { c[\to]==m[\id] } }.as(List);
            a[\modules].remove(m); a[\selected]=nil;
            if(a[\running]) {
                m[\node].free;
                a[\route].value;
                m[\buses].values.do(_.free); m[\buffer] !? _.free
            };
            if(a[\layout].notNil) { a[\layout].value };
            a[\redraw].value; a[\dirty]=true
        }
    };
    a[\compatible] = { |out,in|
        (out[\channels]==in[\channels]) and: {
            (out[\channels]==1) or: { out[\type]==in[\type] }
        }
    };
    a[\connect] = { |src,out,dst,in|
        var sm=a[\find].value(src), dm=a[\find].value(dst),sp,dp,new,okay=false;
        if(sm.notNil and: { dm.notNil }) {
            sp=a[\spec].value(sm)[\outputs].detect { |p| p[\key]==out };
            dp=a[\spec].value(dm)[\inputs].detect { |p| p[\key]==in };
            if(sp.notNil and: { dp.notNil } and: { a[\compatible].value(sp,dp) }) {
                new=a[\cables].reject { |c| (c[\to]==dst) and: { c[\input]==in } }.as(List);
                new.add((from:src,output:out,to:dst,input:in));
                if(order.value(a[\modules],new).notNil) {
                    a[\cables]=new; a[\route].value; okay=true;
                    a[\status].value("Connected "++a[\spec].value(sm)[\name]++" / "++sp[\label]++" -> "++dp[\label])
                } { a[\status].value("Feedback loop: route the return through FEEDBACK / DELAY.") }
            } { a[\status].value("Cable widths must match: mono/CV, stereo, ring 32 or AmbiX 4.") }
        }; okay
    };
    a[\disconnect] = { |id,key,direction|
        a[\cables]=a[\cables].reject { |c|
            if(direction==\in) { (c[\to]==id) and: { c[\input]==key } } { (c[\from]==id) and: { c[\output]==key } }
        }.as(List); a[\route].value; a[\status].value("Cable removed.")
    };
    a[\set] = { |m,key,value|
        var desc=a[\spec].value(m)[\params].detect { |p| p[\key]==key };
        value=value.clip(desc[\min],desc[\max]); if(desc[\warp]==\step) { value=value.round(1) };
        m[\params][key]=value; if(a[\running]) { m[\node].set(key,value) };
        if(a[\spec].value(m)[\family]==\quantizer and: { key==\edo }) { a[\edo]=value.asInteger; a[\syncGlobals].value };
        a[\dirty]=true; a[\redraw].value
    };
    a[\syncGlobals] = {
        if((a[\mode]==2) and: { a[\hardware]<a[\channels] }) { a[\mode]=1; a[\status].value("Speaker mode requires "++a[\channels]++" hardware outputs. Headphone preview selected.") };
        if((a[\mode]==3) and: { a[\hardware]<4 }) { a[\mode]=1; a[\status].value("Raw AmbiX requires at least four hardware outputs.") };
        a[\modules].do { |m|
            if(a[\spec].value(m)[\family]==\quantizer) { m[\params][\edo]=a[\edo]; if(a[\running]) { m[\node].set(\edo,a[\edo]) } };
            if(a[\running]) { m[\node].set(*globals.value) }
        };
        a[\dirty]=true; a[\redraw].value
    };
    a[\play] = { |state|
        a[\playing]=state;
        if(state.not) { a[\modules].do { |m| m[\held]=List.new; if(a[\running] and: { a[\spec].value(m)[\family]==\midi }) { m[\node].set(\gate,0) } } };
        a[\syncGlobals].value
    };
    a[\boot] = {
        var s=a[\server];
        if(a[\running].not and: { (a[\booting] ? false).not } and: { (a[\stopping] ? false).not }) {
            a[\booting]=true; a[\status].value("Starting the MicroMS audio engine...");
            s.options.numOutputBusChannels=a[\hardware]; s.options.numInputBusChannels=a[\inputs] ? 0;
            s.options.numAudioBusChannels=8192; s.options.numControlBusChannels=4096;
            s.options.memSize=262144; s.options.maxNodes=2048; s.options.numWireBufs=512;
            s.options.blockSize=64;
            if(a[\device].notNil) { s.options.outDevice=a[\device] };
            if(a[\inputDevice].notNil) { s.options.inDevice=a[\inputDevice] };
            s.waitForBoot({
                if(a[\booting] ? false) {
                a[\zero]=Bus.audio(s,32); a[\group]=Group.head(s);
                a[\sample]=Buffer.loadCollection(s,FloatArray.fill(96000,{ |j| ((j*0.021).sin*0.35)+((j*0.0351).sin*(j/96000*pi).sin*0.2) }));
                a[\buildDefs].value; s.sync;
                a[\modules].do { |m|
                    if(m[\samplePath].notNil and: { File.exists(m[\samplePath]) }) { m[\buffer]=Buffer.readChannel(s,m[\samplePath],channels:[0]) }
                };
                s.sync;
                if(a[\booting] ? false) {
                a[\modules].do { |m| allocate.value(m) };
                a[\running]=true; a[\booting]=false; a[\playing]=false;
                a[\route].value;
                { a[\status].value("Engine ready. Press PLAY to listen."); a[\redraw].value }.defer
                } { s.quit }
                } { s.quit }
            },100, { { a[\booting]=false; a[\status].value("Audio engine did not start. Check AUDIO SETUP and the SuperCollider post window.") }.defer });
        }
    };
    a[\shutdown] = {
        a[\scopeWindow] !? { |win| a[\scopeWindow]=nil; win.close };
        a[\playing]=false; a[\running]=false; a[\booting]=false;
        if(a[\server].isRecording) { a[\server].stopRecording };
        a[\recording]=false;
        if(a[\server].serverRunning and: { (a[\stopping] ? false).not }) {
            a[\stopping]=true;
            Routine {
                a[\server].sync;
                a[\server].quit(onComplete:{ { a[\stopping]=false; if(a[\window].notNil) { a[\redraw].value } }.defer })
            }.play(AppClock)
        };
        a[\modules].do { |m| m[\node]=nil; m[\buses]=nil; m[\buffer]=nil };
        a[\redraw].value
    };
    a[\clear] = {
        if(a[\recording] ? false) { a[\record].value };
        if(a[\running]) {
            a[\play].value(false); a[\group].freeAll;
            a[\modules].do { |m| m[\buses].values.do(_.free); m[\buffer] !? _.free }
        };
        a[\modules].clear; a[\cables].clear; a[\selected]=nil; a[\nextID]=1;
        if(a[\layout].notNil) { a[\layout].value }; a[\redraw].value
    };
    quote = { |s| "\"" ++ s.asString.replace("\\","\\\\").replace("\"","\\\"").replace(Char.nl.asString,"\\n") ++ "\"" };
    json = { |v|
        case
        { v.isNil } { "null" }
        { v==true } { "true" }
        { v==false } { "false" }
        { v.isNumber } { v.asString }
        { v.isKindOf(Dictionary) } { "{" ++ v.keys.asArray.sort.collect { |k| quote.value(k)++":"++json.value(v[k]) }.join(",") ++ "}" }
        { v.isArray and: { v.isString.not } } { "["++v.collect { |q| json.value(q) }.join(",")++"]" }
        { true } { quote.value(v) }
    };
    a[\snapshot] = {
        (format:"MicroMS-01",version:1,edo:a[\edo],rootHz:a[\rootHz],channels:a[\channels],mode:a[\mode],volume:a[\volume],
            modules:a[\modules].collect { |m| (id:m[\id],type:m[\type].asString,params:m[\params],steps:m[\steps],gates:m[\gates],patterns:m[\patterns],samplePath:m[\samplePath]) }.asArray,
            cables:a[\cables].asArray)
    };
    a[\save] = { |path|
        var file;
        if(path.endsWith(".microms").not) { path=path++".microms" };
        file=File(path,"w");
        if(file.isOpen) { file.write(json.value(a[\snapshot].value)); file.close; a[\dirty]=false; a[\status].value("Saved "++PathName(path).fileName) }
        { a[\status].value("Could not write patch: "++path) }
    };
    // SuperCollider 3.14's JSON parser returns numeric literals as strings.
    parseNumbers = { |v|
        case
        { v.isString } { if(v.findRegexp("^-?[0-9]+([.][0-9]+)?([eE][+-]?[0-9]+)?$").notEmpty) { if(v.findRegexp("^-?[0-9]+$").notEmpty) { v.asInteger } { v.asFloat } } { v } }
        { v.isKindOf(Dictionary) } { var converted=Dictionary.new; v.keysValuesDo { |key,val| converted[key]=parseNumbers.value(val) }; converted }
        { v.isArray } { v.collect { |val| parseNumbers.value(val) } }
        { true } { v }
    };
    a[\load] = { |path|
        var data,mods=List.new,cables=List.new, ids=Set.new;
        try {
            data=parseNumbers.value(File.readAllString(path).parseJSON);
            if(data["format"]!="MicroMS-01" or: { data["version"]!=1 }) { Error("Unsupported patch format").throw };
            if(data["modules"].size>128) { Error("Patch exceeds 128 modules").throw };
            data["modules"].do { |q|
                var type=q["type"].asSymbol,spec=a[\catalog][type],m;
                if(spec.isNil) { Error("Unknown module "++type).throw };
                if(q["id"].isNumber.not or: { q["id"]!=q["id"].asInteger } or: { q["id"]<=0 } or: { ids.includes(q["id"]) }) { Error("Invalid module IDs").throw };
                ids.add(q["id"]);
                m=(id:q["id"].asInteger,type:type,params:IdentityDictionary.new,step:0);
                spec[\params].do { |p|
                    var v=q["params"][p[\key].asString] ? p[\default];
                    if(v.isNumber.not) { Error("Invalid parameter").throw };
                    m[\params][p[\key]]=if(p[\warp]==\step){v.round(1)}{v}.clip(p[\min],p[\max]);
                };
                [\steps,\gates,\patterns].do { |key| m[key]=q[key.asString] };
                if(m[\steps].size!=8 or: { m[\steps].every(_.isNumber).not }) { Error("Invalid pitch steps").throw };
                if(m[\gates].size!=8 or: { m[\gates].every { |v| [0,1].includes(v) }.not }) { Error("Invalid gates").throw };
                if(m[\patterns].size!=4 or: { m[\patterns].every { |row| row.size==16 and: { row.every { |v| [0,1].includes(v) } } }.not }) { Error("Invalid trigger pattern").throw };
                if(q["samplePath"].notNil and: { q["samplePath"].isString.not }) { Error("Invalid sample path").throw };
                m[\samplePath]=q["samplePath"]; mods.add(m)
            };
            if(mods.count { |m| a[\catalog][m[\type]][\family]==\monitor }>1) { Error("Multiple monitor modules").throw };
            data["cables"].do { |q|
                var src=mods.detect { |m| m[\id]==q["from"] },dst=mods.detect { |m| m[\id]==q["to"] },out,in,c;
                if(src.isNil or: { dst.isNil }) { Error("Cable references missing module").throw };
                out=a[\catalog][src[\type]][\outputs].detect { |p| p[\key].asString==q["output"] };
                in=a[\catalog][dst[\type]][\inputs].detect { |p| p[\key].asString==q["input"] };
                if(out.isNil or: { in.isNil } or: { a[\compatible].value(out,in).not }) { Error("Invalid cable type").throw };
                c=(from:src[\id],to:dst[\id],output:out[\key],input:in[\key]);
                if(cables.any { |old| old[\to]==c[\to] and: { old[\input]==c[\input] } }) { Error("Multiple cables on one input").throw };
                cables.add(c)
            };
            if(order.value(mods,cables).isNil) { Error("Unbounded feedback loop").throw };
            ["edo","rootHz","channels","mode","volume"].do { |key| if(data[key].isNumber.not) { Error("Invalid tuning/output settings").throw } };
            if([4,8,16,24,32].includes(data["channels"]).not) { Error("Invalid ring size").throw };
            // Only replace the current rack after validation has succeeded.
            a[\clear].value; a[\modules]=mods; a[\cables]=cables;
            a[\nextID]=(ids.asArray.maxItem ? 0)+1;
            a[\edo]=data["edo"].round.clip(7,120); a[\rootHz]=data["rootHz"].clip(20,2000);
            a[\channels]=data["channels"]; a[\mode]=data["mode"].round.clip(0,3); a[\volume]=data["volume"].clip(0,1);
            if(a[\running]) {
                mods.do { |m| allocate.value(m) };
                mods.do { |m| if(m[\samplePath].notNil) { a[\loadSample].value(m,m[\samplePath]) } };
                a[\route].value
            };
            a[\syncGlobals].value; a[\layout].value; a[\dirty]=false;
            a[\status].value("Loaded "++PathName(path).fileName++". Press PLAY.")
        } { |error| a[\status].value("Patch not loaded: "++error.errorString) }
    };
    a[\loadSample] = { |m,path|
        var sf=SoundFile.new;
        if(File.exists(path) and: { sf.openRead(path) }) {
            if(sf.numFrames<(sf.sampleRate*180)) {
                m[\samplePath]=path;
                if(a[\running]) {
                    Buffer.readChannel(a[\server],path,channels:[0],action:{ |buf|
                        { if(a[\modules].includes(m) and: { a[\running] }) {
                            var old=m[\buffer]; m[\buffer]=buf; m[\node].set(\buf,buf.bufnum); old !? _.free;
                            a[\status].value("Loaded sample: "++PathName(path).fileName)
                        } { buf.free } }.defer
                    })
                };
                a[\dirty]=true
            } { a[\status].value("Choose a sample shorter than three minutes.") };
            sf.close
        } { a[\status].value("Audio file could not be read.") }
    };
    a[\record] = {
        if(a[\running]) {
            if(a[\recording] ? false) {
                a[\server].stopRecording; a[\recording]=false; a[\status].value("Recording saved in recordings/.")
            } {
                var count=if(a[\mode]==2){a[\channels]}{if(a[\mode]==3){4}{2}};
                var m=a[\selected],port,bus=0,path;
                a[\recordModule]=nil;
                if((a[\recordSource] ? 0)==1 and: { m.notNil }) {
                    port=a[\spec].value(m)[\outputs].first;
                    if(port.notNil) {
                        bus=m[\buses][port[\key]].index;
                        count=if(port[\type]==\ring){a[\channels]}{port[\channels]};
                        a[\recordModule]=m[\id]
                    }
                };
                path=(a[\root]+/+"recordings"+/+("MicroMS-01_"++Date.localtime.stamp++"_"++count++"ch.wav")).standardizePath;
                a[\server].recHeaderFormat="wav"; a[\server].recSampleFormat="float";
                a[\server].record(path,bus,count,a[\server].defaultGroup); a[\recording]=true; a[\status].value("Recording "++count++" channels...")
            }; a[\redraw].value
        } { a[\status].value("Start POWER before recording.") }
    };
    a[\midi] = {
        MIDIClient.init; MIDIIn.connectAll;
        a[\midiDefs] !? { |defs| defs.do(_.free) };
        a[\midiDefs]=List.new;
        a[\midiDefs].add(MIDIdef.noteOn(\mms_noteOn,{ |vel,note,ch|
            a[\modules].do { |m| if(a[\spec].value(m)[\family]==\midi and: { a[\running] } and: { [0,ch+1].includes(m[\params][\channel]) }) {
                m[\held]=m[\held] ? List.new; m[\held].remove(note); m[\held].add(note);
                m[\node].set(\note,(note.midicps/a[\rootHz]).log2,\velocity,vel/127,\gate,1)
            } }
        }));
        a[\midiDefs].add(MIDIdef.noteOff(\mms_noteOff,{ |vel,note,ch|
            a[\modules].do { |m| if(a[\spec].value(m)[\family]==\midi and: { a[\running] } and: { [0,ch+1].includes(m[\params][\channel]) }) {
                m[\held]=m[\held] ? List.new; m[\held].remove(note);
                if(m[\held].isEmpty) { if((m[\sustain] ? false).not) { m[\node].set(\gate,0) } }
                { m[\node].set(\note,(m[\held].last.midicps/a[\rootHz]).log2) }
            } }
        }));
        a[\midiDefs].add(MIDIdef.cc(\mms_cc,{ |val,num,ch|
            a[\modules].do { |m| if(a[\spec].value(m)[\family]==\midi and: { a[\running] } and: { [0,ch+1].includes(m[\params][\channel]) }) {
                if(num==1) { m[\node].set(\modwheel,val/127) };
                if(num==64) { m[\sustain]=val>=64; if(m[\sustain].not and: { (m[\held] ? []).isEmpty }) { m[\node].set(\gate,0) } }
            } }
        }));
        a[\midiDefs].add(MIDIdef.bend(\mms_bend,{ |val,ch|
            a[\modules].do { |m| if(a[\spec].value(m)[\family]==\midi and: { a[\running] } and: { [0,ch+1].includes(m[\params][\channel]) }) {
                m[\node].set(\bend,((val-8192)/8192)*(2/12))
            } }
        }));
        a[\status].value("MIDI connected. Add MIDI / CV and patch PITCH + GATE.")
    };
    a[\meterOSC]=OSCFunc({ |msg|
        { a[\meters]=msg.copyRange(3,4); a[\redraw].value }.defer
    },'/mms/meter',a[\server].addr);
    a[\stepOSC]=OSCFunc({ |msg| { var m=a[\find].value(msg[3].asInteger); if(m.notNil) { m[\step]=msg[4].asInteger; a[\rack] !? _.refresh } }.defer },'/mms/step',a[\server].addr);
    a[\scopeOSC]=OSCFunc({ |msg| { var m=a[\find].value(msg[3].asInteger); if(m.notNil) { m[\frequency]=if(msg[5]>0){msg[4]}{0}; m[\peak]=msg[6]; a[\rack] !? _.refresh } }.defer },'/mms/scope',a[\server].addr);
    a[\orbitOSC]=OSCFunc({ |msg| { var m=a[\find].value(msg[3].asInteger); if(m.notNil) { m[\phase]=msg[4]; a[\rack] !? _.refresh } }.defer },'/mms/orbit',a[\server].addr);
    a[\cmdHook]={ { a[\shutdown].value; a[\status].value("Audio stopped by Cmd+Period. POWER restarts the engine.") }.defer };
    CmdPeriod.add(a[\cmdHook]);
    a[\close] = {
        a[\shutdown].value; a[\meterOSC].free; a[\stepOSC].free; a[\orbitOSC].free; a[\scopeOSC].free;
        a[\midiDefs] !? { |defs| defs.do(_.free) }; CmdPeriod.remove(a[\cmdHook]);
        a[\window] !? { |w| w.view.onResize=nil; w.onClose=nil; w.close };
        a[\rack]=nil; a[\refreshUI]=nil; a[\statusView]=nil
    };
}
