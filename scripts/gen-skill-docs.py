#!/usr/bin/env python3
"""Generate SKILL.md files from .tmpl templates with shared block resolution.

Usage:
    python3 scripts/gen-skill-docs.py              # Generate all
    python3 scripts/gen-skill-docs.py --check       # Dry-run: exit 1 if any file differs
    python3 scripts/gen-skill-docs.py --skill NAME  # Process single skill
"""
import argparse
import glob
import os
import re
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BLOCKS_DIR = os.path.join(REPO_ROOT, "scripts", "blocks")
AUTO_HEADER = "<!-- AUTO-GENERATED from SKILL.md.tmpl \u2014 do not edit directly -->"

# Colors (if terminal)
_isatty = sys.stdout.isatty()
GREEN = "\033[32m" if _isatty else ""
RED = "\033[31m" if _isatty else ""
BOLD = "\033[1m" if _isatty else ""
RESET = "\033[0m" if _isatty else ""


def load_blocks():
    """Load all block files from scripts/blocks/ into a dict keyed by uppercase name."""
    blocks = {}
    if not os.path.isdir(BLOCKS_DIR):
        return blocks
    for path in glob.glob(os.path.join(BLOCKS_DIR, "*.md")):
        name = os.path.splitext(os.path.basename(path))[0]
        key = name.upper().replace("-", "_")
        with open(path, "r") as f:
            blocks[key] = f.read()
    return blocks


def discover_templates(skill_filter=None):
    """Find all SKILL.md.tmpl files. Returns list of (skill_name, tmpl_path, output_path)."""
    pattern = os.path.join(REPO_ROOT, "plugins", "*", "skills", "*", "SKILL.md.tmpl")
    results = []
    for tmpl_path in sorted(glob.glob(pattern)):
        skill_dir = os.path.dirname(tmpl_path)
        skill_name = os.path.basename(skill_dir)
        if skill_filter and skill_name != skill_filter:
            continue
        output_path = os.path.join(skill_dir, "SKILL.md")
        results.append((skill_name, tmpl_path, output_path))
    return results


def split_frontmatter(content):
    """Split content into (frontmatter_with_delimiters, body).

    Frontmatter is the raw text between the first --- and second ---.
    Returns the frontmatter INCLUDING the --- delimiters, and the body after.
    """
    lines = content.split("\n")
    if not lines or lines[0].strip() != "---":
        return "", content

    end_idx = None
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            end_idx = i
            break

    if end_idx is None:
        return "", content

    # Include both --- delimiters
    fm_lines = lines[: end_idx + 1]
    body_lines = lines[end_idx + 1 :]
    return "\n".join(fm_lines), "\n".join(body_lines)


def parse_placeholder(match_str):
    """Parse a placeholder like 'BLOCK_NAME key1="val1" key2="val2"'.

    Returns (block_name, {key: value}).
    """
    parts = match_str.strip()
    # Extract block name (first word)
    name_match = re.match(r"([A-Z][A-Z0-9_]*)", parts)
    if not name_match:
        return None, {}
    block_name = name_match.group(1)
    rest = parts[name_match.end() :]

    # Extract key="value" pairs (supports escaped quotes: \")
    params = {}
    for m in re.finditer(r'(\w+)="((?:[^"\\]|\\.)*)"', rest):
        params[m.group(1).upper()] = m.group(2).replace('\\"', '"')

    return block_name, params


def resolve_block(block_content, params):
    """Apply %PARAM% substitutions to block content."""
    result = block_content
    for key, value in params.items():
        result = result.replace(f"%{key}%", value)
    return result


def resolve_placeholders(body, blocks, tmpl_path):
    """Find and resolve all {{BLOCK ...}} placeholders in the body.

    Returns (resolved_body, errors).
    """
    errors = []
    placeholder_re = re.compile(r"\{\{([A-Z][A-Z0-9_]*(?:\s+\w+=\"(?:[^\"\\]|\\.)*\")*)\}\}")

    def replacer(match):
        block_name, params = parse_placeholder(match.group(1))
        if block_name is None:
            errors.append(f"  {tmpl_path}: invalid placeholder syntax: {match.group(0)}")
            return match.group(0)
        if block_name not in blocks:
            errors.append(f"  {tmpl_path}: unknown block '{block_name}' in {match.group(0)}")
            return match.group(0)
        resolved = resolve_block(blocks[block_name], params)
        # Strip trailing newline from block to avoid double-newline
        return resolved.rstrip("\n")

    resolved = placeholder_re.sub(replacer, body)
    return resolved, errors


def generate(tmpl_path, blocks):
    """Generate SKILL.md content from a template. Returns (content, errors)."""
    with open(tmpl_path, "r") as f:
        raw = f.read()

    frontmatter, body = split_frontmatter(raw)

    resolved_body, errors = resolve_placeholders(body, blocks, tmpl_path)
    if errors:
        return None, errors

    # Check for unresolved placeholders (strict mode)
    leftover = re.findall(r"\{\{([A-Z][A-Z0-9_]*[^}]*)\}\}", resolved_body)
    for lo in leftover:
        errors.append(f"  {tmpl_path}: unresolved placeholder: {{{{{lo}}}}}")
    if errors:
        return None, errors

    # Build output: frontmatter + auto-header + body
    # The extra "\n" preserves the blank line after frontmatter that grep -v won't break
    output = frontmatter + "\n" + AUTO_HEADER + "\n" + resolved_body

    return output, []


def main():
    parser = argparse.ArgumentParser(description="Generate SKILL.md from .tmpl templates")
    parser.add_argument("--check", action="store_true", help="Dry-run: exit 1 if output differs")
    parser.add_argument("--skill", type=str, help="Process a single skill by name")
    args = parser.parse_args()

    blocks = load_blocks()
    templates = discover_templates(args.skill)

    if not templates:
        print(f"gen-skill-docs: 0 templates found")
        return 0

    all_errors = []
    stats = []
    stale_count = 0

    for skill_name, tmpl_path, output_path in templates:
        content, errors = generate(tmpl_path, blocks)
        if errors:
            all_errors.extend(errors)
            continue

        line_count = content.count("\n")
        est_tokens = line_count * 4
        stats.append((skill_name, line_count, est_tokens))

        if args.check:
            # Compare with existing file
            if os.path.exists(output_path):
                with open(output_path, "r") as f:
                    existing = f.read()
                if existing != content:
                    stale_count += 1
                    print(f"  {RED}STALE{RESET}  {skill_name}/SKILL.md (differs from template)")
                else:
                    print(f"  {GREEN}FRESH{RESET}  {skill_name}/SKILL.md")
            else:
                stale_count += 1
                print(f"  {RED}STALE{RESET}  {skill_name}/SKILL.md (file missing)")
        else:
            # Write output
            with open(output_path, "w") as f:
                f.write(content)
            rel_path = os.path.relpath(output_path, REPO_ROOT)
            print(f"  {GREEN}WROTE{RESET}  {rel_path}")

    # Print errors
    if all_errors:
        print(f"\n{RED}Errors:{RESET}")
        for err in all_errors:
            print(err)
        return 1

    # Print token budget report
    if stats:
        print(f"\n{BOLD}Token Budget Report{RESET}")
        print(f"  {'Skill':<40} {'Lines':>6} {'Est. Tokens':>12}")
        print(f"  {'-'*40} {'-'*6} {'-'*12}")
        total_lines = 0
        total_tokens = 0
        for name, lines, tokens in stats:
            print(f"  {name:<40} {lines:>6} {tokens:>12}")
            total_lines += lines
            total_tokens += tokens
        print(f"  {'-'*40} {'-'*6} {'-'*12}")
        print(f"  {'TOTAL':<40} {total_lines:>6} {total_tokens:>12}")

    if args.check and stale_count > 0:
        print(f"\n{RED}{stale_count} stale file(s). Run: bash scripts/gen-skill-docs.sh{RESET}")
        return 1

    action = "checked" if args.check else "generated"
    print(f"\ngen-skill-docs: {len(stats)} templates {action} successfully")
    return 0


if __name__ == "__main__":
    sys.exit(main())
