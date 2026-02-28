## Validation & Retry Pattern

After completing your primary task, you MUST validate your own work:

1. **Check**: Verify the output meets all acceptance criteria defined in the skill
2. **Evaluate**: For each criterion, explicitly state PASS or FAIL with reasoning
3. **If any FAIL**:
   a. Use the sequential-thinking MCP to analyze what went wrong
   b. Identify the root cause and formulate a revised approach
   c. Re-execute only the failed portions
   d. Re-validate from step 1
4. **Max retries**: 3 attempts. If still failing after 3 retries, write a summary of what's failing and why to the output file and flag it for human review
5. **If all PASS**: Confirm completion and summarize what was produced
