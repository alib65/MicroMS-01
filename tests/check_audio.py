#!/usr/bin/env python3
"""Validate the real float-WAV renders with Python's standard library."""
import array
import csv
import math
import struct
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent

def read_float_wav(path):
    raw = Path(path).read_bytes()
    assert raw[:4] == b'RIFF' and raw[8:12] == b'WAVE', path
    offset, fmt, payload = 12, None, None
    while offset + 8 <= len(raw):
        kind, size = struct.unpack_from('<4sI', raw, offset)
        chunk = raw[offset + 8:offset + 8 + size]
        if kind == b'fmt ':
            fmt = struct.unpack_from('<HHIIHH', chunk)
        elif kind == b'data':
            payload = chunk
        offset += 8 + size + (size % 2)
    assert fmt and payload, f'{path}: empty recording'
    encoding, channels, rate, _, _, bits = fmt
    assert encoding in (3, 65534) and bits == 32, f'{path}: expected float32'
    samples = array.array('f')
    samples.frombytes(payload)
    if sys.byteorder != 'little':
        samples.byteswap()
    assert all(math.isfinite(x) for x in samples), f'{path}: non-finite audio'
    return channels, rate, samples

def check_presets():
    expected = {'stereo-4': 2, 'headphones-8': 2, 'headphones-16': 2,
                'headphones-32': 2, 'speakers-16': 16, 'ambix-4': 4,
                'glass-31edo': 2}
    for name, count in expected.items():
        ch, rate, x = read_float_wav(ROOT / f'{name}.wav')
        assert ch == count and rate == 48000, name
        peak = max(abs(min(x)), abs(max(x)))
        assert 0.001 < peak <= 0.941, (name, peak)
        assert len(x) // ch > 4 * rate, name
        if name == 'ambix-4':
            assert max(abs(v) for v in x[2::4]) < 1e-7, 'horizontal Z must be zero'
        if name == 'speakers-16':
            assert all(max(abs(v) for v in x[j::ch]) > 0.001 for j in range(ch)), 'all speakers must receive audio over a complete orbit'
        print(f'PASS: {name}: {ch} channels, peak {peak:.4f}, finite audio')

def check_edo():
    ch, rate, x = read_float_wav(ROOT / 'edo-7-120.wav')
    assert ch == 2
    for edo in range(7, 121):
        pitch = math.sin(edo * 0.37) * 1.1
        expected = math.floor(pitch * edo + 0.5) / edo
        frame = round((0.1 + (edo - 7) * 0.04 + 0.02) * rate)
        actual = x[frame * ch]
        assert abs(expected - actual) < 1e-6, (edo, expected, actual)
    print('PASS: all 114 EDO choices quantize actual rendered CV correctly')

def check_modules():
    ch, rate, x = read_float_wav(ROOT / 'all-modules.wav')
    assert ch == 2
    allowed_silent = {'input'}
    rows = list(csv.reader((ROOT / 'families.csv').open()))
    for name, family, start, end in rows:
        lo = int((float(start) + 0.05) * rate) * ch
        hi = int((float(end) - 0.01) * rate) * ch
        peak = max(abs(v) for v in x[lo:hi:ch])
        if family != 'monitor':
            assert max(abs(v) for v in x[lo+1:hi:ch]) == 0, f'{name}: CheckBadValues reported invalid audio'
        if family not in allowed_silent:
            assert peak > 1e-7, f'{name}: silent module output'
    print(f'PASS: all {len(rows)} module designs instantiate and process finite audio')

if __name__ == '__main__':
    check_presets()
    check_edo()
    check_modules()
