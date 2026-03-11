---
description: RFP Go/No-Go qualification — walk through disqualifiers, score strategic fit, and decide whether to pursue
---

# RFP Go/No-Go Qualification Scorecard

You are facilitating an interactive RFP qualification workflow based on the Brite Nites Go/No-Go Qualification Scorecard. Walk the user through each step conversationally, collect their answers, calculate scores, and produce a final decision with next actions.

## Step 0: Gather RFP Metadata

Collect the following information. If `$ARGUMENTS` is provided, treat it as the RFP project name. For any missing fields, ask the user via AskUserQuestion.

Required fields:
- **RFP Project Name** — from `$ARGUMENTS` or ask
- **Issuing Entity** — who issued the RFP
- **Submission Deadline** — when is it due
- **Evaluated By** — who is filling this out (default to the user)

Record the current date as the **Date Evaluated**.

Present a brief summary of the metadata before proceeding:

```
## RFP Qualification: [Project Name]
- Issuing Entity: [Entity]
- Deadline: [Date]
- Evaluated By: [Name]
- Date: [Today]
```

Ask: "Ready to begin the qualification? We'll start with automatic disqualifiers."

## Step 1: Automatic Disqualifiers

Present all 5 disqualifier questions and explain that ANY "Yes" answer is an immediate No-Go.

Ask the user to answer each question YES or NO. You may present them all at once or in groups — adapt to the user's preference.

### Disqualifier Questions

| # | Question |
|---|----------|
| 1 | Is this a labor-only bid where the client provides all equipment and materials? |
| 2 | Is this a small-scope, vendor-provided-equipment engagement where Brite Nites would not supply its own product? |
| 3 | Does the submission deadline fall within less than 7 calendar days with no prior notice or site intel? |
| 4 | Does the project require services entirely outside Brite Nites capabilities (e.g., electrical engineering licensure, general contracting)? |
| 5 | Does the RFP explicitly prohibit the vendor from supplying their own lighting product? |

### Evaluation

- If ALL answers are NO — say "All disqualifiers cleared. Proceeding to Strategic Fit Scorecard." and continue to Step 2.
- If ANY answer is YES — immediately declare **No-Go**. Ask the user to provide a brief reason for documentation, then skip to the Final Output section with the No-Go result. Do NOT proceed to Step 2.

## Step 2: Strategic Fit Scorecard

Walk the user through each of the 8 criteria below. For each criterion:
1. Present the criterion name, description, and weight
2. Remind them of the scoring scale (1 = Poor fit, 2 = Below average, 3 = Acceptable, 4 = Good fit, 5 = Excellent fit)
3. Ask for their score (1-5)
4. Calculate the weighted score (score x weight)

You may present criteria one at a time or in logical groups of 2-3 — adapt to the user's pace.

### Criteria

| # | Criterion | Description | Weight |
|---|-----------|-------------|--------|
| 1 | PRODUCT ALIGNMENT | Does the RFP require us to sell and install lights, structures, architectural lighting, or experiential lighting? | 3x |
| 2 | PROJECT SCALE | Is the estimated project value within our target range ($10K-$500K+)? | 2x |
| 3 | GEOGRAPHIC FEASIBILITY | Can we service the location effectively (local crew, travel logistics, site access)? | 2x |
| 4 | TIMELINE FEASIBILITY | Is there adequate time to deliver a premium proposal within 14 days? | 2x |
| 5 | COMPETITIVE POSITIONING | Do we have a realistic advantage (relationship, past work, design capability)? | 1.5x |
| 6 | RELATIONSHIP AND REPEAT POTENTIAL | Does winning lead to ongoing or multi-year revenue? | 1.5x |
| 7 | DESIGN COMPLEXITY | Does the project showcase our creative design and custom fabrication? | 1x |
| 8 | CLIENT PROFILE | Is this a client type aligned with our brand (municipalities, premium commercial, hospitality, retail centers)? | 1x |

### Score Calculation

After collecting all 8 scores, calculate and present:

```
## Strategic Fit Scorecard Results

| # | Criterion                        | Weight | Score | Weighted |
|---|----------------------------------|--------|-------|----------|
| 1 | Product Alignment                | 3x     | [S]   | [W]      |
| 2 | Project Scale                    | 2x     | [S]   | [W]      |
| 3 | Geographic Feasibility           | 2x     | [S]   | [W]      |
| 4 | Timeline Feasibility             | 2x     | [S]   | [W]      |
| 5 | Competitive Positioning          | 1.5x   | [S]   | [W]      |
| 6 | Relationship & Repeat Potential  | 1.5x   | [S]   | [W]      |
| 7 | Design Complexity                | 1x     | [S]   | [W]      |
| 8 | Client Profile                   | 1x     | [S]   | [W]      |
|---|----------------------------------|--------|-------|----------|
|   | **TOTAL**                        |        |       | **[T] / 70** |
```

The maximum possible score is 70 (all 5s: 5×3 + 5×2 + 5×2 + 5×2 + 5×1.5 + 5×1.5 + 5×1 + 5×1 = 15+10+10+10+7.5+7.5+5+5 = 70).

## Step 3: Decision

Based on the total weighted score, present the decision:

| Score Range | Decision | Action |
|---|---|---|
| 55-70 | **STRONG GO** | Pursue immediately. Trigger all Phase 2 parallel actions same day. |
| 40-54 | **CONDITIONAL GO** | Brief team huddle required. Document what makes it viable before committing resources. |
| Below 40 | **NO-GO** | Document reason and archive. Log in HubSpot. |

Present the decision clearly:

```
## Decision: [STRONG GO / CONDITIONAL GO / NO-GO]
Score: [Total] / 70
```

Then:
- Ask the user for **Notes / Rationale** — any context for why this score landed where it did
- If **Conditional Go**: Ask "What must be true for this to work?" and capture the conditions
- If **No-Go**: Document the reason and skip to Final Output

For Go decisions (Strong Go or Conditional Go), proceed to Step 4.

## Step 4: Parallel Launch Confirmation (Go Decisions Only)

Present the 5 required launch actions. Ask the user to confirm each one has been triggered (or note if it needs to be done later).

### Launch Actions

| # | Action | Status |
|---|--------|--------|
| 1 | Sarah notified in HubSpot to begin deck | [ ] Triggered / [ ] Pending |
| 2 | Olivia notified with extraction summary for legal review | [ ] Triggered / [ ] Pending |
| 3 | Pre-bid meeting date confirmed and attendance assigned | [ ] Triggered / [ ] Pending |
| 4 | Sales rep began proactive outreach to contact person | [ ] Triggered / [ ] Pending |
| 5 | HubSpot deal record created/updated | [ ] Triggered / [ ] Pending |

Ask the user to confirm each action. Record the status of each.

## Final Output

Generate a complete scorecard summary. This is the deliverable — format it clearly so it can be saved or shared.

```
# RFP Go/No-Go Qualification Scorecard
## [Project Name]

**Issuing Entity:** [Entity]
**Submission Deadline:** [Deadline]
**Date Evaluated:** [Date]
**Evaluated By:** [Name]

---

### Step 1: Automatic Disqualifiers
[Result: All Clear / No-Go triggered by Q#]
[If No-Go: Reason documented]

### Step 2: Strategic Fit Scorecard
[Full scoring table from Step 2]
**Total: [Score] / 70**

### Step 3: Decision
**[STRONG GO / CONDITIONAL GO / NO-GO]**
Notes: [User's rationale]
[If Conditional: Conditions — what must be true]

### Step 4: Parallel Launch
[If applicable: Status of each action item]
[If No-Go: N/A]

---
Signed: [Evaluated By] | Date: [Date Evaluated]
```

## Rules

- Be conversational but efficient — this is a decision tool, not a lecture.
- Never skip a disqualifier or criterion. Every field must be answered.
- Do the math correctly. Double-check the weighted score calculation before presenting.
- If a user gives an ambiguous answer to a disqualifier, clarify — it must be a definitive YES or NO.
- If a score is outside 1-5, ask again.
- Present the final scorecard summary even for No-Go results — document why.
- Do not proceed past Step 1 if any disqualifier is YES.
- For Conditional Go, the conditions captured are critical — push the user to be specific.
