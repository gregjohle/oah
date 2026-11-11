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
  Hyprland.<api>                  -> Compositor.<api> (shell/Oah/Compositor.qml, bspwm-backed)

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


# A property value continues onto the next line when the current text ends
# mid-expression or the next line starts with an operator.
CONTINUES_AFTER = ("?", ":", "&&", "||", "+", "-", "*", "/", "(", ",", "!", "=")
CONTINUES_BEFORE = ("?", ":", "&&", "||", "+", "-", "*", "/", ")", ".")


# Hyprland's IPC singleton -> OAH's bspwm-backed stand-in (shell/Oah/Compositor.qml),
# which offers the same workspaces/monitors/toplevels API.
HYPRLAND_REF = re.compile(r"(?<![\w.])Hyprland\.")
HYPRLAND_TARGET = re.compile(r"(?<![\w.])target:\s*Hyprland\b")
HYPRLAND_IMPORT = re.compile(r"^(?P<indent>\s*)import Quickshell\.Hyprland\s*$")
COMPOSITOR_IMPORT = "import qs.Oah"


def code_lines(text: str):
    return (l for l in text.splitlines() if not l.lstrip().startswith("//"))


def transform_hyprland(text: str) -> tuple[str, int]:
    def uses(l):
        return HYPRLAND_REF.search(l) or HYPRLAND_TARGET.search(l)
    if not any(uses(l) for l in code_lines(text)):
        return text, 0
    out, changed, imported = [], 0, COMPOSITOR_IMPORT in text
    for line in text.splitlines(keepends=True):
        body = line.rstrip("\n")
        newline = "\n" if line.endswith("\n") else ""
        im = HYPRLAND_IMPORT.match(body)
        if im and not imported:
            out.append(line)
            out.append(f"{im['indent']}{COMPOSITOR_IMPORT} {MARK}Hyprland IPC, now bspwm-backed{newline}")
            imported = True
            continue
        if body.lstrip().startswith("//") or MARK in body or not uses(body):
            out.append(line)
            continue
        new = HYPRLAND_TARGET.sub("target: Compositor", HYPRLAND_REF.sub("Compositor.", body))
        out.append(f"{new} {MARK}Hyprland{newline}")
        changed += 1
    if not imported:
        raise ValueError("uses Hyprland without importing Quickshell.Hyprland")
    return "".join(out), changed


def strip_comment(code: str) -> str:
    return re.sub(r"\s*//.*$", "", code)


def transform(text: str) -> tuple[str, int]:
    text, changed = transform_hyprland(text)
    lines = text.splitlines(keepends=True)
    out, i = [], 0
    while i < len(lines):
        line = lines[i]
        body = line.rstrip("\n")
        m = LINE.match(body)
        if not m or MARK in body:
            out.append(line)
            i += 1
            continue

        # Gather a multi-line expression (e.g. a ternary spread over lines)
        # so the whole value is rewritten, not just its first line.
        parts = [strip_comment(m["expr"]).strip()]
        j = i + 1
        while j < len(lines):
            nxt = strip_comment(lines[j].strip())
            depth = sum(p.count("(") - p.count(")") for p in parts)
            if depth > 0 or parts[-1].endswith(CONTINUES_AFTER) or nxt.startswith(CONTINUES_BEFORE):
                parts.append(nxt)
                j += 1
                continue
            break
        expr = " ".join(p for p in parts if p)
        if sum(expr.count(c) for c in "(") != sum(expr.count(c) for c in ")"):
            raise ValueError(f"line {i + 1}: can't find the end of WlrLayershell.{m['prop']}'s expression")

        original = f"WlrLayershell.{m['prop']}: {expr}"
        new = rewrite(m["prop"], expr)
        last = lines[j - 1]
        newline = "\n" if last.endswith("\n") else ""
        if new is None:
            out.append(f"{m['indent']}{MARK}{original}{newline}")
        else:
            out.append(f"{m['indent']}{new} {MARK}{original}{newline}")
        changed += 1
        i = j
    return "".join(out), changed


def main(paths: list[str]) -> int:
    # Transform everything in memory first, so a file the rules can't handle
    # leaves the whole tree untouched rather than half rewritten.
    results = []
    for path in paths:
        with open(path, encoding="utf-8") as f:
            text = f.read()
        try:
            new, changed = transform(text)
        except ValueError as e:
            print(f"x11-qml-transform: {path}: {e}", file=sys.stderr)
            return 1
        if changed:
            results.append((path, new, changed))
    total = files = 0
    for path, new, changed in results:
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
