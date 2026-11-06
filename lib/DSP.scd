{
    |a|
    var ringDecode, foldStereo, ears;
    // Coordinate convention: 0 radians = front, +pi/2 = left; ACN/SN3D = W,Y,Z,X.
    ringDecode = { |field, n, yaw=0|
        Array.fill(32, { |j|
            var angle = ((j * 2pi) / n) + yaw;
            ((field[0] + (2 * field[1] * angle.sin) + (2 * field[3] * angle.cos)) / n) * (j < n)
        })
    };
    foldStereo = { |ring, n, width=1|
        var result = [DC.ar(0), DC.ar(0)];
        ring.do { |sig, j|
            var pan = (((j * 2pi) / n).sin.neg * width).clip(-1,1);
            result = result + Pan2.ar(sig * (j < n), pan)
        };
        result * 0.5
    };
    ears = { |ring, n, yaw=0|
        var result = [DC.ar(0), DC.ar(0)];
        ring.do { |sig,j|
            var angle = ((j * 2pi) / n) - yaw;
            var side = angle.sin;
            var back = (1 - angle.cos) * 0.5;
            var left = LPF.ar(sig, (16000 - (side.neg.max(0) * 12000) - (back * 3000)).clip(1000,19000));
            var right = LPF.ar(sig, (16000 - (side.max(0) * 12000) - (back * 3000)).clip(1000,19000));
            left = DelayC.ar(left,0.002, (side.neg.max(0) * 0.00065) + 0.0001) * (1 - (side.neg.max(0) * 0.45));
            right = DelayC.ar(right,0.002, (side.max(0) * 0.00065) + 0.0001) * (1 - (side.max(0) * 0.45));
            result = result + ([left,right] * (j < n))
        };
        result * 0.5
    };
    a[\buildDefs] = {
        a[\catalog].keysValuesDo { |id,spec|
            var def;
            def = SynthDef(("mms_"++id).asSymbol, {
                var i,p,o,patched, freq, edo, root, playing, n, family;
                i = { |key|
                    var jack = spec[\inputs].detect { |q| q[\key] == key };
                    var bus = NamedControl.kr(("inputBus_"++key).asSymbol,0);
                    if(spec[\family] == \feedback) { InFeedback.ar(bus,jack[\channels]) } { In.ar(bus,jack[\channels]) }
                };
                p = { |key|
                    var desc = spec[\params].detect { |q| q[\key] == key };
                    NamedControl.kr(key,desc[\default])
                };
                patched = { |key| NamedControl.kr(("has_"++key).asSymbol,0) };
                o = { |key,sig| Out.ar(NamedControl.kr(("outputBus_"++key).asSymbol,0),sig) };
                edo=NamedControl.kr(\global_edo,19).clip(7,120);
                root=NamedControl.kr(\global_root,130.81278265);
                playing=NamedControl.kr(\global_play,0);
                n=NamedControl.kr(\global_channels,8).clip(4,32);
                freq = { |pitch,octave=0| (root * (2 ** (pitch + octave))).clip(0.05,20000) };
                family=spec[\family];
                switch(family,
                    \vco, {
                        var f=freq.value(i.value(\pitch)+(p.value(\fine)/1200),p.value(\octave));
                        f=(f+(i.value(\fm)*f*p.value(\fm))).clip(0.05,20000);
                        o.value(\sine,SinOsc.ar(f)*0.5); o.value(\tri,LFTri.ar(f)*0.5);
                        o.value(\saw,Saw.ar(f)*0.5);
                        o.value(\pulse,Pulse.ar(f,(p.value(\width)+i.value(\pwm)).clip(0.02,0.98))*0.5);
                        o.value(\sub,Pulse.ar(f*0.5)*0.5)
                    },
                    \complex, {
                        var f=freq.value(i.value(\pitch),p.value(\octave));
                        var mod=SinOsc.ar((f*p.value(\ratio)).clip(0.05,20000));
                        var index=(p.value(\index)+(i.value(\mod)*8)).clip(0,24);
                        var sig=SinOsc.ar(f,(mod*index)+(i.value(\fm)*4));
                        o.value(\out,(sig*p.value(\shape)).fold2(1)*0.45);
                        o.value(\mod,mod*0.5); o.value(\sub,SinOsc.ar(f*0.5)*0.5)
                    },
                    \pluck, {
                        var f=freq.value(i.value(\pitch),p.value(\octave)).clip(20,16000);
                        var gate=Trig1.ar(i.value(\gate),0.001);
                        var excite=(WhiteNoise.ar*p.value(\excite)) + i.value(\in);
                        var sig=Pluck.ar(excite,gate,0.06,f.reciprocal,p.value(\decay),p.value(\damp).linlin(0,1,0.05,0.95));
                        o.value(\out,LeakDC.ar(sig).tanh*0.7)
                    },
                    \noise, {
                        var clock=Select.ar(patched.value(\clock),[Impulse.ar(p.value(\rate))*playing,i.value(\clock)]);
                        var hold=Latch.ar(WhiteNoise.ar,clock);
                        o.value(\white,WhiteNoise.ar(0.35)); o.value(\pink,PinkNoise.ar(0.5));
                        o.value(\hold,hold); o.value(\smooth,Lag.ar(hold,p.value(\slew))); o.value(\clock,Trig1.ar(clock,0.01))
                    },
                    \sampler, {
                        var buf=NamedControl.kr(\buf,0);
                        var rate=p.value(\rate)*(2 ** i.value(\pitch));
                        var pos=(p.value(\position)+i.value(\pos)).wrap(0,1);
                        var trig=Impulse.ar(p.value(\density))*playing + Trig1.ar(i.value(\gate),0.001);
                        var grain=GrainBuf.ar(2,trig,p.value(\size),buf,rate,pos,2,LFNoise1.kr(2).range(-0.8,0.8),-1,256);
                        var phase=Phasor.ar(Trig1.ar(i.value(\gate),0.001),BufRateScale.kr(buf)*rate,0,BufFrames.kr(buf),pos*BufFrames.kr(buf));
                        var plain=BufRd.ar(1,buf,phase,1,4)*playing;
                        var sig=XFade2.ar(plain!2,grain,p.value(\mix).linlin(0,1,-1,1))*0.5;
                        o.value(\out,Mix(sig)*0.5); o.value(\stereo,sig)
                    },
                    \voice, {
                        var f=freq.value(i.value(\pitch),p.value(\octave));
                        var osc=(Saw.ar(f)+Pulse.ar(f*1.003,0.48))*0.25;
                        var env=EnvGen.ar(Env.asr(p.value(\attack),1,p.value(\release)),i.value(\gate));
                        var cutoff=(p.value(\cutoff)*(2 ** ((env*p.value(\env))+i.value(\fm)))).clip(20,19000);
                        o.value(\osc,osc); o.value(\out,RLPF.ar(osc,cutoff,(1-p.value(\res)).max(0.03)).tanh*env*0.6)
                    },
                    \clock, {
                        var rate=(p.value(\bpm)/60)*(2 ** i.value(\rate));
                        var phase=Phasor.ar(1-playing,rate*SampleDur.ir*playing,0,256);
                        var pulses=(((phase*p.value(\division)).frac)<p.value(\width))*playing;
                        o.value(\clock,pulses); o.value(\slow,(phase.frac<p.value(\width))*playing);
                        o.value(\reset,Trig1.ar(HPZ1.ar(K2A.ar(playing)).max(0),0.005))
                    },
                    \sequencer, {
                        var steps=NamedControl.kr(\steps,[0,6,11,16,19,11,8,3]);
                        var gates=NamedControl.kr(\gates,[1,1,1,1,1,1,1,1]);
                        var clock=i.value(\clock)*playing;
                        var count=PulseCount.ar(clock,i.value(\reset)+(1-playing)+Trig1.ar(HPZ1.ar(K2A.ar(playing)).max(0),SampleDur.ir));
                        var index=count%p.value(\length).round(1);
                        var pitch=Select.ar(index,steps.collect { |v| K2A.ar(v/edo) });
                        var gate=clock*Select.ar(index,gates.collect { |v| K2A.ar(v) });
                        o.value(\pitch,Lag.ar(pitch,p.value(\swing))); o.value(\gate,gate); o.value(\step,index/7);
                        SendReply.kr(Impulse.kr(12),'/mms/step',[NamedControl.kr(\moduleID,0),A2K.kr(index)])
                    },
                    \gates, {
                        var clock=i.value(\clock)*playing;
                        var count=PulseCount.ar(clock,i.value(\reset)+(1-playing)+Trig1.ar(HPZ1.ar(K2A.ar(playing)).max(0),SampleDur.ir));
                        var index=count%p.value(\length).round(1);
                        4.do { |lane|
                            var values=NamedControl.kr(("lane"++lane).asSymbol,Array.fill(16,{ |j| if((j%(lane+2))==0){1}{0} }));
                            o.value(("g"++(lane+1)).asSymbol,clock*Select.ar(index,values.collect { |v| K2A.ar(v) }))
                        };
                        SendReply.kr(Impulse.kr(12),'/mms/step',[NamedControl.kr(\moduleID,0),A2K.kr(index)])
                    },
                    \quantizer, {
                        var div=(p.value(\edo)+(i.value(\mod)*p.value(\amount))).round(1).clip(7,120);
                        var sig=((i.value(\pitch)*div).round(1)+p.value(\transpose))/div;
                        o.value(\out,sig); o.value(\change,Trig1.ar(HPZ1.ar(sig).abs,0.01))
                    },
                    \shifter, {
                        var gate=Trig1.ar(i.value(\gate),SampleDur.ir);
                        var last=i.value(\in);
                        4.do { |j|
                            last=Latch.ar(if(j==0){last}{Delay1.ar(last)},gate);
                            o.value(("v"++(j+1)).asSymbol,Lag.ar(last,p.value(\slew)))
                        }
                    },
                    \lfo, {
                        var rate=(p.value(\rate)*(2 ** i.value(\rate))).clip(0.001,200);
                        4.do { |j|
                            var phase=j*0.5;
                            var sig=Select.ar(p.value(\shape),[SinOsc.ar(rate,j*0.5pi),LFTri.ar(rate,phase),LFSaw.ar(rate,phase),LFPulse.ar(rate,phase*0.5)*2-1]);
                            o.value(("v"++(j+1)).asSymbol,(sig*p.value(\depth))+p.value(\offset))
                        }
                    },
                    \functions, {
                        var cycle=Impulse.ar((p.value(\attack)+p.value(\decay)).reciprocal)*p.value(\cycle)*playing;
                        var envs=Array.fill(4,{ |j|
                            var env=EnvGen.ar(Env.perc(p.value(\attack),p.value(\decay),1,p.value(\curve)),i.value(("g"++(j+1)).asSymbol)+cycle);
                            o.value(("v"++(j+1)).asSymbol,env); env
                        });
                        o.value(\end,Trig1.ar((HPZ1.ar(envs[0]>0)).neg.max(0),0.01))
                    },
                    \adsr, {
                        var envs=Array.fill(2,{ |j| EnvGen.ar(Env.adsr(p.value(\attack),p.value(\decay),p.value(\sustain),p.value(\release)),i.value(("g"++(j+1)).asSymbol)) });
                        o.value(\v1,envs[0]); o.value(\v2,envs[1]); o.value(\inv,envs[0].neg)
                    },
                    \xy, {
                        var x=XFade2.kr(p.value(\x),SinOsc.kr(p.value(\rate)),p.value(\auto)*2-1);
                        var y=XFade2.kr(p.value(\y),SinOsc.kr(p.value(\rate),0.5pi),p.value(\auto)*2-1);
                        o.value(\x,K2A.ar(x)); o.value(\y,K2A.ar(y)); o.value(\mix,i.value(\in)*x)
                    },
                    \hold, {
                        o.value(\hold,Latch.ar(i.value(\in),i.value(\gate)));
                        o.value(\slew,LagUD.ar(i.value(\in),p.value(\rise),p.value(\fall)))
                    },
                    \filter, {
                        var sig=(i.value(\in)*p.value(\drive)).tanh;
                        var cutoff=(p.value(\cutoff)*(2 ** (i.value(\cv)*p.value(\fm)))).clip(20,19000);
                        var rq=(1-p.value(\res)).max(0.02);
                        o.value(\low,RLPF.ar(sig,cutoff,rq)); o.value(\band,BPF.ar(sig,cutoff,rq)); o.value(\high,RHPF.ar(sig,cutoff,rq))
                    },
                    \dualfilter, {
                        var mod=2 ** (i.value(\cv)*p.value(\fm));
                        var rq=(1-p.value(\res)).max(0.02);
                        var va=RLPF.ar(i.value(\in),(p.value(\cutoff)*mod).clip(20,19000),rq);
                        var vb=RHPF.ar(i.value(\inB),(p.value(\cutoffB)*mod).clip(20,19000),rq);
                        o.value(\a,va); o.value(\b,vb); o.value(\mix,(va+vb)*0.5)
                    },
                    \lpg, {
                        var env=Decay2.ar(Trig1.ar(i.value(\gate),0.001),0.001,p.value(\decay));
                        o.value(\out,LPF.ar(i.value(\in),(env*p.value(\tone)+60).clip(20,19000))*env)
                    },
                    \vca, {
                        var sigs=Array.fill(4,{ |j|
                            var num=j+1;
                            var cv=Select.ar(patched.value(("cv"++num).asSymbol),[DC.ar(1),i.value(("cv"++num).asSymbol).clip(0,4)]);
                            var sig=i.value(("in"++num).asSymbol)*cv*p.value(("gain"++num).asSymbol);
                            o.value(("v"++num).asSymbol,sig); sig
                        }); o.value(\mix,Mix(sigs))
                    },
                    \mixer, {
                        var sigs=(1..4).collect { |j| i.value(("in"++j).asSymbol)*p.value(("gain"++j).asSymbol) };
                        o.value(\out,Mix(sigs)); o.value(\stereo,Mix(sigs.collect { |sig,j| Pan2.ar(sig,j.linlin(0,3,-1,1)) }))
                    },
                    \attenuverter, {
                        var sigs=(1..3).collect { |j|
                            var sig=(i.value(("in"++j).asSymbol)*p.value(("gain"++j).asSymbol))+p.value(\offset);
                            o.value(("v"++j).asSymbol,sig); sig
                        }; o.value(\mix,Mix(sigs))
                    },
                    \mult, { (1..4).do { |j| o.value(("v"++j).asSymbol,i.value(\in)) } },
                    \logic, {
                        var va=i.value(\a)>p.value(\threshold), vb=i.value(\b)>p.value(\threshold);
                        o.value(\or,(va+vb).min(1)); o.value(\and,va*vb); o.value(\xor,(va-vb).abs); o.value(\not,1-va)
                    },
                    \divider, {
                        var clock=i.value(\clock),count=PulseCount.ar(clock,i.value(\reset));
                        [2,4,8,16].do { |j| o.value(("d"++j).asSymbol,clock*((count%j) |==| 0)) }
                    },
                    \ringmod, { o.value(\out,i.value(\a)*i.value(\b)*p.value(\gain)) },
                    \crossfade, { o.value(\out,XFade2.ar(i.value(\a),i.value(\b),((p.value(\mix)+i.value(\cv))*2-1).clip(-1,1))) },
                    \folder, {
                        var sig=i.value(\in);
                        var folded=((sig*(p.value(\drive)*(2 ** i.value(\cv))))+p.value(\bias)).fold2(1);
                        o.value(\out,XFade2.ar(sig,LeakDC.ar(folded),p.value(\mix)*2-1))
                    },
                    \delay, {
                        var sig=i.value(\in),local=LocalIn.ar(2);
                        var time=Lag.ar((p.value(\time)*(2 ** i.value(\cv))).clip(0.005,4),0.08);
                        var wet=DelayC.ar((sig!2)+(local.reverse*p.value(\feedback)),4.1,[time,time*1.017]);
                        var result;
                        wet=LPF.ar(wet,p.value(\tone)).tanh;
                        LocalOut.ar(wet);
                        if(id==\rainmaker) { wet=wet + (Mix(Array.fill(6,{ |j| DelayC.ar(sig,4.1,(time*((j+1)/7)).clip(0.001,4))*0.12 }))!2) };
                        result=XFade2.ar(sig!2,wet,p.value(\mix)*2-1);
                        o.value(\out,Mix(result)*0.5); o.value(\stereo,result)
                    },
                    \reverb, {
                        var sig=i.value(\in);
                        var wet=FreeVerb2.ar(sig,DelayC.ar(sig,0.02,0.011),1,p.value(\room),p.value(\damp));
                        var result=XFade2.ar(sig!2,wet,p.value(\mix)*2-1);
                        o.value(\out,Mix(result)*0.5); o.value(\stereo,result)
                    },
                    \spring, {
                        var sig=i.value(\in);
                        var wet=Mix(CombC.ar(sig,0.1,[0.0297,0.0371,0.0411],p.value(\decay)))*0.25;
                        3.do { |j| wet=AllpassC.ar(wet,0.05,0.007*(j+1),0.15) };
                        wet=LPF.ar(wet,p.value(\tone)); o.value(\out,XFade2.ar(sig,wet,p.value(\mix)*2-1))
                    },
                    \compressor, {
                        var sig=i.value(\in);
                        var side=Select.ar(patched.value(\side),[sig,i.value(\side)]);
                        o.value(\out,Compander.ar(sig,side,p.value(\threshold),1,p.value(\ratio).reciprocal,p.value(\attack),p.value(\release)))
                    },
                    \feedback, { o.value(\out,DelayC.ar(LeakDC.ar(i.value(\in)).tanh,1.01,p.value(\time))*p.value(\gain)) },
                    \input, {
                        var chan=p.value(\channel).clip(0,(NamedControl.kr(\global_inputs,0)-1).max(0));
                        var enabled=NamedControl.kr(\global_inputs,0)>0;
                        var sig=In.ar(NumOutputBuses.ir+chan,2)*p.value(\gain)*enabled;
                        o.value(\out,sig[0]); o.value(\stereo,sig)
                    },
                    \midi, {
                        o.value(\pitch,K2A.ar(NamedControl.kr(\note,0)+NamedControl.kr(\bend,0)));
                        o.value(\gate,K2A.ar(NamedControl.kr(\gate,0)*playing));
                        o.value(\velocity,K2A.ar(NamedControl.kr(\velocity,0)));
                        o.value(\mod,K2A.ar(NamedControl.kr(\modwheel,0)))
                    },
                    \scope, {
                        var sig=i.value(\in), pitch=Pitch.kr(sig);
                        o.value(\out,sig);
                        SendReply.kr(Impulse.kr(8),'/mms/scope',[NamedControl.kr(\moduleID,0),pitch[0],pitch[1],Amplitude.kr(sig)])
                    },
                    \spatial, {
                        var sig=i.value(\in);
                        var phase=Phasor.ar(0,(p.value(\rate)+i.value(\speed))*SampleDur.ir,0,1);
                        var pos=(phase+(p.value(\azimuth)/360)+(i.value(\cv)*p.value(\depth)/360)).wrap(0,1);
                        var width=p.value(\spread).max(1);
                        var weights=Array.fill(32,{ |j|
                            var distance=(pos-(j/n)).wrap(-0.5,0.5).abs*n;
                            ((distance/width)*pi).clip(0,0.5pi).cos*(j<n)
                        });
                        var norm=(Mix(weights.squared).sqrt).max(0.001);
                        o.value(\ring,weights.collect { |w| sig*w/norm });
                        SendReply.kr(Impulse.kr(12),'/mms/orbit',[NamedControl.kr(\moduleID,0),A2K.kr(pos)])
                    },
                    \ambisonic, {
                        var ring=i.value(\ring), mono=i.value(\mono);
                        var rotate=p.value(\rotate)*pi/180;
                        var elevation=p.value(\elevation)*pi/180;
                        var az=(i.value(\az)*pi)+rotate;
                        var field=[mono,mono*az.sin*elevation.cos,mono*elevation.sin,mono*az.cos*elevation.cos];
                        ring.do { |sig,j|
                            var angle=((j*2pi)/n)+rotate;
                            field=field + ([sig,sig*angle.sin,DC.ar(0),sig*angle.cos]*(j<n))
                        };
                        o.value(\ambi,field)
                    },
                    \ambidecode, {
                        var ring=ringDecode.value(i.value(\ambi),n,p.value(\yaw)*pi/180);
                        o.value(\ring,ring); o.value(\stereo,foldStereo.value(ring,n))
                    },
                    \binaural, {
                        var result=ears.value(i.value(\ring),n,p.value(\yaw)*pi/180);
                        result=result+(FreeVerb2.ar(result[0],result[1],1,0.55,0.7)*p.value(\room));
                        o.value(\stereo,result)
                    },
                    \stereofold, { o.value(\stereo,foldStereo.value(i.value(\ring),n,p.value(\width))) },
                    \monitor, {
                        var mode=NamedControl.kr(\global_mode,1), volume=NamedControl.kr(\global_volume,0.35);
                        var ring=i.value(\ring), field=i.value(\ambi);
                        var decoded=ringDecode.value(field,n);
                        var sumRing=ring+(decoded*(1-patched.value(\ring)));
                        var base=i.value(\stereo)+(i.value(\mono)!2);
                        var stereo=base+Select.ar(mode.clip(0,1),[foldStereo.value(sumRing,n),ears.value(sumRing,n)]);
                        var stereoMode=(mode<2),speakerMode=(mode |==| 2),ambiMode=(mode |==| 3);
                        var count=NamedControl.kr(\global_hardware,2);
                        var gain=Lag.kr(volume*playing,0.05);
                        var audio=Array.fill(a[\hardware],{ |j|
                            var sig=DC.ar(0);
                            if(j<2) { sig=sig+(stereo[j]*stereoMode) };
                            sig=sig+(sumRing[j]*speakerMode*(j<n));
                            if(j<4) { sig=sig+(field[j]*ambiMode) };
                            Limiter.ar(LeakDC.ar(sig*gain),0.94,0.005)
                        });
                        Out.ar(0,audio);
                        SendReply.kr(Impulse.kr(15),'/mms/meter',[Amplitude.kr(audio[0]),Amplitude.kr(audio[1]),Peak.kr(Mix(audio).abs,Impulse.kr(15))])
                    }
                )
            });
            a[\defs][id]=def;
            def.asSynthDesc;
            if(a[\server].notNil and: { a[\server].hasBooted }) { def.send(a[\server]) }
        }
    };
}
