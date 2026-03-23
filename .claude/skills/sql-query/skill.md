---
name: sql-query
description: "Execute read-only SQL queries against the IBM i database. Use when you need to query database tables, explore schemas, or retrieve data. Triggers on: query database, run sql, select from, show tables, describe table, database query."
---

# SQL Query Skill

Execute read-only SQL queries against the IBM i Db2 database via the Express API.

**CRITICAL RULE: NEVER execute UPDATE, INSERT, or DELETE statements — not through this skill, not through inline SQLRPGLE programs, not through any other mechanism. If you need data modified (e.g., resetting flags, copying test data, inserting rows), STOP and ask the user to run the statement manually. Provide the exact SQL statement they should execute.**

**CRITICAL RULE: NEVER put single quotes inside curl `-d` arguments using `'\''`, `"'"`, printf tricks, or ANY shell escaping. Claude Code flags these as security risks and prompts the user every time. Instead, ALWAYS use this two-step pattern:**

1. **Write tool** creates `$HOME/tmp/query.json` with the JSON payload (single quotes go in naturally)
2. **Bash tool** runs `curl ... -d @$HOME/tmp/query.json`

**If the SQL has NO single quotes** (no string literals), you may use inline `-d '{"sql":"..."}'` directly.

---

## Quick Start — How to Run a Query

### Step 1: Read credentials from express/.env

```bash
source c:/Users/gomeza/Documents/gitrepos/Waupaca-810-invoice/express/.env
```

### Step 2: If SQL contains single quotes, use Write tool + curl

Use the **Write tool** to create `$HOME/tmp/query.json`:
```json
{"sql":"SELECT TABLE_NAME FROM QSYS2.SYSTABLES WHERE TABLE_SCHEMA = 'WFLIB' ORDER BY TABLE_NAME","format":"table"}
```

Then **Bash tool**:
```bash
curl -s -X POST http://as400:3000/api/compare/query -H "Content-Type: application/json" -H "X-DB-User: $IBMI_DB_USER" -H "X-DB-Pass: $IBMI_DB_PASS" -d @$HOME/tmp/query.json
```

### Step 2 (alt): If SQL has NO single quotes, inline is OK

```bash
curl -s -X POST http://as400:3000/api/compare/query -H "Content-Type: application/json" -H "X-DB-User: $IBMI_DB_USER" -H "X-DB-Pass: $IBMI_DB_PASS" -d '{"sql":"SELECT * FROM WFLIB.EDIINVOICE810 FETCH FIRST 10 ROWS ONLY","format":"table"}'
```

---

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `EDI_SERVICE_URL` | Yes | `http://as400:3000` | Base URL of the Express API service |
| `IBMI_DB_USER` | Yes | - | IBM i database username |
| `IBMI_DB_PASS` | Yes | - | IBM i database password |

### Example Configurations

**Local development:**
```bash
export EDI_SERVICE_URL="http://as400:3000"
```

**Remote server:**
```bash
export EDI_SERVICE_URL="http://ibmi-server:3000"
```

**With custom port:**
```bash
export EDI_SERVICE_URL="http://192.168.1.100:8080"
```

---

## Authentication Methods

### Method 1: Environment Variables with Headers (Recommended for Claude Code)

Set credentials as environment variables, then pass via headers:

```bash
# Set once per session
export EDI_SERVICE_URL="http://as400:3000"
export IBMI_DB_USER="username"
export IBMI_DB_PASS="password"

# Use in queries
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT COUNT(*) FROM WFLIB.EDIINVOICE810"}'
```

### Method 2: Session-Based (for browser/Angular app)

```bash
# Login first
curl -X POST $EDI_SERVICE_URL/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"USER","password":"PASS"}' \
  -c cookies.txt

# Then query with session cookie
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -b cookies.txt \
  -d '{"sql":"SELECT * FROM WFLIB.EDIINVOICE810"}'
```

---

## Output Formats

### JSON (default)

```bash
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT INVOICE_NUMBER, CUSTOMER_NUMBER FROM WFLIB.EDIINVOICE810 FETCH FIRST 5 ROWS ONLY"}'
```

Response:
```json
{
  "rowCount": 5,
  "columns": ["INVOICE_NUMBER", "CUSTOMER_NUMBER"],
  "data": [
    {"INVOICE_NUMBER": 123456, "CUSTOMER_NUMBER": 12345},
    ...
  ]
}
```

### Table (easy to read in terminal)

```bash
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT INVOICE_NUMBER, CUSTOMER_NUMBER FROM WFLIB.EDIINVOICE810 FETCH FIRST 5 ROWS ONLY","format":"table"}'
```

### CSV

```bash
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT * FROM WFLIB.EDIINVOICE810","format":"csv"}'
```

---

## Common Queries

### List Tables in a Schema

When SQL contains single quotes (string literals like schema/table names), use the **Write tool** to create the JSON payload file, then curl with `-d @file`. This avoids Claude Code security checks on quote patterns.

```
# Step 1: Use Write tool to create $HOME/tmp/query.json:
{"sql":"SELECT TABLE_NAME, TABLE_TYPE FROM QSYS2.SYSTABLES WHERE TABLE_SCHEMA = 'WFLIB' ORDER BY TABLE_NAME","format":"table"}

# Step 2: Bash call:
curl -s -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d @$HOME/tmp/query.json
```

### Describe Table Columns

```
# Step 1: Use Write tool to create $HOME/tmp/query.json:
{"sql":"SELECT COLUMN_NAME, DATA_TYPE, LENGTH, NUMERIC_SCALE, IS_NULLABLE FROM QSYS2.SYSCOLUMNS WHERE TABLE_SCHEMA = 'WFLIB' AND TABLE_NAME = 'EDIINVOICE810' ORDER BY ORDINAL_POSITION","format":"table"}

# Step 2: Bash call:
curl -s -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d @$HOME/tmp/query.json
```

### Count Rows

```bash
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT COUNT(*) AS TOTAL_ROWS FROM WFLIB.EDIINVOICE810"}'
```

### Recent Records

```bash
curl -X POST $EDI_SERVICE_URL/api/compare/query \
  -H "Content-Type: application/json" \
  -H "X-DB-User: $IBMI_DB_USER" \
  -H "X-DB-Pass: $IBMI_DB_PASS" \
  -d '{"sql":"SELECT ID, INVOICE_NUMBER, CUSTOMER_NUMBER, CHANGED_DATE FROM WFLIB.EDIINVOICE810 ORDER BY CHANGED_DATE DESC FETCH FIRST 20 ROWS ONLY","format":"table"}'
```

---

## Request Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `sql` | string | required | The SELECT statement to execute |
| `format` | string | `"json"` | Output format: `json`, `table`, or `csv` |
| `limit` | number | 1000 | Max rows (auto-appended if no FETCH FIRST/LIMIT) |

---

## Security

### Allowed Statements
- SELECT queries
- WITH (Common Table Expressions) followed by SELECT

### Blocked Operations
- INSERT, UPDATE, DELETE (data modification)
- CREATE, DROP, ALTER, TRUNCATE (schema changes)
- GRANT, REVOKE (permissions)
- EXECUTE, EXEC, CALL (stored procedures)
- SET (session variables)
- Multiple statements (semicolons blocked)

### Automatic Protections
- Row limit of 1000 auto-applied if not specified
- All queries require authentication
- Connection uses caller's credentials (not a service account)

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `Authentication required` | Missing credentials | Add X-DB-User/X-DB-Pass headers or login first |
| `Only SELECT statements are allowed` | Non-SELECT query | Use only SELECT or WITH...SELECT |
| `Forbidden keyword detected: UPDATE` | Blocked keyword | Remove modifying statements |
| `Multiple statements are not allowed` | Semicolon in query | Remove semicolons, run single query |
| `SQL0204` | Table not found | Check schema/table name spelling |
| `SQL0206` | Column not found | Verify column exists in table |
| `Connection refused` | Server not running or wrong URL | Check EDI_SERVICE_URL and server status |

---

## Tips for Claude Code Usage

1. **Always set environment variables first** - Set `EDI_SERVICE_URL`, `IBMI_DB_USER`, and `IBMI_DB_PASS`
2. **Use `format=table`** for readable output in terminal
3. **Limit results** - Add `FETCH FIRST N ROWS ONLY` for large tables
4. **SQL with single quotes** - Use the Write tool to create a JSON payload file, then `curl -d @$HOME/tmp/query.json`. NEVER use `'\''` or printf quote tricks in Bash — they trigger security prompts.
5. **Check column names first** - Query QSYS2.SYSCOLUMNS before writing complex queries

---

## Known Schemas

| Schema | Description |
|--------|-------------|
| `WFLIB` | Production EDI tables |
| `EDITEST` | EDI testing tables (fallback) |
| `EDI32DTAT` | EDI mailbox data (EDOTBX) |
| `QSYS2` | System catalog (SYSTABLES, SYSCOLUMNS) |

---

## Troubleshooting

### Environment Variables Not Set
```bash
# Check if set
echo $EDI_SERVICE_URL
echo $IBMI_DB_USER

# Set if missing
export EDI_SERVICE_URL="http://as400:3000"
export IBMI_DB_USER="your_username"
export IBMI_DB_PASS="your_password"
```

### Server Not Running
```bash
# Start the Express server
cd express && npm start
```

### Connection Issues
```bash
# Test server health
curl $EDI_SERVICE_URL/api/health
```

Expected: `{"status":"healthy"}`

### Wrong URL
```bash
# Verify the URL is correct
echo $EDI_SERVICE_URL

# Test connectivity
curl -I $EDI_SERVICE_URL/api/health
```
