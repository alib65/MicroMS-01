/* Validate all fifty factory files with the production loader and real DSP.
   Offline only: this never boots or modifies the user's live audio server. */
(
var root=thisProcess.nowExecutingPath.dirname.dirname.standardizePath;
var a,files,run,defsDir="/tmp/microms-bank-defs",renderDir="/tmp/microms-bank-renders",samplePath="/tmp/microms-bank-texture.wav";
var sample;
a=(root:root,modules:List.new,cables:List.new,catalog:IdentityDictionary.new,nextID:1,
    edo:19,rootHz:130.81278265,channels:8,hardware:2,mode:1,volume:0.43,running:false,playing:false,
    server:Server(\factoryTest,NetAddr("127.0.0.1",59994)));
["Catalog","DSP","Engine"].do { |name| (root+/+"lib"+/+(name++".scd")).load.value(a) };
a[\layout]={};
defsDir.mkdir; renderDir.mkdir;
a[\buildDefs].value;
a[\defs].values.do { |def| def.writeDefFile(defsDir) };
sample=SoundFile.new.sampleRate_(48000).numChannels_(1).headerFormat_("WAV").sampleFormat_("float");
sample.openWrite(samplePath); sample.writeData(FloatArray.fill(96000,{ |j| ((j*0.021).sin*0.35)+((j*0.0351).sin*(j/96000*pi).sin*0.2) })); sample.close;
files=PathName(root+/+"presets").files.select { |p| p.extension=="microms" and: { p.fileName.first.isDecDigit } }.sort { |x,y| x.fileName<y.fileName };
if(files.size!=50) { Error("Expected exactly fifty new presets").throw };
Score.program="/Applications/SuperCollider.app/Contents/Resources/scsynth";
run={ |index|
    if(index>=files.size) {
        a[\meterOSC].free; a[\stepOSC].free; a[\orbitOSC].free; a[\scopeOSC].free; CmdPeriod.remove(a[\cmdHook]);
        "PASS: all 50 factory patches loaded and rendered.".postln; 0.exit
    } {
        var file=files[index],score=List.new,alloc=96,zero=32,sorted,options,types;
        a[\load].value(file.fullPath);
        if(a[\message].beginsWith("Loaded ").not) { Error("Factory patch failed to load: "++file.fileName).throw };
        a[\modules].do { |m|
            m[\nrtBuses]=IdentityDictionary.new;
            a[\spec].value(m)[\outputs].do { |p| m[\nrtBuses][p[\key]]=alloc; alloc=alloc+p[\channels] }
        };
        types=a[\modules].collect { |m| m[\type] }.as(Set);
        types.do { |type| score.add([0,[\d_load,defsDir+/+("mms_"++type++".scsyndef")]]) };
        score.add([0,[\b_allocRead,0,samplePath]]);
        sorted=a[\order].value(a[\modules],a[\cables]);
        sorted.do { |m,j|
            var spec=a[\spec].value(m),node=1000+m[\id];
            var args=[\moduleID,m[\id],\global_edo,a[\edo],\global_root,a[\rootHz],\global_channels,a[\channels],\global_play,0,\global_mode,a[\mode],\global_volume,a[\volume],\global_hardware,2];
            spec[\params].do { |p| args=args++[p[\key],m[\params][p[\key]]] };
            spec[\inputs].do { |p|
                var c=a[\cables].detect { |c| c[\to]==m[\id] and: { c[\input]==p[\key] } };
                args=args++[("inputBus_"++p[\key]).asSymbol,if(c.isNil){zero}{a[\find].value(c[\from])[\nrtBuses][c[\output]]},("has_"++p[\key]).asSymbol,c.notNil.binaryValue]
            };
            spec[\outputs].do { |p| args=args++[("outputBus_"++p[\key]).asSymbol,m[\nrtBuses][p[\key]]] };
            if(spec[\family]==\sampler) { args=args++[\buf,0] };
            score.add([0.05+(j*0.0001),[\s_new,("mms_"++m[\type]).asSymbol,node,1,1]++args]);
            if(spec[\family]==\sequencer) {
                score.add([0.08,[\n_setn,node,\steps,8]++m[\steps]]);
                score.add([0.08,[\n_setn,node,\gates,8]++m[\gates]])
            };
            if(spec[\family]==\gates) { 4.do { |lane| score.add([0.08,[\n_setn,node,("lane"++lane).asSymbol,16]++m[\patterns][lane]]) } };
            score.add([0.2,[\n_set,node,\global_play,1]]);
            score.add([7.4,[\n_set,node,\global_play,0]])
        };
        options=ServerOptions.new.numOutputBusChannels_(2).numInputBusChannels_(0).numAudioBusChannels_(2048).memSize_(262144).numWireBufs_(512);
        ("RENDER "++(index+1)++"/50: "++file.fileName).postln;
        Score(score.asArray).recordNRT(outputFilePath:renderDir+/+(file.fileNameWithoutExtension++".wav"),sampleRate:48000,headerFormat:"WAV",sampleFormat:"float",options:options,duration:8,action:{ |code|
            if(code!=0) { Error("Factory render failed").throw };
            run.value(index+1)
        })
    }
};
run.value(0)
)
