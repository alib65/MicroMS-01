{
    |a|
    a[\preset] = { |name|
        var clock,seq,quant,osc,env,vca,filter,lfo,fx,spatial,ambi,decode,out,ear;
        a[\clear].value;
        if(name!=\empty) {
            clock=a[\add].value(\clock); seq=a[\add].value(\sequencer);
            quant=a[\add].value(\quantizer);
            osc=a[\add].value(if(name==\glass){\complex}{\vco});
            filter=a[\add].value(\filter); env=a[\add].value(\adsr);
            vca=a[\add].value(\vca); lfo=a[\add].value(\lfo);
            fx=a[\add].value(if(name==\glass){\reverb}{\delay});
            spatial=a[\add].value(\spatial); ambi=a[\add].value(\ambisonic);
            decode=a[\add].value(\ambidecode); ear=a[\add].value(\binaural);
            out=a[\add].value(\monitor);
            a[\connect].value(clock[\id],\clock,seq[\id],\clock);
            a[\connect].value(clock[\id],\reset,seq[\id],\reset);
            a[\connect].value(seq[\id],\pitch,quant[\id],\pitch);
            a[\connect].value(quant[\id],\out,osc[\id],\pitch);
            a[\connect].value(osc[\id],if(name==\glass){\out}{\saw},filter[\id],\in);
            a[\connect].value(seq[\id],\gate,env[\id],\g1);
            a[\connect].value(env[\id],\v1,vca[\id],\cv1);
            a[\connect].value(filter[\id],\low,vca[\id],\in1);
            a[\connect].value(lfo[\id],\v1,filter[\id],\cv);
            a[\connect].value(vca[\id],\mix,fx[\id],\in);
            a[\connect].value(fx[\id],\out,spatial[\id],\in);
            a[\connect].value(spatial[\id],\ring,ambi[\id],\ring);
            a[\connect].value(ambi[\id],\ambi,decode[\id],\ambi);
            a[\connect].value(decode[\id],\ring,ear[\id],\ring);
            // Monitor accepts the direct ring, retaining stereo/headphone/speaker choices.
            // The encoder/decoder/headphone chain remains available for comparisons.
            a[\connect].value(spatial[\id],\ring,out[\id],\ring);
            a[\connect].value(ambi[\id],\ambi,out[\id],\ambi);
            if(name==\glass) {
                a[\edo]=31; seq[\steps]=[0,10,18,25,31,43,36,18];
                a[\set].value(clock,\bpm,76); a[\set].value(clock,\division,2);
                a[\set].value(env,\release,1.8); a[\set].value(filter,\cutoff,4800);
                a[\set].value(spatial,\rate,0.035)
            } {
                a[\edo]=19; a[\set].value(env,\sustain,0.3); a[\set].value(env,\release,0.24)
            };
            if(a[\running]) { seq[\node].setn(\steps,seq[\steps]) };
            a[\syncGlobals].value
        };
        a[\selected]=a[\modules].first;
        if(a[\layout].notNil) { a[\layout].value };
        a[\dirty]=false; a[\status].value("Patch: "++(orbit:"19 EDO / Orbital Sequence",glass:"31 EDO / Glass Garden",empty:"Empty rack")[name]);
        a[\redraw].value
    }
}
