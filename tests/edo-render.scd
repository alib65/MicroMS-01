(
var root=thisProcess.nowExecutingPath.dirname.dirname,a,score=List.new,fixture,opts;
a=(catalog:IdentityDictionary.new,defs:IdentityDictionary.new,hardware:2);
(root+/+"lib/Catalog.scd").load.value(a); (root+/+"lib/DSP.scd").load.value(a); a[\buildDefs].value;
a[\defs][\quantizer].writeDefFile("/tmp/microms-defs");
fixture=SynthDef(\mms_edo_fixture,{ |pitch=0.131,mod=0| Out.ar(64,K2A.ar(pitch)); Out.ar(65,K2A.ar(mod)) }); fixture.writeDefFile("/tmp/microms-defs");
score.add([0,[\d_load,"/tmp/microms-defs/mms_quantizer.scsyndef"]]);
score.add([0,[\d_load,"/tmp/microms-defs/mms_edo_fixture.scsyndef"]]);
score.add([0.01,[\s_new,\mms_edo_fixture,1000,1,1]]);
score.add([0.02,[\s_new,\mms_quantizer,1001,1,1,\inputBus_pitch,64,\inputBus_mod,65,\outputBus_out,0,\outputBus_change,1,\edo,7]]);
(7..120).do { |edo|
    var time=0.1+((edo-7)*0.04),pitch=(edo*0.37).sin*1.1;
    score.add([time,[\n_set,1000,\pitch,pitch]]); score.add([time,[\n_set,1001,\edo,edo]])
};
opts=ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0);
Score.program="/Applications/SuperCollider.app/Contents/Resources/scsynth";
Score(score.asArray).recordNRT(outputFilePath:root+/+"tests/edo-7-120.wav",sampleRate:48000,headerFormat:"WAV",sampleFormat:"float",options:opts,duration:4.7,action:{ |code| code.exit })
)
