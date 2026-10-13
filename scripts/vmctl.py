#!/usr/bin/env python3
"""Drive a headless SpeedyOS test VM started with `run-vm.sh ... --headless`.

Talks to QEMU's QMP socket (screenshots, keyboard, mouse) and to the QEMU
guest agent inside the VM (run commands, read files). Only ever touches the
VM; nothing runs on the host besides socket I/O.

  vmctl.py shot FILE.png             screenshot
  vmctl.py click X Y [--right]       click at screen pixel (needs usb-tablet)
  vmctl.py dclick X Y                double-click
  vmctl.py key KEY [KEY...]          press a key combo, e.g. key ctrl alt t
  vmctl.py type TEXT                 type text (US layout)
  vmctl.py exec 'SHELL CMD'          run as root in the guest, print output
  vmctl.py wait-agent [SECONDS]      wait until the guest agent answers
  vmctl.py quit                      power off the VM immediately
"""
import json
import os
import socket
import sys
import time
import base64

VM_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "vm")
QMP = os.path.join(VM_DIR, "qmp.sock")
QGA = os.path.join(VM_DIR, "qga.sock")


class Qmp:
    def __init__(self, path=QMP):
        self.s = socket.socket(socket.AF_UNIX)
        self.s.connect(path)
        self.f = self.s.makefile("rw")
        self._read()  # greeting
        self.cmd("qmp_capabilities")

    def _read(self):
        while True:
            msg = json.loads(self.f.readline())
            if "event" not in msg:
                return msg

    def cmd(self, name, **args):
        self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
        self.f.flush()
        r = self._read()
        if "error" in r:
            raise RuntimeError(f"{name}: {r['error']}")
        return r.get("return")


def screen_size(q):
    tmp = os.path.join(VM_DIR, ".size.ppm")
    q.cmd("screendump", filename=tmp)
    with open(tmp, "rb") as f:
        f.readline()
        w, h = map(int, f.readline().split())
    os.unlink(tmp)
    return w, h


def click(q, x, y, button="left", count=1):
    w, h = screen_size(q)
    ev = [{"type": "abs", "data": {"axis": "x", "value": int(x * 32767 / (w - 1))}},
          {"type": "abs", "data": {"axis": "y", "value": int(y * 32767 / (h - 1))}}]
    q.cmd("input-send-event", events=ev)
    time.sleep(0.15)
    for _ in range(count):
        for down in (True, False):
            q.cmd("input-send-event", events=[{"type": "btn", "data": {"down": down, "button": button}}])
            time.sleep(0.06)


SHIFTED = {'!': '1', '@': '2', '#': '3', '$': '4', '%': '5', '^': '6', '&': '7', '*': '8',
           '(': '9', ')': '0', '_': 'minus', '+': 'equal', '{': 'bracket_left',
           '}': 'bracket_right', '|': 'backslash', ':': 'semicolon', '"': 'apostrophe',
           '<': 'comma', '>': 'dot', '?': 'slash', '~': 'grave_accent'}
PLAIN = {' ': 'spc', '-': 'minus', '=': 'equal', '[': 'bracket_left', ']': 'bracket_right',
         '\\': 'backslash', ';': 'semicolon', "'": 'apostrophe', ',': 'comma', '.': 'dot',
         '/': 'slash', '`': 'grave_accent', '\n': 'ret', '\t': 'tab'}


def keys(q, names):
    q.cmd("send-key", keys=[{"type": "qcode", "data": n} for n in names])
    time.sleep(0.05)


def type_text(q, text):
    for ch in text:
        if ch in PLAIN:
            keys(q, [PLAIN[ch]])
        elif ch in SHIFTED:
            keys(q, ["shift", SHIFTED[ch]])
        elif ch.isupper():
            keys(q, ["shift", ch.lower()])
        else:
            keys(q, [ch])


class Agent:
    def __init__(self, path=QGA, timeout=10):
        self.s = socket.socket(socket.AF_UNIX)
        self.s.settimeout(timeout)
        self.s.connect(path)
        self.f = self.s.makefile("rw")
        sync = int(time.time()) & 0xffff
        self.f.write(json.dumps({"execute": "guest-sync", "arguments": {"id": sync}}) + "\n")
        self.f.flush()
        while json.loads(self.f.readline()).get("return") != sync:
            pass

    def cmd(self, name, **args):
        self.f.write(json.dumps({"execute": name, "arguments": args}) + "\n")
        self.f.flush()
        r = json.loads(self.f.readline())
        if "error" in r:
            raise RuntimeError(f"{name}: {r['error']}")
        return r.get("return")

    def run(self, shell_cmd, timeout=900):
        pid = self.cmd("guest-exec", path="/bin/sh", arg=["-c", shell_cmd],
                       **{"capture-output": True})["pid"]
        end = time.time() + timeout
        while time.time() < end:
            st = self.cmd("guest-exec-status", pid=pid)
            if st["exited"]:
                out = base64.b64decode(st.get("out-data", "")).decode(errors="replace")
                err = base64.b64decode(st.get("err-data", "")).decode(errors="replace")
                return st.get("exitcode", -1), out, err
            time.sleep(0.5)
        raise TimeoutError(shell_cmd)


def main(argv):
    if len(argv) < 2 or argv[1] in ("-h", "--help"):
        print(__doc__)
        return 0
    op, rest = argv[1], argv[2:]
    if op == "shot":
        Qmp().cmd("screendump", filename=os.path.abspath(rest[0]), format="png")
    elif op in ("click", "dclick"):
        click(Qmp(), int(rest[0]), int(rest[1]),
              "right" if "--right" in rest else "left", 2 if op == "dclick" else 1)
    elif op == "key":
        keys(Qmp(), rest)
    elif op == "type":
        type_text(Qmp(), " ".join(rest))
    elif op == "exec":
        code, out, err = Agent().run(" ".join(rest))
        sys.stdout.write(out)
        sys.stderr.write(err)
        return code
    elif op == "wait-agent":
        end = time.time() + float(rest[0] if rest else 300)
        while time.time() < end:
            try:
                Agent(timeout=3).cmd("guest-ping")
                print("guest agent is up")
                return 0
            except (OSError, socket.timeout, ValueError, RuntimeError):
                time.sleep(3)
        print("guest agent did not answer", file=sys.stderr)
        return 1
    elif op == "quit":
        Qmp().cmd("quit")
    else:
        print(__doc__)
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
