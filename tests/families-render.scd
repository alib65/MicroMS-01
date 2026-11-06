(
var root=thisProcess.nowExecutingPath.dirname.dirname,a,score=List.new,fixture,tap,opts,ids,manifest=List.new;
a=(catalog:IdentityDictionary.new,defs:IdentityDictionary.new,hardware:2);
(root+/+"lib/Catalog.scd").load.value(a); (root+/+"lib/DSP.scd").load.value(a); a[\buildDefs].value;
fixture=SynthDef(\mms_fixture,{
    Out.ar(64,SinOsc.ar(220)*0.3); Out.ar(66,[SinOsc.ar(220),SinOsc.ar(330)]*0.2);
    Out.ar(68,LFPulse.ar(12,0,0.3)); Out.ar(69,DC.ar(0.131));
    Out.ar(96,Array.fill(32,{ |j| SinOsc.ar(220+(j*10))*0.05 }));
    Out.ar(128,[SinOsc.ar(220),SinOsc.ar(330),SinOsc.ar(440),SinOsc.ar(550)]*0.1)
});
tap=SynthDef(\mms_tap,{ |bus=256| var sig=In.ar(bus,1); Out.ar(0,[sig,CheckBadValues.ar(sig,0,0)]) });
a[\defs][\fixture]=fixture; a[\defs][\tap]=tap;
a[\defs].values.do { |d| d.writeDefFile("/tmp/microms-defs"); score.add([0,[\d_load,"/tmp/microms-defs"+/+(d.name++".scsyndef")]]) };
score.add([0,[\b_alloc,0,4096,1]]);
score.add([0.01,[\b_setn,0,0,4096]++Array.fill(4096,{ |j| (j*0.02).sin*0.5 })]);
score.add([0.02,[\s_new,\mms_fixture,500,1,1]]);
ids=a[\catalog].keys.asArray.sort;
ids.do { |id,index|
    var spec=a[\catalog][id],time=0.1+(index*0.4),bus=256;
    var args=[\global_play,1,\global_channels,8,\global_mode,0,\global_volume,0.2,\global_inputs,0];
    spec[\inputs].do { |p|
        var inBus=if(p[\key]==\reset){160}{(mono:64,stereo:66,gate:68,cv:69,ring:96,ambi:128)[p[\type]]};
        args=args++[("inputBus_"++p[\key]).asSymbol,inBus,("has_"++p[\key]).asSymbol,1]
    };
    spec[\outputs].do { |p| args=args++[("outputBus_"++p[\key]).asSymbol,bus]; bus=bus+p[\channels] };
    if(spec[\family]==\xy) { args=args++[\x,0.3,\y,0.5] };
    if(spec[\family]==\midi) { args=args++[\note,0.13,\gate,1,\velocity,0.8,\modwheel,0.4] };
    score.add([time,[\s_new,("mms_"++id).asSymbol,1000,1,1]++args]);
    if(spec[\outputs].notEmpty) { score.add([time+0.001,[\s_new,\mms_tap,1001,1,1,\bus,256]]) };
    score.add([time+0.37,[\n_free,1000]]);
    if(spec[\outputs].notEmpty) { score.add([time+0.37,[\n_free,1001]]) };
    manifest.add(id.asString++","++spec[\family]++","++time++","++(time+0.37))
};
File.use(root+/+"tests/families.csv","w",{ |f| f.write(manifest.join(Char.nl.asString)) });
opts=ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0).numAudioBusChannels_(1024).numWireBufs_(512).memSize_(262144);
Score.program="/Applications/SuperCollider.app/Contents/Resources/scsynth";
Score(score.asArray).recordNRT(outputFilePath:root+/+"tests/all-modules.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"float",options:opts,duration:0.2+(ids.size*0.4),action:{ |code| code.exit })
)
