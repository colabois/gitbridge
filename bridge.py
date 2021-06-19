#!/usr/bin/env python3
import sys
import os
import subprocess
import shlex

def printe(*args, file=sys.stderr, flush=True, **kwargs):
    print(*args, **kwargs, file=file, flush=flush)

printe("\n~~Connecting via git Bridge...~~")
for keyname in map(os.fsdecode, os.listdir('/opt/git/keys')):
    printe(f"\nConnecting using {keyname}")
    proc = subprocess.Popen(["ssh", '-o', 'StrictHostKeyChecking=no', '-i', '/opt/git/keys/'+keyname, 'git@github.com'] + shlex.split(os.environ['SSH_ORIGINAL_COMMAND']), stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    payloads=[]
    while True:
        # printe("Waiting...")
        data = proc.stdout.read(4)
        if data == b'':
            break
        length = int(data, base=16)
        if length != 0:
            payload = proc.stdout.read(length - 4)
            payloads.append(payload)
            # printe('S : ', payload)
        else:
            proc.terminate()
    stderr = proc.stderr.read()
    if stderr != b'ERROR: Repository not found.\n':
        printe("Successfuly connected.")
        pid = subprocess.call(['ssh', '-o', 'StrictHostKeyChecking=no', '-i', '/opt/git/keys/'+keyname, 'git@github.com']+ shlex.split(os.environ['SSH_ORIGINAL_COMMAND']), stdout=sys.stdout, stderr=sys.stderr, stdin=sys.stdin)
        break
    else:
        printe(stderr.decode())
        printe(f"Failed to connect using {keyname}.\n\n")
