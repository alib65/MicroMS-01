#!/bin/zsh
set -eu
project_dir="${0:A:h:h}"
cd "$project_dir"
sc_lang=/Applications/SuperCollider.app/Contents/MacOS/sclang
if [[ ! -x "$sc_lang" ]]; then
  print 'This validation runner targets the macOS SuperCollider installation.'
  exit 1
fi
mkdir -p /tmp/microms-defs
for test_name in compile engine edo-render render families-render ui-interactions gui-smoke realtime; do
  print "Running $test_name..."
  "$sc_lang" -D -l tests/runtime.yaml "tests/$test_name.scd" > "/tmp/microms-$test_name.log" 2>&1
  if rg -n '^ERROR:|FAILURE IN SERVER|FAIL:' "/tmp/microms-$test_name.log"; then
    print "Failed: /tmp/microms-$test_name.log"
    exit 1
  fi
done
python3 tests/check_audio.py
python3 - <<'PY'
import runpy
from pathlib import Path
read_wav = runpy.run_path('tests/check_audio.py')['read_float_wav']
for suffix, count in [('2ch.wav', 2), ('4ch.wav', 4)]:
    files = sorted(Path('recordings').glob('*_' + suffix), key=lambda p: p.stat().st_mtime)
    path = files[-1]
    channels, rate, samples = read_wav(path)
    assert channels == count and len(samples) / channels > rate * 2, path
    print(f'PASS: live {count}-channel recording has complete WAV data')
PY
print 'PASS: full MicroMS-01 validation suite'
