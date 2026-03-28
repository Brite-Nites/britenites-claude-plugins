#!/usr/bin/env python3
"""Parse a rubric markdown file's YAML frontmatter into JSON.

Usage:
    python3 parse_rubric.py <rubric-file>           # full JSON output
    python3 parse_rubric.py <rubric-file> --body     # print markdown body only
    python3 parse_rubric.py <rubric-file> --meta     # print frontmatter JSON only

Output (default): {"skill": "...", "pass_threshold": 3.0, "dimensions": [...], "body": "..."}
"""
import sys
import json
import re


def try_parse_value(val):
    """Try to parse a YAML scalar as a Python type."""
    val = val.strip().strip('"').strip("'")
    if val.lower() in ('true', 'yes'):
        return True
    if val.lower() in ('false', 'no'):
        return False
    try:
        return int(val)
    except ValueError:
        pass
    try:
        return float(val)
    except ValueError:
        pass
    return val


def parse_rubric(filepath):
    """Parse a rubric file with YAML frontmatter and markdown body."""
    with open(filepath, 'r') as f:
        content = f.read()

    parts = content.split('---', 2)
    if len(parts) < 3:
        print(json.dumps({"error": "Invalid frontmatter: missing --- delimiters"}),
              file=sys.stderr)
        sys.exit(1)

    yaml_text = parts[1].strip()
    body = parts[2].strip()

    result = {"dimensions": []}
    current_dim = None

    for line in yaml_text.split('\n'):
        line = line.rstrip()
        if not line or line.startswith('#'):
            continue

        # Top-level scalar: "key: value"
        m = re.match(r'^([a-zA-Z_][\w_-]*)\s*:\s*(.+)$', line)
        if m:
            key, val = m.group(1), m.group(2)
            if key == 'dimensions':
                # dimensions header — children follow as list items
                continue
            result[key] = try_parse_value(val)
            current_dim = None
            continue

        # Top-level key with no value (e.g., "dimensions:")
        m = re.match(r'^([a-zA-Z_][\w_-]*)\s*:\s*$', line)
        if m:
            current_dim = None
            continue

        # List item start: "  - name: value"
        m = re.match(r'^\s+-\s+([a-zA-Z_]\w*)\s*:\s*(.+)$', line)
        if m:
            current_dim = {m.group(1): try_parse_value(m.group(2))}
            result["dimensions"].append(current_dim)
            continue

        # Continuation of list item: "    key: value"
        m = re.match(r'^\s+([a-zA-Z_]\w*)\s*:\s*(.+)$', line)
        if m and current_dim is not None:
            current_dim[m.group(1)] = try_parse_value(m.group(2))
            continue

    result["body"] = body
    return result


def main():
    if len(sys.argv) < 2:
        print("Usage: python3 parse_rubric.py <rubric-file> [--body|--meta]",
              file=sys.stderr)
        sys.exit(2)

    filepath = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "--all"

    parsed = parse_rubric(filepath)

    if mode == "--body":
        print(parsed["body"])
    elif mode == "--meta":
        meta = {k: v for k, v in parsed.items() if k != "body"}
        print(json.dumps(meta))
    else:
        print(json.dumps(parsed))


if __name__ == "__main__":
    main()
