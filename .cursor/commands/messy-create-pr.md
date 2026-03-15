# Create Ad-Hoc GitHub Pull Request Workflow (GitHub MCP)

## Prerequisites Check

1. **Verify all changes are committed**:
   - Run `git status --short` - should show no modified/untracked files (except temporary PR files)
   - If uncommitted changes exist, prompt user to commit first

2. **Get repository information**:
   - Run `git remote get-url origin` to get the remote URL
   - Extract owner and repo name from URL (e.g., `github-messyvirgo:messyvirgo-coin/messyvirgo-platform.git` → owner: `messyvirgo-coin`, repo: `messyvirgo-platform`)
   - Store these values for use with GitHub MCP tools

3. **Get current branch name**:
   - Run `git branch --show-current` to get the current branch name
   - Store for use in PR creation and issue extraction

4. **Verify branch is pushed to remote**:
   - Run `git log origin/main..HEAD --oneline` - should show commits
   - If no commits ahead, check if branch exists on remote: `git ls-remote --heads origin $(git branch --show-current)`
   - If not pushed, prompt user to push first
   - **Note**: GitHub MCP requires the branch to exist on the remote repository

## Extract Information from Branch Name

1. **Extract GitHub issue number** (if present):
   - Look for the first numeric sequence in the branch name (e.g., "123" from "123-feature-name", "issue-123-fix", "feature/123-add-endpoint")
   - Patterns to match: `^\d+`, `issue-(\d+)`, `(\d+)-`, `/(\d+)-`, etc.
   - Store the issue number if found (e.g., "123")
   - **Note**: The issue number refers to an issue in the current repository

2. **Extract description from branch name**:
   - Extract description for title context (optional, commit messages take precedence)
   - Remove issue numbers and prefixes to get clean description

## Analyze Commit History (via GitHub MCP)

**Prefer using GitHub MCP tools** for fetching commit data when possible, as it provides structured data and better integration.

1. **Get commits using GitHub MCP**:
   - Use `mcp_github_list_commits` with:
     - `owner`: Repository owner (from prerequisites)
     - `repo`: Repository name (from prerequisites)
     - `sha`: Current branch name (or HEAD commit SHA)
   - Parse commit messages from the response to understand changes
   - **Alternative**: If MCP fails or branch not found, fall back to `git log origin/main..HEAD --pretty=format:"%h|%s|%b"`

2. **Determine primary change type from commit messages**:
   - Look for conventional commit prefixes: `feat:`, `fix:`, `refactor:`, `chore:`, `docs:`, etc.
   - Use the most frequent prefix, or the first commit's prefix if all are different
   - If no prefix found, infer from commit message keywords (similar to branch name logic)

3. **Extract main description from commits**:
   - Use the first commit's subject line (strip prefix if present)
   - If multiple commits, synthesize a high-level description
   - Keep description concise (max 50-60 characters for title)

## Analyze Changed Files

1. Get list of changed files:
   - Run: `git diff --name-status origin/main...HEAD` to get changed files with status
   - Parse output to categorize: Added (A), Modified (M), Deleted (D), Renamed (R)
2. Summarize file changes:
   - Count total files changed
   - If ≤ 10 files: List all files with their status (e.g., "Modified: services/api/src/api/routes/tokens.py")
   - If > 10 files: Group by top-level directory/package and summarize:
     - Count files per directory (e.g., "services/api: 5 files, packages/messy-core: 3 files")
     - List key files only (e.g., routes, services, major components)
   - Identify affected areas: services, packages, infrastructure, config, docs, etc.
3. Use this information to inform PR description sections

## Resolve GitHub Issue (if issue number found)

**Note**: This step is optional and non-blocking. Only perform if GitHub issue number was found in branch name. The issue number refers to an issue in the current repository.

1. **Fetch GitHub issue details using MCP**:
   - Use `mcp_github_get_issue` with:
     - `owner`: Repository owner (from prerequisites)
     - `repo`: Repository name (from prerequisites)
     - `issue_number`: Extracted GitHub issue number (as integer)
   - If issue exists, extract:
     - Issue title (for context)
     - Issue body/description (for additional context)
     - Issue labels (to understand issue type)
     - Issue state (open/closed)
   - If issue not found, log warning but continue (issue number might be incorrect or issue deleted)

2. **Use issue information**:
   - If issue found and open, reference it in PR description
   - Include issue title in PR description context if relevant
   - **Note**: GitHub automatically links the PR to the issue when you use `Closes #123` or `Fixes #123` in the PR description (the PR will appear in the issue's "Linked pull requests" section)
   - GitHub does NOT automatically post a comment on the issue - see optional step after PR creation

## Create PR Title

Format: `{prefix}: {Description} (#{GitHub-Issue})` (GitHub issue number optional)

- Determine prefix from commit messages (preferred) or branch name:
  - Use `fix:` if commits contain keywords like "fix", "bug", "error", "issue", "repair", "resolve"
  - Use `feat:` for new features or enhancements
  - Use `refactor:` for code restructuring
  - Use `chore:` for maintenance tasks
  - Default to `feat:` if uncertain
- Use description from commit messages (synthesized if multiple commits)
- Include GitHub issue number in format `#123` if found
- Examples:
  - "feat: Add Token Search Endpoint (#123)"
  - "fix: Resolve Database Connection Pool Error (#456)"
  - "refactor: Simplify Provider Architecture"
  - "chore: Update Dependencies and Config"
- Keep title concise and descriptive (max 70 characters recommended)

## Create PR Description

1. **Load PR template using GitHub MCP** (preferred):
   - Use `mcp_github_get_file_contents` with:
     - `owner`: Repository owner
     - `repo`: Repository name
     - `path`: `.github/PULL_REQUEST_TEMPLATE.md`
     - `branch`: `main` (or current branch if template doesn't exist on main)
   - If template not found via MCP, fall back to reading local file `.github/PULL_REQUEST_TEMPLATE.md`
   - If template still not found, use the standard template structure

2. **Add GitHub issue reference** (if issue number found and issue exists):
   - At the top of the description, add: `Closes #123` or `Fixes #123` (GitHub will auto-close the issue when PR is merged)
   - Or use `Related to #123` if PR doesn't fully address the issue
   - Include issue title and brief context if helpful: `Related to #123: {issue title}`

3. **Fill in sections based on commit messages, changed files, and issue context**:

   **Context & Purpose:**
   - Synthesize from commit messages and GitHub issue (if found) - what is the main goal?
   - If GitHub issue was found, reference it: "Addresses #123: {issue title}"
   - Keep it brief and factual

   **Implementation & Design:**
   - Summarize key changes based on changed files
   - Mention any architectural changes if evident from file structure

   **Impact on MVP/Product Strategy:**
   - Brief statement if obvious from commits, otherwise can be minimal

   **How to Review/Test:**
   - Based on changed files: suggest what to test (e.g., "Test token search endpoint: POST /api/v1/tokens/search")
   - If tests were added/modified, mention running them

   **Key Decisions & Tradeoffs:**
   - Extract from commit message bodies if they contain design notes
   - Otherwise, can be minimal or omitted for small changes

   **Investor Notes:**
   - Only if relevant, otherwise omit

   **Checklist:**
   - Pre-fill based on changed files:
     - [ ] Code runs locally
     - [ ] Core business logic/feature covered (if applicable)
     - [ ] No major bugs found in manual smoke tests

4. **Add a "Changes Summary" section at the top** (after GitHub issue reference, before template sections):

   ```markdown
   ## Changes Summary
   - GitHub Issue: #{issue-number} (if found)
   - Commits: {count} commits
   - Files Changed: {count} files ({added} added, {modified} modified, {deleted} deleted)
   - Primary Change Type: {prefix} (e.g., feat, fix, refactor)
   - Affected Areas: {summary of directories/packages}
   ```

5. **Build the complete PR description** as a string (do not save to file yet)

## Run Tests and Verify All Pass

**Note**: This step is mandatory. PR creation will be blocked if tests fail.

1. **Run All Tests**:
   - From workspace root, run: `uv run pytest -v`
   - This auto-discovers and runs all test files (`test_*.py` and `*_test.py`) across the entire workspace
   - Verify exit code is 0 (all tests pass)
   - If tests fail, display error output and **block PR creation**
   - Prompt user to fix failing tests before proceeding

2. **Handle Test Failures**:
   - If tests fail, do NOT create the PR
   - Display clear error message: "Tests failed. Please fix failing tests before creating PR."
   - Show the test output to help user debug
   - Stop workflow execution
   - Do NOT proceed to PR creation step

3. **On Success**:
   - Display test summary (e.g., "All tests passed: 25 passed in 1.05s")
   - Continue to PR creation step

## Create Pull Request (via GitHub MCP)

**Prefer using GitHub MCP** for creating PRs as it provides better error handling and structured responses.

1. **Use `mcp_github_create_pull_request`** with the following parameters:
   - `owner`: Repository owner (from prerequisites)
   - `repo`: Repository name (from prerequisites)
   - `title`: Generated PR title (includes GitHub issue number if found)
   - `body`: Generated PR description (complete string, includes `Closes #123` if applicable)
   - `head`: Current branch name (from prerequisites)
   - `base`: `main` (target branch)
   - `draft`: `false` (unless user requests draft PR)

2. **Handle the response**:
   - The MCP tool will return PR details including PR number and URL
   - Display the PR URL to the user
   - GitHub will automatically:
     - Link the issue if `Closes #123` or `Fixes #123` is in the description (appears in issue's "Linked pull requests" section)
     - Close the issue when PR is merged (if `Closes` or `Fixes` keyword used)
   - **Note**: GitHub does NOT automatically post a comment on the issue when the PR is created

3. **Post comment on GitHub issue (optional)**:
   - **Note**: This step is optional and non-blocking. Only perform if GitHub issue number was found and PR was successfully created.
   - Use `mcp_github_add_issue_comment` with:
     - `owner`: Repository owner (from prerequisites)
     - `repo`: Repository name (from prerequisites)
     - `issue_number`: Extracted GitHub issue number (as integer)
     - `body`: Brief comment: `PR created: {PR Title}\n\nSee PR: {PR URL}\n\nThis PR addresses this issue.`
   - This helps notify issue subscribers that work has started
   - If posting fails, log warning but continue (non-blocking - GitHub already linked the PR automatically)

4. **Error handling**:
   - If PR creation fails (e.g., branch doesn't exist on remote, merge conflicts, etc.), display clear error message
   - Prompt user to resolve issues and retry
   - **Fallback**: If MCP fails, use GitHub CLI: `gh pr create --base main --title "{title}" --body "{body}"`

## Cleanup

- No temporary files need to be created or cleaned up (PR description is built in memory)
- If any temporary files were created during the process, delete them now

## Completion

- Answer: "done"
