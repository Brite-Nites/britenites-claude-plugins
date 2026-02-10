---
name: create-issues
description: >
  Creates Linear issues from a refined project plan. Validates issues
  were created correctly with sufficient context for agent execution.
  Use after /refine-plan.
allowed-tools:
  - mcp__sequential-thinking__sequentialthinking
  - mcp__linear__*
  - Read
  - Write
  - Glob
  - Grep
agent: issue-creator
context: fork
---

## Instructions

You are creating Linear issues from a refined project plan.

### Input
- The refined plan file path is passed as $ARGUMENTS
- If no argument provided, look for `docs/project-plan-refined.md`

### Process
1. **Read the refined plan** and parse all tasks

2. **For each task, create a Linear issue** with:
   - **Title**: From the task title
   - **Description**: Combine the Context, Steps, and Validation
     sections into a well-structured issue body. Format it so that
     an AI agent receiving this issue has everything it needs:
     - "## Context" — background and architectural decisions
     - "## Implementation Steps" — the numbered steps
     - "## Validation Criteria" — how to verify completion
     - "## Dependencies" — links to dependent issues (add after
       all issues are created)
   - **Labels**: Add complexity label (S/M/L)
   - **Priority**: Derive from dependency order (earlier = higher)

3. **After all issues are created**:
   - Go back and update dependency references to use actual Linear
     issue IDs/links
   - Set parent/sub-issue relationships where appropriate

4. **Update the refined plan file**:
   - Add the Linear issue ID next to each task title
   - Add a "Linear Project" link at the top of the document

### Output
- Linear issues created and linked
- Updated `docs/project-plan-refined.md` with issue IDs
- Write a summary to `docs/linear-issues-created.md` containing:
  - Total issues created
  - Issue ID → Task title mapping
  - Any issues that needed special handling

### Validation Criteria
Read `.claude/skills/_shared/validation-pattern.md` and apply it.
Specific criteria for this skill:
- [ ] Every task in the refined plan has a corresponding Linear issue
- [ ] Each issue's description contains Context, Implementation Steps,
      and Validation Criteria sections
- [ ] Read each issue back from Linear via MCP and verify the content
      matches what was intended
- [ ] Dependencies are correctly linked between issues
- [ ] An agent picking up any single issue would have enough context
      to: understand the task, complete the work, and validate the result
- [ ] The refined plan file has been updated with issue IDs
