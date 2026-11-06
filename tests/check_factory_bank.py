#!/usr/bin/env python3
"""Check each factory patch's actual 8-second audio render; standard library only."""
import argparse
import collections
import csv
import hashlib
import json
import math
from pathlib import Path
from check_audio import read_float_wav

ROOT=Path(__file__).resolve().parents[1]

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--render-dir',type=Path,default=Path('/tmp/microms-bank-renders'))
    args=parser.parse_args()
    patches=sorted((ROOT/'presets').glob('[0-9][0-9]-*.microms'))
    assert len(patches)==50, f'Expected 50 new patches, found {len(patches)}'
    signatures=set(); audio_hashes=set(); rows=[]; styles=collections.Counter()
    for path in patches:
        patch=json.loads(path.read_text())
        signature=json.dumps({k:patch[k] for k in ['edo','rootHz','modules','cables']},sort_keys=True)
        assert signature not in signatures,f'{path.name}: duplicate patch'
        signatures.add(signature)
        assert all(m['samplePath'] is None for m in patch['modules']),path.name
        assert patch['mode']==1 and patch['channels'] in [4,8,16,24,32],path.name
        assert 7<=patch['edo']<=120 and 0<patch['volume']<=.9,path.name
        styles[patch['style']]+=1
        wav=args.render_dir/(path.stem+'.wav')
        channels,rate,samples=read_float_wav(wav)
        assert channels==2 and rate==48000 and len(samples)>=channels*rate*7.9,path.name
        peak=max(abs(min(samples)),abs(max(samples)))
        active=samples[int(rate*channels*.4):int(rate*channels*7.3)]
        rms=math.sqrt(sum(value*value for value in active)/len(active))
        assert .005<peak<=.941, (path.name,'silent or overloaded',peak)
        assert .001<rms<.13, (path.name,'unexpected output level',rms)
        for channel in range(channels):
            assert max(abs(v) for v in active[channel::channels])>.001,(path.name,channel,'silent channel')
        audio_hash=hashlib.sha256(samples.tobytes()).hexdigest()
        assert audio_hash not in audio_hashes,f'{path.name}: duplicate audio'
        audio_hashes.add(audio_hash)
        rows.append([path.name,patch['style'],patch['edo'],len(patch['modules']),peak,rms])
        print(f'PASS: {path.stem}: peak={peak:.3f}, RMS={rms:.4f}')
    assert len(styles)==10 and all(count==5 for count in styles.values()),styles
    with (args.render_dir/'validation.csv').open('w') as f:
        writer=csv.writer(f);writer.writerow(['preset','style','edo','modules','peak','rms']);writer.writerows(rows)
    print('PASS: 50 distinct, self-contained factory presets; stereo audio is finite and audible in every render.')

if __name__=='__main__': main()
