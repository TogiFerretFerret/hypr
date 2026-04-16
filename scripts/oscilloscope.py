#!/usr/bin/env python3
import sys, struct, subprocess, threading, time
from collections import deque

RATE  = 8000
BARS  = 32   # per channel; 64 total output
FPS   = 60

default_sink = subprocess.check_output(['pactl', 'get-default-sink'], text=True).strip()
monitor = default_sink + '.monitor'

samples_l = deque(maxlen=RATE)
samples_r = deque(maxlen=RATE)
lock = threading.Lock()

def reader():
    proc = subprocess.Popen(
        ['parec', '--format=float32le', f'--rate={RATE}', '--channels=2',
         '--latency-msec=10', f'--device={monitor}'],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL
    )
    while True:
        # 2 channels * 4 bytes * 32 samples = 256 bytes
        data = proc.stdout.read(256)
        if not data:
            break
        count = len(data) // 4
        floats = struct.unpack(f'{count}f', data[:count * 4])
        lefts  = floats[0::2]
        rights = floats[1::2]
        with lock:
            samples_l.extend(lefts)
            samples_r.extend(rights)

t = threading.Thread(target=reader, daemon=True)
t.start()

interval = 1.0 / FPS
while True:
    start = time.monotonic()
    with lock:
        snap_l = list(samples_l)[-BARS:] if len(samples_l) >= BARS else [0] * BARS
        snap_r = list(samples_r)[-BARS:] if len(samples_r) >= BARS else [0] * BARS
    step = len(snap_l) / BARS
    out_l = [int(max(-100, min(100, snap_l[int(i * step)] * 100))) for i in range(BARS)]
    out_r = [int(max(-100, min(100, snap_r[int(i * step)] * 100))) for i in range(BARS)]
    sys.stdout.write(';'.join(map(str, out_l + out_r)) + '\n')
    sys.stdout.flush()
    elapsed = time.monotonic() - start
    time.sleep(max(0, interval - elapsed))
