#!/usr/bin/env python3
import sys
import json
import subprocess
import os

def main():
    try:
        input_data = json.load(sys.stdin)
    except Exception:
        # Fail open if payload is unreadable
        print(json.dumps({"decision": "allow"}))
        return

    tool_call = input_data.get("toolCall", {})
    name = tool_call.get("name", "")
    args = tool_call.get("args", {})
    cmd = args.get("CommandLine", "")

    # Only gate on git commit commands
    if name == "run_command" and "git commit" in cmd:
        script_dir = os.path.dirname(os.path.abspath(__file__))
        review_script = os.path.join(script_dir, "pre-commit-review.sh")

        if os.path.exists(review_script):
            res = subprocess.run([review_script], capture_output=True, text=True)
            if res.returncode != 0:
                print(json.dumps({
                    "decision": "deny",
                    "reason": f"❌ [Swift Auditor] Pre-commit quality & security check failed:\n{res.stdout}\n{res.stderr}"
                }))
                return

    print(json.dumps({"decision": "allow"}))

if __name__ == "__main__":
    main()
