(
var root=thisProcess.nowExecutingPath.dirname.dirname,assert,same,a,src,filter,loop,out,field,saved;
assert={ |test,msg| if(test.not) { Error("FAIL: "++msg).throw } { ("PASS: "++msg).postln } };
same={ |x,y|
    case
    { x.isNumber and: { y.isNumber } } { (x-y).abs<0.000001 }
    { x.isKindOf(Dictionary) and: { y.isKindOf(Dictionary) } } { x.size==y.size and: { x.keys.every { |k| same.value(x[k],y[k]) } } }
    { x.isArray and: { x.isString.not } } { x.size==y.size and: { x.every { |v,j| same.value(v,y[j]) } } }
    { true } { x==y }
};
try {
a=(root:root.standardizePath,modules:List.new,cables:List.new,catalog:IdentityDictionary.new,nextID:1,
    edo:19,rootHz:130.81278265,channels:8,hardware:2,mode:1,volume:0.35,running:false,playing:false,
    server:Server(\engineTest,NetAddr("127.0.0.1",59998)));
["Catalog","DSP","Engine","Presets"].do { |name| (root+/+"lib"+/+(name++".scd")).load.value(a) };
a[\layout]={};
src=a[\add].value(\vco); filter=a[\add].value(\filter); loop=a[\add].value(\feedback); out=a[\add].value(\monitor); field=a[\add].value(\ambisonic);
assert.value(a[\connect].value(src[\id],\saw,filter[\id],\in),"mono audio routing");
assert.value(a[\connect].value(filter[\id],\low,filter[\id],\in).not,"reject unbounded self feedback");
assert.value(a[\connect].value(filter[\id],\low,loop[\id],\in),"feedback send");
assert.value(a[\connect].value(loop[\id],\out,filter[\id],\in),"explicit block feedback accepted");
assert.value(a[\connect].value(src[\id],\sine,out[\id],\ambi).not,"reject channel mismatch");
assert.value(a[\connect].value(src[\id],\tri,out[\id],\mono),"fan-out source");
assert.value(a[\connect].value(src[\id],\saw,out[\id],\mono),"replace input cable");
assert.value(a[\cables].count { |c| c[\to]==out[\id] and: { c[\input]==\mono } }==1,"one source per input");
a[\save].value("/tmp/microms-roundtrip.microms"); saved=a[\snapshot].value;
a[\load].value("/tmp/microms-roundtrip.microms");
assert.value(same.value(a[\snapshot].value,saved),"patch JSON round trip");
File.use("/tmp/microms-invalid.microms","w",{ |f| f.write("{\"format\":\"bad\"}") });
a[\load].value("/tmp/microms-invalid.microms");
assert.value(same.value(a[\snapshot].value,saved),"invalid patch preserves current rack");
a[\close].value; "PASS: engine checks completed.".postln; 0.exit
} { |err| err.reportError; 1.exit };
)
