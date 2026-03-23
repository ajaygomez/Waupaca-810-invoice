---
name: ibmi-compile
description: "Compile RPGLE, SQLRPGLE, and CLLE programs on IBM i and run batch tests. Use when compiling programs, running tests, or executing batch jobs. Triggers on: compile, build, run test, run batch, CRTBNDRPG, CRTSQLRPGI, CRTBNDCL."
---

# IBM i Compile and Test Skill

Compile RPG/RPGLE, SQLRPGLE, and CLLE programs on IBM i via the compile service, run test programs, and execute batch jobs.

---

## CRITICAL: No Data Modification

**NEVER create or run inline programs that execute UPDATE, INSERT, or DELETE SQL statements.** This includes throwaway utility programs for resetting flags, copying test data, or any other data modification. If data needs to be changed, STOP and ask the user to run the SQL manually. Provide the exact SQL statement they should execute.

---

## IMPORTANT: Use the Node.js Compile Script

**Always use the provided Node.js script for all compile operations.** Do NOT create custom scripts or use curl/PowerShell directly.

### Script Location
```
scripts/ibmi-compile.js
```

### Quick Reference Commands

**Compile a program:**
```bash
node scripts/ibmi-compile.js <source-file> [--lib <library>] [--obj <object>]
```

**Compile and run a test:**
```bash
node scripts/ibmi-compile.js run-test <source-file> [--lib <library>]
```

**Run an existing batch program:**
```bash
node scripts/ibmi-compile.js run-batch --program <name> --lib <library> --output-type <db2|ifs|spool> [options]
```

### Examples

```bash
# Compile SQLRPGLE program (mode auto-detected from extension)
node scripts/ibmi-compile.js qrpglesrc/edi027.sqlrpgle --lib AGLIB

# Compile RPGLE program
node scripts/ibmi-compile.js qrpglesrc/mypgm.rpgle --lib DEVLIB

# Compile and run test program
node scripts/ibmi-compile.js run-test qrpglesrc/test.rpgle --lib DEVLIB

# Run batch with IFS database lookup
node scripts/ibmi-compile.js run-batch --program INVTEST --lib EDITEST \
  --params "217584" --output-type ifs --ifs-lookup \
  --lookup-lib EDITEST --lookup-table EDIINVOICE810 \
  --lookup-path-col FILE_PATH --lookup-key "ID=3312" \
  --libl "EDITEST"
```

The script automatically:
- Reads configuration from `.claude/skills/ibmi-compile/config.json`
- Detects compile mode from file extension (.rpgle -> BNDRPG, .sqlrpgle -> SQLRPGLE, .clle -> BNDCL)
- Derives object name from filename (uppercase, max 10 chars)
- Handles source upload to IBM i (inline source transfer is automatic)

Run `node scripts/ibmi-compile.js --help` for full usage details.

---

## Configuration Reference

All configuration options are stored in `.claude/skills/ibmi-compile/config.json`.

### Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `serverUrl` | string | `http://localhost:8080` | The compile service URL |
| `defaultLibrary` | string | `DEVLIB` | Default library for compiled objects |
| `defaultObjectType` | string | `PGM` | Default object type (PGM, MODULE) |
| `defaultMode` | string | `BNDRPG` | Default compile mode |
| `libraryList` | array | `["DEVLIB"]` | Default library list for compilation |
| `compileOptions` | object | `{replace: true, dbgview: "*SOURCE"}` | Default compile options |
| `debugMode` | boolean | `false` | Enable debug mode for troubleshooting |

### Environment Variable Fallbacks

| Env Variable | Config Option | Description |
|--------------|---------------|-------------|
| `IBMI_COMPILE_URL` | `serverUrl` | Fallback URL for compile service |
| `IBMI_COMPILE_LIB` | `defaultLibrary` | Fallback library name |

### Resolution Priority

Configuration values are resolved in this order (first wins):
1. **Explicit parameter** - Value passed directly in the request
2. **Config file** - Value from `.claude/skills/ibmi-compile/config.json`
3. **Environment variable** - Value from env var fallback
4. **Default** - Built-in default value

### Example config.json

```json
{
  "ibmi-compile": {
    "serverUrl": "http://your-ibmi:8080",
    "defaultLibrary": "DEVLIB",
    "defaultObjectType": "PGM",
    "defaultMode": "BNDRPG",
    "libraryList": ["DEVLIB", "UTILS"],
    "compileOptions": {
      "replace": true,
      "dbgview": "*SOURCE"
    },
    "debugMode": false
  }
}
```

---

## Configuration

### Server URL

The compile service URL must be configured before use. There are several ways to determine the URL:

1. **Ask the user** - If not known, ask: "What is the IBM i compile service URL? (e.g., http://hostname:8080)"

2. **Check for config file** - Look for `.claude/skills/ibmi-compile/config.json`:
   ```json
   {
     "ibmi-compile": {
       "serverUrl": "http://your-ibmi:8080",
       "defaultLibrary": "DEVLIB"
     }
   }
   ```

3. **Environment variable** - Check if `IBMI_COMPILE_URL` is set in the environment

4. **Default** - If running locally on IBM i, try `http://localhost:8080`

**Example configurations:**
- Local: `http://localhost:8080`
- Remote IBM i: `http://your-ibmi-hostname:8080`
- With custom port: `http://192.168.1.100:3000`
- With DNS: `http://ibmi.company.local:8080`

### Verifying the Connection

Before compiling, verify the service is running:
```bash
curl -s "http://<SERVER_URL>/health" | jq
```

Expected response: `{"ok":true,"debug":false}`

### Library Whitelist

The compile service only allows compilation to libraries in its `LIB_WHITELIST` environment variable. By default: `DEVLIB,UTILS,QGPL`. Ask the user which library to use if not specified.

**Important:** If using standard IBM i library lists, ensure QGPL is in LIB_WHITELIST. Many programs require QGPL in their library list for standard IBM i functions and commands.

Example whitelist configuration:
```
LIB_WHITELIST=DEVLIB,UTILS,QGPL,EDITEST
```

**Note:** Requests will fail with "Library QGPL is not in LIB_WHITELIST" if QGPL is specified in `env.libl` but not included in the server's whitelist. Ensure all libraries used in the library list are whitelisted on the server.

---

## Available Commands

### 1. Compile a Program (`/compile`)

Compiles source code into a *PGM or *MODULE object.

### 2. Run a Test (`/run-test`)

Compiles and executes a test program, capturing stdout/stderr output.

### 3. Run Batch (`/run-batch`)

Executes an existing batch program and retrieves output from DB2 tables, IFS files, or spool files.

---

## Auto-Derivation Rules

When compiling source files, object names and compile modes can be automatically derived from the source file path.

### Object Name Derivation

The object name is derived from the source filename:

1. Convert filename to uppercase
2. Strip the file extension
3. Truncate to maximum 10 characters (IBM i object name limit)
4. Replace invalid characters with underscore

**Example:**
```
/path/to/ordproc.sqlrpgle -> ORDPROC
/home/user/customer-maint.rpgle -> CUSTOMER_M
/project/src/myprogram123.clle -> MYPROGRAM1
```

**Note:** Explicit `objectName` parameter always overrides auto-derivation.

### Mode Detection

The compile mode is automatically detected from the file extension:

| Extension | Mode | Command |
|-----------|------|---------|
| `.rpgle` | `BNDRPG` | CRTBNDRPG |
| `.sqlrpgle` | `SQLRPGLE` | CRTSQLRPGI |
| `.clle` | `BNDCL` | CRTBNDCL |

**Note:** Explicit `mode` parameter always overrides auto-detection.

---

## Step 1: Determine What the User Wants

Ask or infer:

1. **Action:** Compile, Run Test, or Run Batch?
2. **Source:** Inline code, IFS file path, or existing source member?
3. **Language/Mode:** RPGLE (BNDRPG), SQLRPGLE, or CLLE (BNDCL)?
4. **Target Library:** Which library to compile into?
5. **Object Name:** Name for the compiled program?
6. **Server URL:** Where is the compile service running?

---

## Step 2: Build the Request

### For Compile or Run-Test

**Inline Source Example:**

> **Note:** When using `kind: 'inline'`, the compile service automatically handles uploading the source to IBM i. No manual IFS sync is required - local file changes can be compiled directly.

```json
{
  "source": {
    "kind": "inline",
    "filename": "ordproc.sqlrpgle",
    "extension": "sqlrpgle",
    "language": "SQLRPGLE",
    "memberType": "SQLRPGLE",
    "content": "<source code here>"
  },
  "output": {
    "library": "DEVLIB",
    "objectName": "ORDPROC",
    "objectType": "PGM"
  },
  "mode": "SQLRPGLE"
}
```

**IFS Source Example:**
```json
{
  "source": {
    "kind": "ifs",
    "ifsPath": "/home/user/mypgm.rpgle",
    "library": "DEVLIB",
    "member": "MYPGM"
  },
  "output": {
    "library": "DEVLIB",
    "objectName": "MYPGM",
    "objectType": "PGM"
  },
  "mode": "BNDRPG"
}
```

**Existing Member Example:**
```json
{
  "source": {
    "kind": "member",
    "library": "DEVLIB",
    "file": "QRPGLESRC",
    "member": "MYPGM"
  },
  "output": {
    "library": "DEVLIB",
    "objectName": "MYPGM",
    "objectType": "PGM"
  },
  "mode": "BNDRPG"
}
```

### Mode Selection

| File Extension / Content | Mode |
|-------------------------|------|
| `.rpgle` or free-format RPG | `BNDRPG` |
| `.sqlrpgle` or has `EXEC SQL` | `SQLRPGLE` |
| `.clle` or starts with `PGM` | `BNDCL` |

### Environment and Compile Options

Add `env` and `options` objects to customize compilation. These values default from config when not specified.

```json
{
  "env": {
    "libl": ["DEVLIB", "UTILS"]
  },
  "options": {
    "replace": true,
    "dbgview": "*SOURCE"
  }
}
```

| Field | Description |
|-------|-------------|
| `env.libl` | Library list for the compile job |
| `options.replace` | Replace existing object if it exists |
| `options.dbgview` | Debug view setting (*SOURCE, *LIST, *NONE, etc.) |

### Complete Request Example

A comprehensive example showing all fields for compiling an SQLRPGLE program:

```json
{
  "mode": "SQLRPGLE",
  "output": {
    "library": "DEVLIB",
    "objectName": "ORDPROC",
    "objectType": "PGM"
  },
  "source": {
    "kind": "inline",
    "filename": "ordproc.sqlrpgle",
    "extension": "sqlrpgle",
    "language": "SQLRPGLE",
    "memberType": "SQLRPGLE",
    "content": "**FREE\nctl-opt dftactgrp(*no);\ndcl-s orderId packed(10);\nexec sql SELECT MAX(order_id) INTO :orderId FROM orders;\ndsply orderId;\n*inlr = *on;"
  },
  "env": {
    "libl": ["DEVLIB", "UTILS"]
  },
  "options": {
    "replace": true,
    "dbgview": "*SOURCE"
  }
}
```

### Detecting IFS Lookup Intent

When a user requests run-batch output, determine the correct output mode based on their request:

**Trigger phrases for IFS Database Lookup mode:**
- "output from IFS"
- "get the IFS file"
- "file path from database"
- "grab the file from [table]"
- "look up the path in [table]"
- "find the IFS file for this [key]"

**Decision Logic:**

| User Request Contains | Output Mode |
|-----------------------|-------------|
| Database table AND IFS mention | IFS lookup (`type: "ifs"`, `source: "db"`) |
| Direct IFS path (e.g., `/tmp/file.txt`) | IFS direct (`type: "ifs"`, `path: "..."`) |
| "query the table for output" without IFS | DB2 mode (`type: "db2"`) |
| Table name for results retrieval | DB2 mode (`type: "db2"`) |
| Spool file or print output | Spool mode (`type: "spool"`) |

### Building IFS Lookup Requests

When constructing an IFS lookup request, map user terms to the correct lookup fields:

**Common Parameter Mappings:**

| User Term | Maps To | Example Value |
|-----------|---------|---------------|
| "invoice number", "invoice ID" | `keyColumn: "INVOICE_NUMBER"` | `keyValue: "INV-12345"` |
| "order number", "order ID" | `keyColumn: "ORDER_ID"` | `keyValue: "ORD-12345"` |
| "document ID", "doc number" | `keyColumn: "DOC_ID"` | `keyValue: 98765` |
| "latest record", "most recent" | `orderBy` | `"CREATED_DATE DESC"` |
| "oldest", "first created" | `orderBy` | `"CREATED_DATE ASC"` |

### For Run-Batch

**DB2 Output Example:**
```json
{
  "program": {
    "library": "DEVLIB",
    "name": "BATCHPGM",
    "params": ["PARM1", "PARM2"]
  },
  "output": {
    "type": "db2",
    "tables": [
      { "library": "DEVLIB", "table": "RESULTS", "limit": 100 }
    ]
  },
  "env": {
    "libl": ["DEVLIB", "UTILS"],
    "curlib": "DEVLIB"
  }
}
```

**IFS Output Example:**
```json
{
  "program": {
    "library": "DEVLIB",
    "name": "RPTPGM"
  },
  "output": {
    "type": "ifs",
    "path": "/tmp/report.txt"
  }
}
```

**IFS Database Lookup Example:**

Use lookup mode when the IFS path is stored in a database table. Instead of providing a direct path, specify a lookup configuration that queries the database to find the IFS file path.

```json
{
  "program": {
    "library": "EDITEST",
    "name": "INVTEST",
    "params": ["12345"]
  },
  "output": {
    "type": "ifs",
    "source": "db",
    "lookup": {
      "library": "EDITEST",
      "table": "EDIINVOICE810",
      "pathColumn": "FILE_PATH",
      "keyColumn": "ID",
      "keyValue": 3312,
      "orderBy": "CREATED_DATE DESC"
    }
  },
  "env": {
    "libl": ["EDITEST", "QGPL"]
  }
}
```

| Lookup Field | Description |
|--------------|-------------|
| `library` | Library containing the lookup table |
| `table` | Table name containing IFS path references |
| `pathColumn` | Column that stores the IFS file path |
| `keyColumn` | Column used to filter records (e.g., INVOICE_NUMBER) |
| `keyValue` | Value to match in the key column |
| `orderBy` | (Optional) Sort order to select the desired record |

**Spool Output Example:**
```json
{
  "program": {
    "library": "DEVLIB",
    "name": "PRINTPGM"
  },
  "output": {
    "type": "spool",
    "file": "QPRINT"
  }
}
```

---

## Step 3: Execute the Request

Use `curl` via bash to call the compile service:

### Compile Command
```bash
curl -s -X POST "http://<SERVER_URL>/compile" \
  -H "Content-Type: application/json" \
  -d '<JSON_PAYLOAD>'
```

### Run-Test Command
```bash
curl -s -X POST "http://<SERVER_URL>/run-test" \
  -H "Content-Type: application/json" \
  -d '<JSON_PAYLOAD>'
```

### Run-Batch Command
```bash
curl -s -X POST "http://<SERVER_URL>/run-batch" \
  -H "Content-Type: application/json" \
  -d '<JSON_PAYLOAD>'
```

### Health Check
```bash
curl -s "http://<SERVER_URL>/health"
```

---

## Step 4: Handle the Response

### Successful Compile Response
```json
{
  "requestId": "uuid",
  "startedAt": "ISO timestamp",
  "finishedAt": "ISO timestamp",
  "success": true,
  "object": "DEVLIB/MYPGM",
  "objectType": "PGM"
}
```

**Report to user:** "Successfully compiled DEVLIB/MYPGM"

### Failed Compile Response
```json
{
  "requestId": "uuid",
  "success": false,
  "error": "error message",
  "artifacts": { "joblog": "...compile joblog text..." },
  "analysis": {
    "highestSeverity": 30,
    "warnings": 0,
    "errors": 0,
    "severeErrors": 1,
    "created": false,
    "notCreated": true
  }
}
```

**Report to user:**
1. Compilation failed
2. Show the error message
3. Parse the joblog for specific error messages (look for RNF, RNS, SQL, CPF messages)
4. Suggest fixes based on the errors

### Successful Run-Test Response
```json
{
  "requestId": "uuid",
  "success": true,
  "compiled": true,
  "executed": true,
  "object": "DEVLIB/TESTPGM",
  "stdout": "program output",
  "stderr": ""
}
```

**Report to user:**
1. Test program compiled and executed successfully
2. Show the stdout output (this contains test results like DSPLY messages)

### Failed Run-Test Response (Compile Failed)
```json
{
  "success": false,
  "compiled": false,
  "executed": false,
  "error": "compile error message",
  "artifacts": { "joblog": "..." },
  "analysis": { ... }
}
```

### Failed Run-Test Response (Runtime Failed)
```json
{
  "success": false,
  "compiled": true,
  "executed": false,
  "error": "runtime error message",
  "stdout": "partial output before crash",
  "stderr": "error output",
  "exitCode": 1
}
```

### Successful Run-Batch Response
```json
{
  "requestId": "uuid",
  "success": true,
  "program": {
    "library": "DEVLIB",
    "name": "MYPGM",
    "type": "RPGLE"
  },
  "output": {
    "type": "db2",
    "data": {
      "OUTTBL": [{ "COL1": "value1", "COL2": 123 }]
    },
    "metadata": {
      "OUTTBL": {
        "library": "DEVLIB",
        "table": "OUTTBL",
        "rowCount": 1,
        "fetchDurationMs": 50
      }
    }
  }
}
```

---

## Error Code Reference

### Batch Error Codes
| Code | Description |
|------|-------------|
| `VALIDATION_ERROR` | Request validation failed |
| `PGM_NOT_FOUND` | Program does not exist |
| `INTERACTIVE_PGM` | Program is interactive (uses 5250) |
| `RUNTIME_ERROR` | Program execution failed |

### Common Compile Errors

| Message Pattern | Meaning | Fix |
|-----------------|---------|-----|
| `RNF7023` | Undeclared variable | Declare the variable with `Dcl-S` or `Dcl-DS` |
| `RNF7030` | Procedure not found | Check procedure name spelling and export |
| `RNF7031` | Data structure not found | Ensure data structure is declared |
| `RNS9380` | CCSID conversion error | Source file CCSID mismatch |
| `SQL0104` | SQL syntax error | Check SQL statement syntax |
| `SQL0204` | Object not found in SQL | Table/view doesn't exist or not qualified |
| `CPF9801` | Object not found | Check library/object names |
| `CPF9810` | Library not found | Library doesn't exist or not in library list |

---

## Complete Workflow Example

### Example 1: Compile an RPGLE Program

**User says:** "Compile the file qrpglesrc/CUSTMAINT.rpgle to DEVLIB"

**Steps:**
1. Read the source file content
2. Detect mode as BNDRPG (based on extension)
3. Build the request:
```json
{
  "source": {
    "kind": "inline",
    "content": "<file content>"
  },
  "output": {
    "library": "DEVLIB",
    "objectName": "CUSTMAINT",
    "objectType": "PGM"
  },
  "mode": "BNDRPG"
}
```
4. Execute: `curl -s -X POST "http://SERVER_URL/compile" -H "Content-Type: application/json" -d '...'`
5. Parse response and report result

### Example 2: Run a Test Program

**User says:** "Run this test program"

```rpgle
**FREE
ctl-opt dftactgrp(*no);
dsply 'Test started';
dsply 'All tests passed!';
*inlr = *on;
```

**Steps:**
1. Use `/run-test` endpoint
2. Build request with inline source
3. Execute and capture stdout
4. Report: "Test executed successfully. Output: Test started / All tests passed!"

### Example 3: Run Batch and Get DB2 Output

**User says:** "Run PROCDATA in DEVLIB and get results from PROCLOG table"

**Steps:**
1. Use `/run-batch` endpoint
2. Build request:
```json
{
  "program": {
    "library": "DEVLIB",
    "name": "PROCDATA"
  },
  "output": {
    "type": "db2",
    "tables": [
      { "library": "DEVLIB", "table": "PROCLOG" }
    ]
  }
}
```
3. Execute and display the table data

---

## Debug Mode / Troubleshooting

Enable debug mode to save request and response JSON for troubleshooting compile issues.

### Enabling Debug Mode

Set `debugMode: true` in your config file:
```json
{
  "ibmi-compile": {
    "debugMode": true
  }
}
```

### Saving Debug Files

When debug mode is enabled, save request and response JSON to the `tmp/` directory:

```bash
# Create tmp directory if it doesn't exist
mkdir -p tmp

# Save request JSON with timestamp
cat > "tmp/compile-request-$(date +%Y%m%d-%H%M%S).json" << 'EOF'
{
  "source": { ... },
  "output": { ... },
  "mode": "SQLRPGLE"
}
EOF

# Execute compile and save response
curl -s -X POST "http://SERVER_URL/compile" \
  -H "Content-Type: application/json" \
  -d @"tmp/compile-request-*.json" | tee tmp/compile-response.json | jq
```

### Extracting Joblog from Failed Compiles

When a compile fails, the joblog contains detailed error information:

```bash
# Extract joblog from response
jq -r '.artifacts.joblog' tmp/compile-response.json

# Search for specific error messages
jq -r '.artifacts.joblog' tmp/compile-response.json | grep -E "RNF|SQL|CPF"
```

### Common Debug Scenarios

1. **Request not reaching server** - Check server health endpoint first
2. **Source encoding issues** - Verify file content doesn't contain invalid characters
3. **Missing library list** - Check if required libraries are in the `env.libl` array
4. **Permission denied** - Verify target library is in LIB_WHITELIST

---

## Tips

1. **Inline source is automatically transferred** - When using `kind: 'inline'`, the compile service handles uploading the source to IBM i automatically. Local file changes can be compiled directly without manual IFS sync.
2. **Always check server health first** if compile fails with connection errors
2. **Escape special characters** in inline source (especially quotes and backslashes)
3. **For SQLRPGLE**, the service automatically handles EXEC SQL statements
4. **For CLLE**, use mode `BNDCL`, `CLLE`, or `CL` (all equivalent)
5. **Library must be whitelisted** - check LIB_WHITELIST if library rejected
6. **Use jq** to parse JSON responses: `curl ... | jq '.success'`

---

## Quick Reference

| Action | Endpoint | Key Fields |
|--------|----------|------------|
| Compile | POST /compile | source, output, mode |
| Test | POST /run-test | source, output, mode |
| Batch | POST /run-batch | program, output |
| Health | GET /health | (none) |

| Source Kind | Required Fields |
|-------------|-----------------|
| inline | content |
| ifs | ifsPath, library, member |
| member | library, member, (file) |

| Mode | Language | Command |
|------|----------|---------|
| BNDRPG | RPGLE | CRTBNDRPG |
| SQLRPGLE | SQL RPGLE | CRTSQLRPGI |
| BNDCL | CLLE | CRTBNDCL |

### Output Types (Run-Batch)

| Output Type | Mode | Required Fields |
|-------------|------|-----------------|
| DB2 | `type: "db2"` | `tables: [{library, table}]` |
| IFS Direct | `type: "ifs"` | `path: "/path/to/file"` |
| IFS Lookup | `type: "ifs"`, `source: "db"` | `lookup.library`, `lookup.table`, `lookup.pathColumn`, `lookup.keyColumn`, `lookup.keyValue` |
| Spool | `type: "spool"` | `file: "QPRINT"` |

| IFS Lookup Field | Required | Description |
|------------------|----------|-------------|
| `lookup.library` | Yes | Library containing the lookup table |
| `lookup.table` | Yes | Table name with IFS path references |
| `lookup.pathColumn` | Yes | Column storing the IFS file path |
| `lookup.keyColumn` | Yes | Column to filter records |
| `lookup.keyValue` | Yes | Value to match in key column |
| `lookup.orderBy` | No | Sort order (e.g., "CREATED_DATE DESC") |

---

## Checklist Before Compiling

- [ ] Server URL is known and accessible
- [ ] Target library is in LIB_WHITELIST
- [ ] Source code is available (file or inline)
- [ ] Object name follows IBM i naming rules (max 10 chars, starts with letter)
- [ ] Correct mode selected for the language
- [ ] For tests: program has proper exit (*INLR = *ON or RETURN)
