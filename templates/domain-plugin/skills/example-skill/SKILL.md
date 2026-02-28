---
name: example-skill
description: Example skill — replace with your own trigger conditions
user-invocable: false
---

# Example Skill

This is a placeholder skill. Replace this directory and SKILL.md with your own skills.

## When this activates

Skills auto-activate based on the `description` field in the frontmatter. Write a description that captures the trigger conditions (e.g., "Use when writing FastAPI endpoints or configuring async Python code").

## What to do next

1. Create a new directory under `skills/` with your skill name (e.g., `skills/my-skill/`)
2. Add a `SKILL.md` with proper frontmatter — `name` must match the directory name
3. Set `user-invocable: true` if users should be able to invoke it directly
4. Delete this `example-skill/` directory when you're done

## Conventions

- `name` must match the directory name exactly
- `description` must be a plain YAML string (no quotes, no `>` folded blocks)
- `user-invocable` must always be explicit `true` or `false`
