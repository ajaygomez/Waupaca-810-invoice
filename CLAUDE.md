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

## 810 Invoice Testing

### Reference Programs
- **Mailbox data programs (EDI027 etc.):** `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/qrpglesrc-readonly/` — Analyze these to understand how mailbox data is created.
- **Fixed file program (EDI810):** `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/qrpglesrc/edi810.sqlrpgle` — This creates the fixed-format output file.

### Test Execution
Run `/ibmi-compile run batch` using the following parameters:
- **Program:** `INV810TST` (or `INVDRIVER` with X12 parm)
- **Library:** `EDITEST`
- **Packing slip:** `223655`
- **Customer:** `01564`
- **Invoice number:** `00000000` to derive from `IVH021` (real: `22365501`), or any 8-digit value to override the tracking/filename
- **X12 parm (for INVDRIVER only):** `00`

### Verifying Output
After the program runs, it generates output in the IFS. To find the IFS output file path:
1. Query using the SQL in `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/database/ediinvoic810.sql`
2. Filter by the packing slip number (`223655`)
3. Get the latest record for that packing slip — it contains the IFS file path

Note: passing `00000000` for invoice number triggers derive-from-`IVH021` in `INVOICE`/`EDI810`. Passing a specific value stores that value in `EDIINVOIC810` and the IFS filename, but the EDI content (`BIG02` / `BGM02`) always reflects the real `IVH021` regardless. See `decisions/2026-04-20-invoice-number-source-of-truth.md`.

## EDIFACT INVOIC Testing

### Reference Programs
- **Mailbox data programs (EDI031, EDI041):** `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/qrpglesrc-readonly/` — Analyze these to understand how mailbox data is created for EDIFACT INVOIC.
- **Fixed file program (INVOICE):** `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/qrpglesrc/invoice.sqlrpgle` — This creates the fixed-format output file.

### Acceptance Criteria
1. The program **compiles** successfully (`/ibmi-compile`).
2. The program **runs** successfully via batch test.
3. **Verify the output** — check the IFS file contents to confirm proper data is produced.

### Test Execution
Run `/ibmi-compile run batch` using the following parameters:
- **Program:** `INVTEST` (or `INVDRIVER` with EDIFACT parm)
- **Library:** `EDITEST`
- **Packing slip:** `223301`
- **Customer:** `01681`
- **Invoice number:** `00000000` to derive from `IVH021` (real: `22330101`), or any 8-digit value to override the tracking/filename
- **EDIFACT parm (for INVDRIVER only):** `9 ` (digit `9` plus one space)

### Verifying Output
After the program runs, it generates output in the IFS. To find the IFS output file path:
1. Query using the SQL in `c:/Users/gomeza/Documents/gitrepos/waupaca-856-desadv/database/ediinvoic810.sql`
2. Filter by the packing slip number (`223301`)
3. Get the latest record for that packing slip — it contains the IFS file path
4. Read the IFS file and verify the data is correct

Note: passing `00000000` for invoice number triggers derive-from-`IVH021` in `INVOICE`/`EDI810`. Passing a specific value stores that value in `EDIINVOIC810` and the IFS filename, but the EDI content (`BGM02`) always reflects the real `IVH021` regardless. See `decisions/2026-04-20-invoice-number-source-of-truth.md`.

## Decision Documentation

When making non-trivial decisions during a task, document them in the `./decisions` directory. Each decision file should be a markdown file named with the date and a short slug (e.g., `2026-03-22-field-mapping-approach.md`).

A decision record should include:
- **Context:** What problem or question prompted the decision
- **Decision:** What was decided and why
- **Alternatives considered:** Other options that were evaluated
- **Consequences:** Any trade-offs or follow-up work implied

Create one file per decision. This applies to decisions about architecture, data mapping, program structure, algorithm choice, or any judgment call that a future reader would want to understand.
