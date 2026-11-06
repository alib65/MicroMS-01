#!/usr/bin/env python3
"""Author the 50-patch factory bank using the actual Catalog.scd schema.
First export it: sclang -D -l tests/runtime.yaml tests/export-preset-schema.scd "$PWD"
Then run this script. SuperCollider itself never requires Python.
"""
from pathlib import Path
import csv
import json
import math

ROOT = Path(__file__).resolve().parents[1]
LEVELS_PATH = ROOT/'tools'/'factory-levels.json'
LEVELS = json.loads(LEVELS_PATH.read_text()) if LEVELS_PATH.exists() else {}
SCHEMA = {}
for kind, family in csv.reader(open('/tmp/microms-modules.csv')):
    SCHEMA[kind] = dict(family=family, params={}, ports={})
for kind, key, lo, hi, default, warp in csv.reader(open('/tmp/microms-params.csv')):
    SCHEMA[kind]['params'][key] = (float(lo), float(hi), float(default), warp)
for kind, direction, key, width, signal in csv.reader(open('/tmp/microms-ports.csv')):
    SCHEMA[kind]['ports'][direction, key] = (int(width), signal)

TITLES = [
 ('Neon Caravan',19,'Sequenced lead','A syncopated saw melody with warm filtering and dotted echoes.'),
 ('Chromatic Fireflies',12,'Sequenced lead','Bright pulse notes, moving pulse width and short stereo repeats.'),
 ('Copper Spiral',22,'Sequenced lead','Wavefolded triangle arpeggios with a five-step turnaround.'),
 ('Prism Runner',31,'Sequenced lead','Phase-modulated lead with a slowly changing FM index.'),
 ('Seven Lanterns',7,'Sequenced lead','A spacious seven-division melody with a spring-like halo.'),
 ('Basalt Engine',12,'Bass','Compact sub bass with fast amplitude and cutoff envelopes.'),
 ('Subterranean Pulse',16,'Bass','Square/sub layering and a tight eight-step low-register groove.'),
 ('Acid Mosaic',19,'Bass','Resonant saw bass with glide, envelope sweeps and filtered echoes.'),
 ('Magnetic Dub',24,'Bass','Sparse triangle bass, long offbeat delay and slow circular movement.'),
 ('Elastic Gravity',11,'Bass','Folded bass with a rubbery filter envelope and a seven-step phrase.'),
 ('Mercury Bells',31,'FM keys','Clear near-harmonic FM bells with long decay and room reverb.'),
 ('Glass Constellations',17,'FM keys','High inharmonic chimes with a rotating stereo delay.'),
 ('Ceramic Orbit',13,'FM keys','Hollow mallet tones and damped spring-like resonance.'),
 ('Chiming Lattice',41,'FM keys','Fine-grained descending bell steps and bright spacious tails.'),
 ('Aurora Keys',53,'FM keys','Warm electric-piano-like FM chords implied by overlapping notes.'),
 ('Silk Road Strings',17,'Plucked strings','A resonant low string melody with expressive damping.'),
 ('Bamboo Rain',9,'Plucked strings','Short wooden plucks and skipping gates in nine divisions.'),
 ('Silver Kora',22,'Plucked strings','High metallic strings with a five-note repeating figure.'),
 ('Clockwork Harp',31,'Plucked strings','Fast harp patterns, long resonance and cascading repeats.'),
 ('Velvet Kalimba',12,'Plucked strings','Soft damped plucks with a compact room and gentle orbit.'),
 ('Frozen Pollen',72,'Granular','Slow pitched grains, broad reverb and glacial filter motion.'),
 ('Reverse Nebula',29,'Granular','Reverse grains with wavefolding and shadowy delay.'),
 ('Velvet Static',8,'Granular','Dense short grains softened by a moving low-pass filter.'),
 ('Granular Mirage',48,'Granular','A clocked granular melody with roaming sample position.'),
 ('Polar Dust',120,'Granular','Fine-division grains, sparse pitch steps and long diffuse decay.'),
 ('Distant Suns',10,'Ambient drone','Two beating oscillators, slow crossfade and broad reverb.'),
 ('Slow Tectonics',26,'Ambient drone','Low folded drone layers and slowly opening filters.'),
 ('Violet Horizon',34,'Ambient drone','A detuned upper drone with subtle phase modulation.'),
 ('Sleepwalk Cathedral',43,'Ambient drone','Fifth-related oscillators with long comb and room tails.'),
 ('Ocean of Fifths',60,'Ambient drone','A drifting harmonic pair in an Ambisonic listening field.'),
 ('Carbon Footsteps',12,'Percussion','Sine kick, filtered snare and patterned noise hats.'),
 ('Broken Satellites',15,'Percussion','Uneven metallic percussion with a clipped echo tail.'),
 ('Neon Steam',20,'Percussion','Open noise hats, punchy low drum and quick stereo motion.'),
 ('Ceramic Machines',27,'Percussion','Resonant band-pass drums, short envelopes and spring coloration.'),
 ('Dust Circuit',35,'Percussion','A dry compressed machine groove with sparse hat accents.'),
 ('Probability Garden',19,'Generative','Clocked random pitch quantized into a plucked melodic garden.'),
 ('Moonlit Switches',23,'Generative','Smoothed random pitch with soft gated tones and filtered echoes.'),
 ('Fractal Orchard',37,'Generative','Slow pitch memory drives a resonant string with varying EDO count.'),
 ('Solar Dice',47,'Generative','Angular randomized FM pulses through a folding stage.'),
 ('Quiet Automata',80,'Generative','Smoothed random voltages, finely quantized plucks and long echoes.'),
 ('Three Against Seven',14,'Polyrhythmic duet','A three-step synth phrase against seven-step plucked strings.'),
 ('Binary Bazaar',21,'Polyrhythmic duet','Two independent gate patterns drive contrasting melodic voices.'),
 ('Fivefold Crossing',25,'Polyrhythmic duet','A five-step FM line crosses a divided seven-note string phrase.'),
 ('Spiral Conversation',33,'Polyrhythmic duet','Ascending and descending voices converse at different clock divisions.'),
 ('Luminous Gears',55,'Polyrhythmic duet','Tightly interlocked plucks and a bright sustained counterline.'),
 ('Quad Compass',18,'Spatial experiment','Two voices travel independently through a four-speaker Ambisonic field.'),
 ('Octagonal Rain',28,'Spatial experiment','A spinning pluck ring combines with a second positioned tone.'),
 ('Sixteen Moons',46,'Spatial experiment','Sixteen-channel motion surrounds a slowly moving FM voice.'),
 ('Helix Observatory',64,'Spatial experiment','Two tonal layers explore a 24-speaker virtual field.'),
 ('Infinite Carousel',96,'Spatial experiment','A 32-channel ring crosses a separately moving pitched source.')
]
MELODIES = [
 [0,3,7,10,12,7,5,2], [0,7,12,10,3,5,14,7],
 [0,2,5,9,7,4,12,11], [12,10,7,3,0,5,7,14], [0,4,7,11,9,7,4,2]
]
GATE_MASKS = [[1,1,0,1,1,1,0,1],[1,0,1,1,0,1,1,1],[1,1,1,0,1,0,1,1],[1,0,0,1,0,1,0,1],[1,1,0,1,0,1,1,0]]
ROOTS = [130.81278265,146.83238396,110.0,164.81377846,98.0]

class Patch:
    def __init__(self, index):
        self.index = index
        self.name,self.edo,self.style,self.description = TITLES[index]
        self.v = index % 5
        self.modules=[]; self.cables=[]
        self.data=dict(format='MicroMS-01',version=1,edo=self.edo,rootHz=ROOTS[self.v],
                       channels=[4,8,16,24,32][self.v],mode=1,volume=LEVELS.get(self.name,0.43),
                       name=self.name,author='Ali Balighi',copyright='Ali Balighi © 2026 - Alibalighi.com',
                       description=self.description,style=self.style,
                       modules=self.modules,cables=self.cables)
    def add(self,kind,**overrides):
        schema=SCHEMA[kind]
        params={k:(round(v[2]) if v[3]=='step' else v[2]) for k,v in schema['params'].items()}
        params.update(overrides)
        if schema['family']=='quantizer': params['edo']=self.edo
        for key,val in params.items():
            lo,hi,_,warp=schema['params'][key]
            assert lo <= val <= hi,(kind,key,val,lo,hi)
            assert warp!='step' or val==round(val),(kind,key,val)
        m=dict(id=len(self.modules)+1,type=kind,params=params,
               steps=[0]*8,gates=[1]*8,patterns=[[int(k%(j+2)==0) for k in range(16)] for j in range(4)],samplePath=None)
        self.modules.append(m); return m
    def wire(self,src,output,dst,input):
        source=SCHEMA[src['type']]['ports']['out',output]
        target=SCHEMA[dst['type']]['ports']['in',input]
        assert source[0]==target[0] and (source[0]==1 or source[1]==target[1]),(src,output,dst,input)
        assert not any(c['to']==dst['id'] and c['input']==input for c in self.cables),(dst,input)
        self.cables.append(dict(from_=src['id'],output=output,to=dst['id'],input=input))
        self.cables[-1]['from']=self.cables[-1].pop('from_')
    def sequence(self,clock,length=8,melody=None,glide=0,mask=None,output='clock'):
        seq=self.add('sequencer',length=length,swing=glide)
        seq['steps']=[round(x*self.edo/12) for x in (melody or MELODIES[self.v])]
        if self.edo>12 and self.edo%12==0:
            seq['steps']=[step+offset for step,offset in zip(seq['steps'],[0,1,-1,1,0,-1,2,-2])]
        seq['gates']=(mask or GATE_MASKS[self.v]).copy()
        self.wire(clock,output,seq,'clock'); self.wire(clock,'reset',seq,'reset')
        q=self.add('quantizer'); self.wire(seq,'pitch',q,'pitch')
        return seq,q
    def tail(self,src,key,fx='reverb',mix=None,rate=None,route='ring'):
        v=self.v
        if fx=='delay':
            effect=self.add('delay',time=[.28125,.1875,.375,.5625,.4286][v],feedback=.25+v*.075,tone=4200+v*1300,mix=mix if mix is not None else .28)
        elif fx=='spring': effect=self.add('spring',decay=.8+v*.55,tone=2400+v*1200,mix=mix if mix is not None else .32)
        elif fx=='rainmaker': effect=self.add('rainmaker',time=.19+v*.087,feedback=.28+v*.05,mix=mix if mix is not None else .32)
        else: effect=self.add('reverb',room=.72+v*.055,damp=.62-v*.09,mix=mix if mix is not None else .38)
        self.wire(src,key,effect,'in')
        orbit=self.add('spatial',azimuth=-120+v*60,rate=rate if rate is not None else [.043,-.075,.12,-.028,.19][v],spread=1.2+v*.45,depth=85)
        self.wire(effect,'out',orbit,'in')
        field=self.add('ambisonic',rotate=v*13-26); self.wire(orbit,'ring',field,'ring')
        out=self.add('monitor')
        if route=='ambi':
            decode=self.add('ambidecode',yaw=v*11-22)
            self.wire(field,'ambi',decode,'ambi'); self.wire(decode,'ring',out,'ring')
            self.wire(field,'ambi',out,'ambi')
        elif route=='ears':
            ear=self.add('binaural',yaw=v*15-30,room=.04+v*.025)
            self.wire(orbit,'ring',ear,'ring'); self.wire(ear,'stereo',out,'stereo')
        else:
            self.wire(orbit,'ring',out,'ring'); self.wire(field,'ambi',out,'ambi')
        return orbit,field,out
    def finish(self):
        used={c['from'] for c in self.cables}|{c['to'] for c in self.cables}
        assert len(used)==len(self.modules),(self.name,'disconnected module')
        assert len([m for m in self.modules if m['type']=='monitor'])==1
        return self.data


def lead(p,bass=False):
    v=p.v
    clock=p.add('clock',bpm=([118,132,107,143,92] if not bass else [126,104,138,74,112])[v],division=4,width=.25 if bass else .43)
    seq,q=p.sequence(clock,length=[8,8,5,8,7][v],glide=([0,.014,.008,.025,.006] if not bass else [.012,0,.07,.03,.1])[v])
    kind=['vco','vco','vco','complex','voice'][v] if not bass else ['voice','vco','vco','vco','complex'][v]
    osc=p.add(kind,octave=-1 if bass else (1 if v==1 else 0))
    p.wire(q,'out',osc,'pitch')
    osc_key='out' if kind in ('voice','complex') else (['saw','pulse','tri','pulse','saw'][v] if not bass else ['sine','sub','saw','tri','saw'][v])
    if kind=='voice':
        osc['params'].update(cutoff=420 if bass else 2600,res=.4 if bass else .28,attack=.002 if bass else .009,release=.16 if bass else .25,env=3.5 if bass else 1.5)
        p.wire(seq,'gate',osc,'gate')
    if kind=='complex': osc['params'].update(ratio=1.5 if bass else 2.5,index=.9 if bass else 1.8,shape=1.8 if bass else 1.2)
    lfo=p.add('lfo',rate=.06+v*.085,depth=.2 if bass else .37,shape=v%3)
    if kind=='vco' and v==1: p.wire(lfo,'v2',osc,'pwm')
    if kind=='complex': p.wire(lfo,'v3',osc,'mod')
    if v in (2,4):
        fold=p.add('folder',drive=1.7+v*.5,mix=.25 if bass else .45,bias=.07*v)
        p.wire(osc,osc_key,fold,'in'); osc,osc_key=fold,'out'
    filt=p.add('filter',cutoff=([1900,3900,2100,4600,1700] if not bass else [620,420,1050,800,560])[v],res=.64 if bass and v==2 else .25+v*.055,fm=2.2 if bass else 1.5,drive=1.5 if bass else 1.1)
    p.wire(osc,osc_key,filt,'in')
    env=p.add('adsr',attack=.002 if bass else .008,decay=.11+v*.023,sustain=.2 if bass else .36,release=.12+v*.045)
    p.wire(seq,'gate',env,'g1')
    p.wire(env,'v1',filt,'cv') if bass else p.wire(lfo,'v1',filt,'cv')
    amp=p.add('vca',gain1=.8 if bass else .72)
    p.wire(filt,'low',amp,'in1'); p.wire(env,'v1',amp,'cv1')
    if bass and v==1:
        upper=p.add('vco',octave=-1,fine=5,width=.4)
        p.wire(q,'out',upper,'pitch'); p.wire(upper,'pulse',amp,'in2'); p.wire(env,'v1',amp,'cv2'); amp['params']['gain2']=.15
    orbit,_,_=p.tail(amp,'mix',fx=['delay','reverb','delay','rainmaker','spring'][v],mix=.12 if bass and v!=3 else .34,rate=.018 if bass else None)
    if bass:p.wire(lfo,'v2',orbit,'cv')


def bells(p):
    v=p.v
    clock=p.add('clock',bpm=[68,93,84,108,72][v],division=[2,3,2,4,2][v],width=.1)
    seq,q=p.sequence(clock,length=[8,7,5,8,6][v],melody=MELODIES[(v+2)%5])
    osc=p.add('complex',octave=[1,2,0,1,0][v],ratio=[2,3.51,1.4142,5.0,1][v],index=[1.7,3.2,2.4,.9,.7][v],shape=1.0+v*.09)
    p.wire(q,'out',osc,'pitch')
    env=p.add('functions',attack=.002,decay=[1.7,2.3,.65,3.8,1.4][v],curve=-5)
    p.wire(seq,'gate',env,'g1')
    atten=p.add('attenuverter',gain1=.22+v*.03)
    p.wire(env,'v1',atten,'in1'); p.wire(atten,'v1',osc,'mod')
    amp=p.add('vca',gain1=.56); p.wire(osc,'out',amp,'in1'); p.wire(env,'v1',amp,'cv1')
    p.tail(amp,'mix',fx=['reverb','delay','spring','rainmaker','reverb'][v],mix=.4,route='ambi' if v==3 else 'ring')


def strings(p):
    v=p.v
    clock=p.add('clock',bpm=[83,98,116,124,76][v],division=[2,3,3,4,2][v],width=.12)
    seq,q=p.sequence(clock,length=[8,7,5,8,6][v],melody=MELODIES[(v+1)%5])
    string=p.add('pluck',octave=[-1,0,1,1,0][v],decay=[2.6,.35,2.2,4.6,.65][v],damp=[.5,.7,.22,.28,.85][v],excite=[.65,.9,.7,.55,.7][v])
    p.wire(q,'out',string,'pitch'); p.wire(seq,'gate',string,'gate')
    if v==2:
        spring=p.add('spring',decay=1.2,tone=4700,mix=.15); p.wire(string,'out',spring,'in'); string=spring
    p.tail(string,'out',fx=['reverb','spring','delay','rainmaker','reverb'][v],mix=[.28,.24,.32,.36,.23][v],route='ears' if v==1 else 'ring')


def grains(p):
    v=p.v
    clock=p.add('clock',bpm=[46,59,71,98,38][v],division=[1,2,2,3,1][v],width=.62)
    seq,q=p.sequence(clock,length=[5,7,8,8,6][v],melody=[[0,2,7,9,14,12,5,7],[0,-5,7,3,10,-2,5,12],[0,0,3,7,0,5,7,10],[0,7,3,12,10,5,14,7],[0,1,7,12,13,5,3,10]][v],glide=.07+v*.026,mask=[1]*8)
    grain=p.add('sampler',rate=[.55,-.8,.7,1.25,.32][v],position=[.18,.76,.45,.28,.9][v],density=[9,17,64,23,5][v],size=[.52,.24,.025,.11,.85][v],mix=[1,.9,.82,.95,1][v])
    p.wire(q,'out',grain,'pitch'); p.wire(seq,'gate',grain,'gate')
    lfo=p.add('lfo',rate=[.013,.039,.17,.09,.007][v],depth=.15+v*.025,shape=v%3)
    p.wire(lfo,'v1',grain,'pos')
    src,key=grain,'out'
    if v==1:
        folder=p.add('folder',drive=2.8,mix=.36,bias=.1); p.wire(src,key,folder,'in'); src,key=folder,'out'
    filt=p.add('filter',cutoff=[1800,3200,1200,5600,2400][v],res=.25,fm=1.2)
    p.wire(src,key,filt,'in'); p.wire(lfo,'v2',filt,'cv')
    p.tail(filt,'low',fx=['reverb','delay','spring','rainmaker','reverb'][v],mix=[.64,.43,.28,.33,.7][v],rate=[.012,-.032,.08,.13,-.008][v],route='ambi' if v==4 else 'ring')


def drones(p):
    v=p.v
    one=p.add('vco',octave=[0,-1,1,0,0][v],fine=-4-v,width=.35)
    two=p.add('complex',octave=[0,-1,0,-1,0][v],ratio=[1.5,1,2,2.5,3][v],index=.23+v*.15,shape=1+v*.17)
    offset=p.add('attenuverter',gain1=0,offset=round(p.edo*[7/12,.25,7/12,7/12,7/12][v])/p.edo)
    p.wire(offset,'v1',two,'pitch')
    lfo=p.add('lfo',rate=[.017,.011,.032,.009,.014][v],depth=.3,shape=v%2)
    morph=p.add('crossfade',mix=.5); p.wire(one,['tri','saw','pulse','sine','tri'][v],morph,'a'); p.wire(two,'out',morph,'b'); p.wire(lfo,'v1',morph,'cv')
    src=morph
    if v in (1,3):
        folder=p.add('folder',drive=2.2+v*.35,mix=.28); p.wire(src,'out',folder,'in'); src=folder
    filt=p.add('filter',cutoff=[1200,520,2400,1700,2100][v],res=.32+v*.045,fm=1.5)
    p.wire(src,'out',filt,'in'); p.wire(lfo,'v2',filt,'cv')
    if v==3:
        comb=p.add('spring',decay=5,tone=3200,mix=.4); p.wire(filt,'low',comb,'in'); filt=comb
    p.tail(filt,'low' if filt['type']=='filter' else 'out',fx='reverb',mix=.66,rate=[.008,-.013,.024,-.007,.018][v],route='ambi' if v==4 else 'ring')


def drums(p):
    v=p.v
    p.data['rootHz']=[98,110,87.307,130.8128,103.8262][v]
    clock=p.add('clock',bpm=[108,123,132,96,115][v],division=4,width=.12)
    gates=p.add('gates',length=[16,15,16,12,16][v]); p.wire(clock,'clock',gates,'clock'); p.wire(clock,'reset',gates,'reset')
    hits=[[[0,6,8,14],[4,12],[0,2,4,6,8,10,12,14]],[[0,5,9],[3,7,12],[0,2,5,7,9,11,14]],[[0,6,8,11],[4,12],[0,2,4,6,8,10,12,14,15]],[[0,3,7,10],[2,6,11],[0,2,5,8,10]],[[0,7,8],[4,12],[2,6,10,14]]][v]
    gates['patterns']=[[int(j in lane) for j in range(16)] for lane in hits]+[[int(j in [7,15]) for j in range(16)]]
    env=p.add('functions',attack=.001,decay=[.17,.23,.12,.28,.11][v],curve=-6)
    for lane in range(1,5):p.wire(gates,f'g{lane}',env,f'g{lane}')
    kick=p.add('vco',octave=-1,fm=1.5); p.wire(env,'v1',kick,'fm')
    noise=p.add('noise',rate=1,slew=.02)
    snare=p.add('filter',cutoff=[2200,3100,3800,1650,2900][v],res=[.15,.62,.22,.72,.1][v],drive=1.2)
    p.wire(noise,'white',snare,'in')
    hat=p.add('filter',cutoff=[6500,7800,5800,4600,9000][v],res=.12)
    p.wire(noise,'white',hat,'in')
    amp=p.add('vca',gain1=.9,gain2=.55,gain3=.24,gain4=0)
    for n,source,port in [(1,kick,'sine'),(2,snare,'band'),(3,hat,'high')]:
        p.wire(source,port,amp,f'in{n}'); p.wire(env,f'v{n}',amp,f'cv{n}')
    comp=p.add('compressor',threshold=.24,ratio=4,attack=.004,release=.09); p.wire(amp,'mix',comp,'in')
    p.tail(comp,'out',fx=['reverb','delay','delay','spring','reverb'][v],mix=[.1,.23,.17,.24,.07][v],rate=[.018,-.12,.18,.065,-.03][v])


def generative(p):
    v=p.v
    clock=p.add('clock',bpm=[69,81,56,109,44][v],division=[3,2,2,4,2][v],width=.22)
    random=p.add('noise',rate=1,slew=[.03,.3,.09,.01,.7][v]); p.wire(clock,'clock',random,'clock')
    scale=p.add('attenuverter',gain1=[.58,.7,.43,.83,.65][v],offset=[.42,.35,.5,.55,.25][v])
    p.wire(random,'smooth' if v in (1,4) else 'hold',scale,'in1')
    src,key=scale,'v1'
    if v==2:
        memory=p.add('shifter',slew=.08); p.wire(src,key,memory,'in'); p.wire(clock,'slow',memory,'gate'); src,key=memory,'v3'
    q=p.add('quantizer',amount=9 if v==2 else 0); p.wire(src,key,q,'pitch')
    lfo=p.add('lfo',rate=.012+v*.008,depth=.35)
    if v==2:p.wire(lfo,'v1',q,'mod')
    if v in (0,2,4):
        voice=p.add('pluck',octave=0,decay=[1.7,1,3.2,1,3.8][v],damp=.3+v*.1,excite=.75)
        p.wire(q,'out',voice,'pitch'); p.wire(clock,'clock',voice,'gate'); src,key=voice,'out'
    else:
        voice=p.add('voice' if v==1 else 'complex',octave=0)
        p.wire(q,'out',voice,'pitch')
        if v==1:
            voice['params'].update(cutoff=1200,res=.32,attack=.013,release=.65,env=1.7)
            p.wire(clock,'clock',voice,'gate'); src,key=voice,'out'
        else:
            voice['params'].update(ratio=2.7,index=2.1,shape=1.4)
            env=p.add('functions',attack=.003,decay=.18,curve=-5); p.wire(clock,'clock',env,'g1')
            amp=p.add('vca',gain1=.6); p.wire(voice,'out',amp,'in1'); p.wire(env,'v1',amp,'cv1')
            fold=p.add('folder',drive=2.4,mix=.32); p.wire(amp,'mix',fold,'in'); src,key=fold,'out'
    orbit,_,_=p.tail(src,key,fx=['reverb','delay','spring','rainmaker','delay'][v],mix=.36+v*.04,rate=[.06,-.05,.023,.14,-.013][v])
    p.wire(lfo,'v2',orbit,'cv')


def duets(p):
    v=p.v
    clock=p.add('clock',bpm=[97,113,102,89,126][v],division=4,width=.24)
    seq,q=p.sequence(clock,length=[3,8,5,7,8][v],melody=MELODIES[v],mask=[1]*8)
    bseq,bq=p.sequence(clock,length=[7,5,7,8,5][v],melody=list(reversed(MELODIES[(v+2)%5])),mask=GATE_MASKS[(v+2)%5],output='slow')
    a=p.add('voice' if v%2==0 else 'complex',octave=0)
    p.wire(q,'out',a,'pitch')
    if a['type']=='voice':
        a['params'].update(cutoff=1500+v*420,res=.3,attack=.008,release=.25+v*.035,env=1.5); p.wire(seq,'gate',a,'gate'); source,port=a,'out'
    else:
        a['params'].update(ratio=1.5+v*.25,index=1.3)
        env=p.add('functions',attack=.005,decay=.28,curve=-4); p.wire(seq,'gate',env,'g1')
        amp=p.add('vca',gain1=.65); p.wire(a,'out',amp,'in1'); p.wire(env,'v1',amp,'cv1'); source,port=amp,'mix'
    b=p.add('pluck',octave=-1 if v==2 else 0,decay=.9+v*.3,damp=.5,excite=.75)
    p.wire(bq,'out',b,'pitch'); p.wire(bseq,'gate',b,'gate')
    mixer=p.add('mixer',gain1=.55,gain2=.7,gain3=0,gain4=0); p.wire(source,port,mixer,'in1'); p.wire(b,'out',mixer,'in2')
    if v==1:
        rhythm=p.add('gates',length=13); p.wire(clock,'clock',rhythm,'clock'); p.wire(clock,'reset',rhythm,'reset')
        # Replace the two synth articulation cables with independent trigger lanes.
        target=next(m for m in p.modules if m['type']=='functions')
        p.cables[:]=[c for c in p.cables if not ((c['to']==target['id'] and c['input']=='g1') or (c['to']==b['id'] and c['input']=='gate'))]
        p.wire(rhythm,'g1',target,'g1'); p.wire(rhythm,'g3',b,'gate')
    p.tail(mixer,'out',fx=['delay','reverb','spring','rainmaker','delay'][v],mix=.3,rate=[.05,-.07,.11,-.035,.16][v])


def spatial(p):
    v=p.v
    clock=p.add('clock',bpm=[72,94,58,65,104][v],division=[2,3,2,2,4][v],width=.25)
    seq,q=p.sequence(clock,length=[8,7,6,5,8][v])
    first=p.add('pluck',decay=1.4+v*.5,damp=.4,excite=.8,octave=0)
    p.wire(q,'out',first,'pitch'); p.wire(seq,'gate',first,'gate')
    space,field,out=p.tail(first,'out',fx='reverb',mix=.36,rate=[.17,-.25,.08,-.045,.31][v],route='ambi')
    second=p.add('complex',octave=-1 if v==3 else 0,ratio=1.25+v*.5,index=.6+v*.25,shape=1.05)
    p.wire(q,'out',second,'pitch')
    env=p.add('adsr',attack=.04+v*.025,decay=.23,sustain=.35,release=.6+v*.12); p.wire(clock,'slow',env,'g1')
    amp=p.add('vca',gain1=.28); p.wire(second,'out',amp,'in1'); p.wire(env,'v1',amp,'cv1')
    p.wire(amp,'mix',field,'mono')
    head=p.add('lfo',rate=[.037,.061,.019,.027,.083][v],shape=1,depth=.83)
    p.wire(head,'v1',field,'az'); p.wire(head,'v2',space,'cv')
    # Positive/negative CV moves the second source independently of the rotating first voice.
    field['params']['elevation']=0

BUILDERS=[lead,lambda p:lead(p,True),bells,strings,grains,drones,drums,generative,duets,spatial]

def main():
    rows=[]
    for index in range(50):
        p=Patch(index); BUILDERS[index//5](p); data=p.finish()
        filename=f'{index+1:02d}-{p.name.replace(" ","-")}-{p.edo}EDO.microms'
        path=ROOT/'presets'/filename
        path.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n')
        rows.append((filename,p.style,p.edo,len(p.modules),p.description))
    doc=['# MicroMS-01 · 50-preset factory bank','','Ali Balighi © 2026 - Alibalighi.com','',
         'Fifty new patches, in addition to the two original starter presets. All are fully cabled and play without MIDI, external audio or sample files. Granular patches use the built-in generated texture; load a sample to explore other timbres.','',
         'Restart MicroMS-01 once to load the updated preset menu and patch loader. Choose a preset from that menu, or press OPEN and choose a `.microms` file from this folder. Press POWER if needed, then PLAY after loading. The initial listening mode is a headphone preview, with 4/8/16/24/32 virtual speakers. Lower LEVEL before switching to a physical installation.','',
         'Sequence faders use degrees of the listed EDO. Edit faders and gate cells to develop a patch; change tempo, filter, envelope, delay and ORBIT rate for performance. Every patch includes an AmbiX encoder available for selected-output recording.','',
         '| Preset | Style | EDO | Modules | Character |','|---|---|---:|---:|---|']
    for filename,style,edo,count,desc in rows:
        title=filename[3:].removesuffix('.microms').replace('-',' ')
        doc.append(f'| [{title}]({filename}) | {style} | {edo} | {count} | {desc} |')
    (ROOT/'presets'/'README.md').write_text('\n'.join(doc)+'\n')
    print(f'Wrote {len(rows)} fully patched factory presets.')

if __name__=='__main__':main()
