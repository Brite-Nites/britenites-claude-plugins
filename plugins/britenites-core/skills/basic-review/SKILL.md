---
name: basic-review
description: Perform a simple code review checking for common issues, code quality, and best practices. Use when reviewing code changes or pull requests.
allowed-tools: Read, Grep, Glob
---

# Basic Code Review

## Instructions

When reviewing code, check for:

1. **Code Quality**
   - Clear variable and function names
   - Appropriate comments for complex logic
   - Consistent formatting and style

2. **Common Issues**
   - Unhandled error cases
   - Missing input validation
   - Potential null/undefined references

3. **Best Practices**
   - DRY (Don't Repeat Yourself) principle
   - Single responsibility functions
   - Appropriate use of abstractions

## Review Output Format

Provide feedback in this structure:
- **Summary**: Brief overview of the code
- **Issues Found**: List any problems with severity (high/medium/low)
- **Suggestions**: Recommendations for improvement
- **Positive Notes**: What the code does well
