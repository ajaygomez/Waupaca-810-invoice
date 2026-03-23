# Project Instructions

## CRITICAL: Never use Bash to create files or embed special characters

NEVER use printf, echo, cat heredoc, or any Bash command to create files or embed single quotes, double quotes, backslashes, or shell expansion syntax (`$HOME`, `$VAR`). Claude Code has multiple hardcoded security checks that flag these patterns and force the user to approve every time. This CANNOT be bypassed with permission settings.

**Blocked patterns (all trigger non-bypassable prompts):**
- `'\''` or `"'"` in arguments — "consecutive quote characters at word start"
- printf/echo with quotes or `\n` — "Shell expansion syntax in paths"
- `$HOME` or `$VAR` in file paths inside printf/echo — "Shell expansion syntax in paths"
- Backslash patterns in single-quoted strings — "single-quoted backslash pattern"

**Rule: ALWAYS use the Write tool to create files.** The Write tool bypasses all shell escaping issues.

Examples:
- To create a JSON payload file → Write tool creates `C:/Users/gomeza/tmp/query.json`, then `curl -d @C:/Users/gomeza/tmp/query.json`
- To create an SSH askpass script → Write tool creates `C:/Users/gomeza/tmp/ssh_askpass.sh`, then `chmod +x C:/Users/gomeza/tmp/ssh_askpass.sh`
- To create any script or config file → Write tool, never Bash

**If the curl payload has NO single quotes**, inline `-d '{"sql":"..."}'` is fine.

## CRITICAL: No compound Bash commands

NEVER chain multiple commands in a single Bash call using `&&`, `;`, `||`, or newlines. Each Bash call must contain exactly ONE command so it matches existing permission rules.

## CRITICAL: No data modification

NEVER run UPDATE, INSERT, or DELETE — not via SQL, inline programs, or any mechanism. If data needs changing, STOP and ask the user. Provide the exact SQL for them to run manually.
