/* Offline rendering: exercises the actual SynthDefs and preset patch graph. */
(
var root=thisProcess.nowExecutingPath.dirname.dirname;
var cases=[
    [\orbit,0,4,2,"stereo-4"], [\orbit,1,8,2,"headphones-8"],
    [\orbit,1,16,2,"headphones-16"], [\orbit,1,32,2,"headphones-32"],
    [\orbit,2,16,16,"speakers-16"], [\orbit,3,8,4,"ambix-4"],
    [\glass,1,8,2,"glass-31edo"]
];
var run;
Score.program="/Applications/SuperCollider.app/Contents/Resources/scsynth";
run={ |index|
    var c=cases[index],a,score=List.new,alloc=96,zero=64,opts,sorted,outPath;
    if(index>=cases.size) { "PASS: offline renders completed.".postln; 0.exit } {
        a=(root:root,modules:List.new,cables:List.new,catalog:IdentityDictionary.new,nextID:1,
            edo:19,rootHz:130.81278265,channels:c[2],hardware:c[3],mode:c[1],volume:0.35,running:false,playing:false,
            server:Server(("test"++index).asSymbol,NetAddr("127.0.0.1",59999)));
        ["Catalog","DSP","Engine","Presets"].do { |name| (root+/+"lib"+/+(name++".scd")).load.value(a) };
        a[\preset].value(c[0]); a[\channels]=c[2]; a[\hardware]=c[3]; a[\mode]=c[1];
        if(c[1]==2) { a[\modules].do { |m| if(a[\spec].value(m)[\family]==\spatial) { m[\params][\rate]=0.5 } } };
        a[\server]=nil; a[\buildDefs].value;
        a[\modules].do { |m|
            m[\nrtBuses]=IdentityDictionary.new;
            a[\spec].value(m)[\outputs].do { |p| m[\nrtBuses][p[\key]]=alloc; alloc=alloc+p[\channels] }
        };
        a[\defs].values.do { |d| d.writeDefFile("/tmp/microms-defs"); score.add([0,[\d_load,"/tmp/microms-defs"+/+(d.name++".scsyndef")]]) };
        sorted=a[\order].value(a[\modules],a[\cables]);
        sorted.do { |m,j|
            var spec=a[\spec].value(m),args=[\global_edo,a[\edo],\global_root,a[\rootHz],\global_channels,c[2],\global_play,0,\global_mode,c[1],\global_volume,0.35,\global_hardware,c[3]];
            spec[\params].do { |p| args=args++[p[\key],m[\params][p[\key]]] };
            spec[\inputs].do { |p|
                var cable=a[\cables].detect { |cable| (cable[\to]==m[\id]) and: { cable[\input]==p[\key] } };
                var bus=if(cable.isNil){zero}{a[\find].value(cable[\from])[\nrtBuses][cable[\output]]};
                args=args++[("inputBus_"++p[\key]).asSymbol,bus,("has_"++p[\key]).asSymbol,cable.notNil.binaryValue]
            };
            spec[\outputs].do { |p| args=args++[("outputBus_"++p[\key]).asSymbol,m[\nrtBuses][p[\key]]] };
            score.add([0.05+(j*0.0001),[\s_new,("mms_"++m[\type]).asSymbol,1000+m[\id],1,1]++args]);
            if(spec[\family]==\sequencer) {
                score.add([0.08,[\n_setn,1000+m[\id],\steps,8]++m[\steps]]);
                score.add([0.08,[\n_setn,1000+m[\id],\gates,8]++m[\gates]])
            };
            score.add([0.2,[\n_set,1000+m[\id],\global_play,1]]);
            score.add([4.5,[\n_set,1000+m[\id],\global_play,0]])
        };
        opts=ServerOptions.new.numOutputBusChannels_(c[3]).numInputBusChannels_(0).numAudioBusChannels_(1024).memSize_(262144).numWireBufs_(512);
        outPath=root+/+"tests"+/+(c[4]++".wav");
        ("RENDER: "++outPath).postln;
        Score(score.asArray).recordNRT(outputFilePath:outPath,sampleRate:48000,headerFormat:"WAV",sampleFormat:"float",options:opts,duration:5,action:{ |exitCode|
            if(exitCode!=0) { ("FAIL: renderer exit "++exitCode).postln; 1.exit };
            a[\meterOSC].free; a[\stepOSC].free; a[\orbitOSC].free; a[\scopeOSC].free; CmdPeriod.remove(a[\cmdHook]);
            run.value(index+1)
        })
    }
};
run.value(0)
)
