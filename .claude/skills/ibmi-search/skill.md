---
name: ibmi-search
description: "Search IBM i source members across libraries via SSH or SQL API. Use when searching for programs, finding source members, or exploring QRPGSRC/QRPGLESRC/QCLSRC/QSQLSRC. Triggers on: search source, find program, search QRPGSRC, find member, list members, search ibmi, search as400."
---

# IBM i Source Member Search Skill

Search for source members across IBM i libraries using SSH or the Express SQL API.

**CRITICAL: NEVER put single quotes inside curl `-d` arguments using `'\''`, `"'"`, printf tricks, or ANY shell escaping. Claude Code flags these as security risks and prompts the user every time. When SQL contains single quotes (string literals), ALWAYS use the Write tool to create a JSON payload file first, then `curl -d @$HOME/tmp/query.json`.**

---

## Two Methods Available

### Method 1: SQL API (Preferred for metadata searches)

Use the Express API SQL endpoint to query `QSYS2.SYSPARTITIONSTAT` for source member names, descriptions, and types. This is the fastest way to search by member name or description text.

### Method 2: SSH with SSH_ASKPASS (For IFS access and shell commands)

Use SSH with automated password via SSH_ASKPASS for direct shell access. Required for reading source file contents or running CL commands.

---

## Credentials

Read credentials from `express/.env`:
```
IBMI_DB_USER=gomeza
IBMI_DB_PASS=p@ckers8
```

- **Hostname:** `as400`
- **Express API:** `http://as400:3000`

---

## Method 1: SQL API Search

### Prerequisites

The Express server must be running at `http://as400:3000`.

### Search Source Members by Name or Description

**Step 1:** Source credentials:
```bash
source c:/Users/gomeza/Documents/gitrepos/Waupaca-810-invoice/express/.env
```

**Step 2:** Use the **Write tool** to create `$HOME/tmp/query.json`:
```json
{"sql":"SELECT SYSTEM_TABLE_MEMBER AS MEMBER, SYSTEM_TABLE_SCHEMA AS LIBRARY, SYSTEM_TABLE_NAME AS SRCFILE, SOURCE_TYPE, TRIM(PARTITION_TEXT) AS DESCRIPTION FROM QSYS2.SYSPARTITIONSTAT WHERE SYSTEM_TABLE_NAME IN ('QRPGSRC', 'QRPGLESRC', 'QSQLSRC', 'QCLSRC') AND (UPPER(PARTITION_TEXT) LIKE '%SEARCH_TERM%') ORDER BY LIBRARY, SRCFILE, MEMBER","format":"table","limit":500}
```

**Step 3:** Run curl with file payload:
```bash
curl -s -X POST http://as400:3000/api/compare/query -H "Content-Type: application/json" -H "X-DB-User: $IBMI_DB_USER" -H "X-DB-Pass: $IBMI_DB_PASS" -d @$HOME/tmp/query.json
```

### Key Columns in QSYS2.SYSPARTITIONSTAT

| Column | Description |
|--------|-------------|
| `SYSTEM_TABLE_MEMBER` | Member name (10 char) |
| `SYSTEM_TABLE_SCHEMA` | Library name |
| `SYSTEM_TABLE_NAME` | Source file name (QRPGSRC, QRPGLESRC, etc.) |
| `SOURCE_TYPE` | Source type (RPGLE, SQLRPGLE, CLP, CLLE, etc.) |
| `PARTITION_TEXT` | Member description/text |
| `CREATE_TIMESTAMP` | When the member was created |
| `LAST_SOURCE_UPDATE_TIMESTAMP` | Last source change |

### Source Physical File Columns (for content queries)

When querying source file content directly (e.g., `SELECT * FROM WFLIB.QRPGSRC`):

| Column | Type | Description |
|--------|------|-------------|
| `SRCSEQ` | NUMERIC(6,2) | Sequence number |
| `SRCDAT` | NUMERIC(6) | Source date (YYMMDD) |
| `SRCDTA` | CHAR(80) | Source data line |

**IMPORTANT:** Source physical files do NOT have a `SRCMBR` column. The member name is a partition attribute, not a regular column. To get the member name with source data, you must query members individually or use `QSYS2.SYSPARTITIONSTAT` for member metadata.

### Common Source File Names

| Source File | Contains |
|-------------|----------|
| `QRPGSRC` | RPG and RPGLE source |
| `QRPGLESRC` | RPGLE and SQLRPGLE source |
| `QSQLSRC` | SQL source (views, indexes, etc.) |
| `QCLSRC` | CL and CLLE source |
| `QDDSSRC` | DDS source (files, displays) |
| `QCMDSRC` | Command definitions |

---

## Method 2: SSH with SSH_ASKPASS

### Setup (Required Once Per Session)

Create the SSH_ASKPASS helper script to automate password entry. **Use the Write tool** (never printf/echo — triggers security prompts):

**Step 1:** Write tool creates `C:/Users/gomeza/tmp/ssh_askpass.sh` with content:
```
#!/bin/bash
echo "p@ckers8"
```

**Step 2:** Bash:
```bash
chmod +x C:/Users/gomeza/tmp/ssh_askpass.sh
```

### Running SSH Commands

Always prefix SSH commands with the SSH_ASKPASS environment variables:

```bash
export SSH_ASKPASS=/tmp/ssh_askpass.sh && export SSH_ASKPASS_REQUIRE=force && ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no gomeza@as400 "COMMAND_HERE"
```

### Example: List Libraries with QRPGSRC

```bash
export SSH_ASKPASS=/tmp/ssh_askpass.sh && export SSH_ASKPASS_REQUIRE=force && ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no gomeza@as400 "ls -d /QSYS.LIB/*.LIB/QRPGSRC.FILE 2>/dev/null"
```

### Example: List Members in a Library

```bash
export SSH_ASKPASS=/tmp/ssh_askpass.sh && export SSH_ASKPASS_REQUIRE=force && ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no gomeza@as400 "ls /QSYS.LIB/WFLIB.LIB/QRPGSRC.FILE/*.MBR 2>/dev/null"
```

### Important SSH Notes

- Source files on IBM i are EBCDIC. `cat` and `grep` on `/QSYS.LIB/` paths produce garbled output
- For content searching, use the SQL API method instead
- IFS path format: `/QSYS.LIB/{LIBRARY}.LIB/{SRCFILE}.FILE/{MEMBER}.MBR`
- `db2util` may not be installed on the system; do NOT rely on it
- The `system` CL command works via SSH but `RUNSQL` produces no visible terminal output

---

## Known Libraries with QRPGSRC

| Library | Description |
|---------|-------------|
| AGLIB | Development/test library |
| DBQPGM | |
| DBQPGM20 | |
| EDIPROD | EDI production |
| EDITEST | EDI testing |
| HAWKEYE | |
| IISCUSTOM | |
| JBLIB | JB development |
| JBSRC | JB source |
| JCLIB | JC development (active EDI programs) |
| MMLIB | MM development |
| MRCWORKLIB | |
| MRLIB | |
| QGPL | General purpose |
| QSYSINC | System includes |
| SOURCE | Production/archive source library |
| WFLIB | Production library |
| WFLIB19 | Archive |
| X2EGEN | X2E generation |
| XWAUPACA2 | Waupaca extensions |

---

## Common Search Patterns

### Search by EDI Document Type

```sql
-- X12 810 Invoice
UPPER(PARTITION_TEXT) LIKE '%X12%810%' OR UPPER(PARTITION_TEXT) LIKE '%810%INVOICE%'

-- EDIFACT INVOIC
UPPER(PARTITION_TEXT) LIKE '%EDIFACT%INVOIC%'

-- X12 856 ASN
UPPER(PARTITION_TEXT) LIKE '%856%' OR UPPER(PARTITION_TEXT) LIKE '%ASN%' OR UPPER(PARTITION_TEXT) LIKE '%DESADV%'

-- EDIFACT DESADV
UPPER(PARTITION_TEXT) LIKE '%DESADV%' OR UPPER(PARTITION_TEXT) LIKE '%EDIFACT%DESADV%'
```

### Search by Member Name Pattern

```sql
-- All EDI-related members
UPPER(SYSTEM_TABLE_MEMBER) LIKE 'EDI%'

-- Specific member
SYSTEM_TABLE_MEMBER = 'EDI027'

-- All versions of a member across libraries
SYSTEM_TABLE_MEMBER = 'EDI027'
-- (omit library filter to search all libraries)
```

### Search Across All Libraries

```sql
SELECT SYSTEM_TABLE_MEMBER AS MEMBER,
       SYSTEM_TABLE_SCHEMA AS LIBRARY,
       SYSTEM_TABLE_NAME AS SRCFILE,
       SOURCE_TYPE,
       TRIM(PARTITION_TEXT) AS DESCRIPTION
FROM QSYS2.SYSPARTITIONSTAT
WHERE SYSTEM_TABLE_NAME IN ('QRPGSRC', 'QRPGLESRC', 'QSQLSRC', 'QCLSRC')
  AND (search conditions here)
ORDER BY LIBRARY, SRCFILE, MEMBER
```

---

## Tips

1. **Prefer the SQL API** for searching metadata (member names, descriptions, types)
2. **Use SSH** only when you need shell access (listing IFS files, running CL commands)
3. **Always use SSH_ASKPASS** - never prompt the user for SSH passwords interactively
4. **PARTITION_TEXT** is the column for member description (not TEXT_DESCRIPTION)
5. **Source files are EBCDIC** - cannot grep/cat source via IFS; use SQL API for content
6. **JCLIB** is the active development library for EDI programs
7. **SOURCE** is the production/archive source library
8. **Read credentials from `express/.env`** - never hardcode or ask the user for them
