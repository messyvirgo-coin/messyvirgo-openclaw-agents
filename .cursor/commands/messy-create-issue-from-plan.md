# Create GitHub Issue From Plan

Create a GitHub issue in the **current repository** using the active plan context (for example an open `.cursor/plans/*.plan.md` file).

## Goal

Generate a clear implementation issue with:

- A concise, actionable **title**
- An inferred **issue type**: `Feature`, `Bug`, or `Task`
- Automatic assignment to the **current authenticated user**
- Description aligned with the repository feature template fields:
  - `## Problem / motivation`
  - `## User story`
  - `## Acceptance criteria`
  - `## Alternatives considered`

The issue must make it obvious what will be implemented from the plan.

## Preconditions

1. Determine repository owner/name from current git remote.
2. Identify the plan source from context:
   - Prefer currently open/selected plan file
   - Otherwise use the most recent `.cursor/plans/*.plan.md`
3. Resolve current GitHub username (the authenticated user) for assignment.
4. If no plan is available or the plan content is too ambiguous to derive the required sections, stop and ask for clarification.

## Workflow

### 1) Read and summarize the plan

- Extract:
  - Problem statement / goal
  - Intended user impact
  - Main implementation scope
  - Key constraints or risks

### 2) Draft the issue title

- Keep it short and outcome-focused.
- Prefer formats like:
  - `Use canonical variant_id links for lens results and sharing`
  - `Implement <primary outcome> from plan`

### 2.1) Infer issue type from plan intent

- Classify as:
  - `Bug`: fixes incorrect behavior, regressions, broken flows, data mismatches, error conditions.
  - `Feature`: introduces new capability or significant new behavior.
  - `Task`: maintenance/refactor/chore/process/documentation work without a net-new user capability.
- If multiple apply, choose the dominant implementation intent from the plan goal and acceptance criteria.

### 3) Draft the issue body with required chapters

Use exactly this structure:

```markdown
## Problem / motivation
<What problem are we solving, and why now?>

## User story
As a <user/persona>, I want <capability>, so that <outcome/value>.

## Acceptance criteria
- [ ] <Criterion 1: observable behavior>
- [ ] <Criterion 2: observable behavior>
- [ ] <Criterion 3: observable behavior>

## Alternatives considered
<Optional alternatives considered, or "None">
```

Rules:

- Keep acceptance criteria simple, testable, and implementation-oriented.
- Include only criteria directly implied by the plan.
- If no meaningful alternative exists, set `Alternatives considered` to `None`.
- Do not add extra sections.

### 4) Create the GitHub issue in current repo

Preferred method (GitHub MCP):

- Use `mcp_github_create_issue` with:
  - `owner`
  - `repo`
  - `title`
  - `body`
  - `assignees` set to current authenticated username
  - `labels` set to one of: `Feature`, `Bug`, `Task` (from inferred issue type)

Fallback method (if MCP is unavailable):

- Use GitHub CLI:
  - `gh issue create --title "<title>" --body "<body>" --assignee @me --label "<IssueType>"`

If the label does not exist:

- Create the issue without label and prepend title with `[Feature]`, `[Bug]`, or `[Task]`.

### 5) Completion output

- Return:
  - Created issue number
  - Issue URL
  - Final title
  - Inferred issue type
  - Assignee username

## Quality Bar

- The `Problem / motivation` section states why the work matters.
- The `User story` captures the plan's intended user-facing value.
- `Acceptance criteria` clearly define done and are easy to verify.
- The issue must be understandable without opening the plan file.
- The issue must be assigned to the current authenticated user.
