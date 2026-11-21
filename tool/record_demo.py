#!/usr/bin/env python3
"""Records the demo walkthrough (integration_test/demo_test.dart) on an iOS
simulator, one video per scene, into build/demo/<scene>.mp4.

    python3 tool/record_demo.py                       # every scene, iPhone 17 Pro
    python3 tool/record_demo.py --scene 03            # one scene
    python3 tool/record_demo.py --device <simulator udid>

Reseed the backend first (asah-be: npm run demo:reset): the scenes change data
and build on each other. config/development.json needs DEMO_OTP.
"""
import argparse
import os
import re
import signal
import subprocess
import sys

BUNDLE_ID = "com.jutaberlian.asah"
SEMINYAK = "-8.6913,115.1682"  # Dapur Berlian Seminyak, inside its geofence


def find_udid(name: str) -> str:
    """The booted simulator with this name, else the first available one."""
    out = subprocess.run(["xcrun", "simctl", "list", "devices", "available"], capture_output=True, text=True).stdout
    found = re.findall(r"^\s*(.+?) \(([0-9A-F-]{36})\) \((\w+)\)", out, re.M)
    matches = [(udid, state) for n, udid, state in found if n == name]
    if not matches:
        sys.exit(f"No available simulator named {name!r}")
    return next((u for u, st in matches if st == "Booted"), matches[0][0])


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--device", help="simulator UDID (default: the first available 'iPhone 17 Pro')")
    ap.add_argument("--scene", default="", help="only scenes starting with this, e.g. 03")
    ap.add_argument("--out", default="build/demo")
    args = ap.parse_args()

    udid = args.device or find_udid("iPhone 17 Pro")
    os.makedirs(args.out, exist_ok=True)
    subprocess.run(["xcrun", "simctl", "boot", udid], capture_output=True)
    subprocess.run(["open", "-a", "Simulator"])
    subprocess.run(["xcrun", "simctl", "bootstatus", udid, "-b"], capture_output=True)
    subprocess.run(["xcrun", "simctl", "location", udid, "set", SEMINYAK], check=True)
    subprocess.run(["xcrun", "simctl", "status_bar", udid, "override", "--time", "17:30",
                    "--batteryState", "charged", "--batteryLevel", "100", "--wifiBars", "3", "--cellularBars", "4"])

    cmd = ["flutter", "test", "integration_test/demo_test.dart", "-d", udid,
           "--dart-define-from-file=config/development.json"]
    if args.scene:
        cmd.append(f"--dart-define=DEMO_SCENE={args.scene}")
    print("$", " ".join(cmd), flush=True)
    proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, bufsize=1)
    rec = None
    recorded = []
    for line in proc.stdout:
        sys.stdout.write(line)
        sys.stdout.flush()
        if "DEMO_READY" in line:
            for service in ("location", "location-always"):
                subprocess.run(["xcrun", "simctl", "privacy", udid, "grant", service, BUNDLE_ID], capture_output=True)
        elif "DEMO_LOCATION" in line:  # a scene moves to another outlet
            where = line.split("DEMO_LOCATION", 1)[1].strip()
            subprocess.run(["xcrun", "simctl", "location", udid, "set", where], capture_output=True)
        elif "DEMO_REC_START" in line:
            name = line.split("DEMO_REC_START", 1)[1].strip()
            path = os.path.join(args.out, f"{name}.mp4")
            rec = subprocess.Popen(["xcrun", "simctl", "io", udid, "recordVideo", "--codec", "h264", "--force", path],
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            recorded.append(path)
        elif "DEMO_REC_STOP" in line and rec:
            rec.send_signal(signal.SIGINT)
            rec.wait(timeout=30)
            rec = None
    proc.wait()
    if rec:
        rec.send_signal(signal.SIGINT)
        rec.wait(timeout=30)
    subprocess.run(["xcrun", "simctl", "status_bar", udid, "clear"], capture_output=True)
    print("\nRecorded:" if recorded else "\nNothing recorded.")
    for p in recorded:
        print("  ", p)
    sys.exit(proc.returncode)


if __name__ == "__main__":
    main()
