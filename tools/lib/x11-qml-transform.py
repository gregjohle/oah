#!/usr/bin/env python3
"""Mechanical Wayland -> X11 rewrites for Omarchy's Quickshell QML.

These are the changes every upstream release needs in the same way, so they
are applied by script instead of by hand (see tools/oah-import-shell). Each
rewritten line keeps the original as a trailing `// OAH(x11): was ...`
comment, so the port stays reviewable and greppable.

On X11, Quickshell can't create the WlrLayershell attached object, and QML
then refuses to create the whole window ("Component is not ready"). The X11
PanelWindow has its own equivalents:

  WlrLayershell.layer: X          -> aboveWindows   (Top/Overlay above, Background/Bottom below)
  WlrLayershell.keyboardFocus: X  -> focusable      (anything but None takes focus)
  WlrLayershell.namespace: X      -> dropped        (no X11 equivalent)

Usage: x11-qml-transform.py FILE...   (rewrites files in place, prints a summary)
"""

import re
import sys

MARK = "// OAH(x11): was "

LINE = re.compile(r"^(?P<indent>\s*)WlrLayershell\.(?P<prop>layer|keyboardFocus|namespace):\s*(?P<expr>.*?)\s*$")

ABOVE = {"WlrLayer.Overlay": "true", "WlrLayer.Top": "true", "WlrLayer.Bottom": "false", "WlrLayer.Background": "false"}
FOCUS = {"WlrKeyboardFocus.None": "false", "WlrKeyboardFocus.Exclusive": "true", "WlrKeyboardFocus.OnDemand": "true"}


def rewrite(prop: str, expr: str) -> str | None:
    """The X11 replacement for one WlrLayershell property, or None to drop it."""
    if prop == "namespace":
        return None
    if prop == "layer":
        value = ABOVE.get(expr, f"({expr}) === WlrLayer.Top || ({expr}) === WlrLayer.Overlay")
        return f"aboveWindows: {value}"
    # keyboardFocus: loose != so a bool expression (`open`) maps the same way
    # as the enum (None == 0 == false).
    value = FOCUS.get(expr, f"({expr}) != WlrKeyboardFocus.None")
    return f"focusable: {value}"


def transform(text: str) -> tuple[str, int]:
    out, changed = [], 0
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\n")
        m = LINE.match(body)
        if not m or MARK in body:
            out.append(line)
            continue
        expr = m["expr"]
        # A trailing // comment isn't part of the expression.
        expr = re.sub(r"\s*//.*$", "", expr)
        original = f"WlrLayershell.{m['prop']}: {expr}"
        new = rewrite(m["prop"], expr)
        newline = "\n" if line.endswith("\n") else ""
        if new is None:
            out.append(f"{m['indent']}{MARK}{original}{newline}")
        else:
            out.append(f"{m['indent']}{new} {MARK}{original}{newline}")
        changed += 1
    return "".join(out), changed


def main(paths: list[str]) -> int:
    total = files = 0
    for path in paths:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        new, changed = transform(text)
        if changed:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new)
            total += changed
            files += 1
    leftover = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            for n, line in enumerate(f, 1):
                if "WlrLayershell." in line and MARK not in line:
                    leftover.append(f"{path}:{n}: {line.strip()}")
    print(f"x11-qml-transform: rewrote {total} line(s) in {files} file(s)")
    if leftover:
        print("x11-qml-transform: WlrLayershell uses the rules don't cover:", file=sys.stderr)
        print("\n".join(leftover), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
