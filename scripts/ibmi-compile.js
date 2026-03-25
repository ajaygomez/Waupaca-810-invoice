#!/usr/bin/env node
/**
 * ibmi-compile.js - Compile and run RPG/RPGLE, SQLRPGLE, and CLLE programs on IBM i
 *
 * Commands:
 *   compile (default)   Compile source code to PGM or MODULE
 *   run-test            Compile and execute test program, capture stdout/stderr
 *   run-batch           Execute existing batch program, retrieve output from DB2/IFS/spool
 *
 * Usage:
 *   node scripts/ibmi-compile.js <source-file> [options]           # compile (default)
 *   node scripts/ibmi-compile.js run-test <source-file> [options]  # compile & run test
 *   node scripts/ibmi-compile.js run-batch [options]               # run existing program
 *
 * Compile Options:
 *   --lib <library>     Target library (default: from config or DEVLIB)
 *   --obj <object>      Object name (default: derived from filename, max 10 chars)
 *   --type <type>       Object type: PGM or MODULE (default: PGM)
 *   --mode <mode>       Compile mode: BNDRPG, SQLRPGLE, BNDCL (default: auto-detect)
 *
 * Run-Batch Options:
 *   --program <name>          Program name to execute (required for run-batch)
 *   --program-lib <library>   Program library (default: uses --lib)
 *   --params <p1,p2,...>      Program parameters (comma-separated)
 *   --output-type <type>      Output type: db2, ifs, spool (required for run-batch)
 *
 *   DB2 Output:
 *     --tables <spec>         Tables: LIB/TABLE or LIB/TABLE:alias (comma-separated)
 *     --query <sql>           Custom SQL query for single table
 *     --limit <n>             Max rows per table (default: 1000)
 *
 *   IFS Output (direct path):
 *     --ifs-path <path>       IFS file path to read
 *
 *   IFS Output (database lookup):
 *     --ifs-lookup            Enable database lookup mode for IFS path
 *     --lookup-lib <lib>      Lookup table library
 *     --lookup-table <table>  Lookup table name
 *     --lookup-path-col <col> Column containing the IFS path
 *     --lookup-key <col=val>  Key column and value (repeatable for composite keys)
 *     --lookup-order <order>  ORDER BY clause (e.g., "CREATED_DATE DESC")
 *
 *   Spool Output:
 *     --spool-file <name>     Spool file name pattern
 *
 * Common Options:
 *   --url <url>         Compile service URL (default: from config)
 *   --libl <libs>       Library list (comma-separated)
 *   --curlib <lib>      Current library
 *   --debug             Enable debug mode (save request/response JSON)
 *   --help              Show this help message
 *
 * Configuration:
 *   Reads from .claude/skills/ibmi-compile/config.json if present.
 *   Environment variables IBMI_COMPILE_URL and IBMI_COMPILE_LIB are fallbacks.
 *
 * Examples:
 *   # Compile RPGLE program
 *   node scripts/ibmi-compile.js qrpglesrc/mypgm.rpgle --lib TESTLIB
 *
 *   # Compile and run test
 *   node scripts/ibmi-compile.js run-test qrpglesrc/test.rpgle --lib DEVLIB
 *
 *   # Run batch with DB2 output
 *   node scripts/ibmi-compile.js run-batch --program MYPGM --lib DEVLIB \
 *     --output-type db2 --tables "DEVLIB/RESULTS,DEVLIB/LOG:logs"
 *
 *   # Run batch with IFS database lookup
 *   node scripts/ibmi-compile.js run-batch --program EDI856PGM --program-lib EDILIB \
 *     --params "123456" --output-type ifs --ifs-lookup \
 *     --lookup-lib EDITEST --lookup-table EDIDESADV856 \
 *     --lookup-path-col FILE_PATH --lookup-key "PACKING_SLIP=123456" \
 *     --lookup-order "CREATED_DATE DESC"
 */

const fs = require('fs');
const path = require('path');
const http = require('http');
const https = require('https');

// -----------------------------------------------------------------------------
// Configuration Loading
// -----------------------------------------------------------------------------

function loadConfig() {
  const configPath = path.join(process.cwd(), '.claude', 'skills', 'ibmi-compile', 'config.json');
  let config = {
    serverUrl: process.env.IBMI_COMPILE_URL || 'http://localhost:8080',
    defaultLibrary: process.env.IBMI_COMPILE_LIB || 'DEVLIB',
    defaultObjectType: 'PGM',
    defaultMode: 'BNDRPG',
    libraryList: null, // null means "use target library"
    compileOptions: { replace: true, dbgview: '*SOURCE' },
    debugMode: false
  };

  if (fs.existsSync(configPath)) {
    try {
      const fileConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
      if (fileConfig['ibmi-compile']) {
        config = { ...config, ...fileConfig['ibmi-compile'] };
      }
    } catch (err) {
      console.error(`[ibmi-compile] Warning: Could not parse config file: ${err.message}`);
    }
  }

  return config;
}

// -----------------------------------------------------------------------------
// Argument Parsing
// -----------------------------------------------------------------------------

function parseArgs(args) {
  const options = {
    command: 'compile', // compile, run-test, or run-batch
    sourceFile: null,
    lib: null,
    obj: null,
    type: null,
    mode: null,
    url: null,
    debug: false,
    help: false,
    // Common options
    libl: null,
    curlib: null,
    // Run-batch specific options
    program: null,
    programLib: null,
    params: null,
    outputType: null,
    // DB2 output options
    tables: null,
    query: null,
    limit: null,
    // IFS output options
    ifsPath: null,
    ifsLookup: false,
    lookupLib: null,
    lookupTable: null,
    lookupPathCol: null,
    lookupKeys: [],
    lookupOrder: null,
    // Spool output options
    spoolFile: null
  };

  let i = 0;

  // Check for command as first argument
  if (args.length > 0 && !args[0].startsWith('-')) {
    const firstArg = args[0].toLowerCase();
    if (firstArg === 'run-test' || firstArg === 'run-batch') {
      options.command = firstArg;
      i = 1;
    }
  }

  while (i < args.length) {
    const arg = args[i];
    switch (arg) {
      // Compile options
      case '--lib':
        options.lib = args[++i];
        break;
      case '--obj':
        options.obj = args[++i];
        break;
      case '--type':
        options.type = args[++i];
        break;
      case '--mode':
        options.mode = args[++i];
        break;
      // Common options
      case '--url':
        options.url = args[++i];
        break;
      case '--libl':
        options.libl = args[++i];
        break;
      case '--curlib':
        options.curlib = args[++i];
        break;
      case '--debug':
        options.debug = true;
        break;
      case '--help':
      case '-h':
        options.help = true;
        break;
      // Run-batch options
      case '--program':
        options.program = args[++i];
        break;
      case '--program-lib':
        options.programLib = args[++i];
        break;
      case '--params':
        options.params = args[++i];
        break;
      case '--output-type':
        options.outputType = args[++i];
        break;
      // DB2 output
      case '--tables':
        options.tables = args[++i];
        break;
      case '--query':
        options.query = args[++i];
        break;
      case '--limit':
        options.limit = parseInt(args[++i], 10);
        break;
      // IFS output
      case '--ifs-path':
        options.ifsPath = args[++i];
        break;
      case '--ifs-lookup':
        options.ifsLookup = true;
        break;
      case '--lookup-lib':
        options.lookupLib = args[++i];
        break;
      case '--lookup-table':
        options.lookupTable = args[++i];
        break;
      case '--lookup-path-col':
        options.lookupPathCol = args[++i];
        break;
      case '--lookup-key':
        // Format: COL=value or COL=123 (for numbers)
        const keyArg = args[++i];
        const eqIdx = keyArg.indexOf('=');
        if (eqIdx > 0) {
          const col = keyArg.substring(0, eqIdx);
          let val = keyArg.substring(eqIdx + 1);
          // Try to parse as number if it looks like one
          if (/^-?\d+(\.\d+)?$/.test(val)) {
            val = parseFloat(val);
          }
          options.lookupKeys.push({ column: col, value: val });
        } else {
          console.error(`[ibmi-compile] Invalid --lookup-key format: ${keyArg} (expected COL=value)`);
          process.exit(2);
        }
        break;
      case '--lookup-order':
        options.lookupOrder = args[++i];
        break;
      // Spool output
      case '--spool-file':
        options.spoolFile = args[++i];
        break;
      default:
        if (arg.startsWith('-')) {
          console.error(`[ibmi-compile] Unknown option: ${arg}`);
          process.exit(2);
        }
        if (!options.sourceFile) {
          options.sourceFile = arg;
        } else {
          console.error(`[ibmi-compile] Unexpected argument: ${arg}`);
          process.exit(2);
        }
    }
    i++;
  }

  return options;
}

function showHelp() {
  const helpText = `
ibmi-compile.js - Compile and run RPG/RPGLE, SQLRPGLE, and CLLE programs on IBM i

COMMANDS:
  compile (default)   Compile source code to PGM or MODULE
  run-test            Compile and execute test program, capture stdout/stderr
  run-batch           Execute existing batch program, retrieve output

USAGE:
  node scripts/ibmi-compile.js <source-file> [options]           # compile
  node scripts/ibmi-compile.js run-test <source-file> [options]  # compile & run
  node scripts/ibmi-compile.js run-batch [options]               # run existing

COMPILE OPTIONS:
  --lib <library>     Target library (default: from config or DEVLIB)
  --obj <object>      Object name (default: derived from filename)
  --type <type>       Object type: PGM or MODULE (default: PGM)
  --mode <mode>       Compile mode: BNDRPG, SQLRPGLE, BNDCL (auto-detect)

RUN-BATCH OPTIONS:
  --program <name>          Program name to execute (required)
  --program-lib <library>   Program library (default: uses --lib)
  --params <p1,p2,...>      Program parameters (comma-separated)
  --output-type <type>      Output type: db2, ifs, spool (required)

  DB2 Output:
    --tables <spec>         Tables: LIB/TABLE or LIB/TABLE:alias (comma-sep)
    --query <sql>           Custom SQL query for single table
    --limit <n>             Max rows per table (default: 1000)

  IFS Output (direct path):
    --ifs-path <path>       IFS file path to read

  IFS Output (database lookup):
    --ifs-lookup            Enable database lookup mode
    --lookup-lib <lib>      Lookup table library
    --lookup-table <table>  Lookup table name
    --lookup-path-col <col> Column containing the IFS path
    --lookup-key <col=val>  Key column=value (repeatable for composite keys)
    --lookup-order <order>  ORDER BY clause (e.g., "CREATED_DATE DESC")

  Spool Output:
    --spool-file <name>     Spool file name pattern

COMMON OPTIONS:
  --url <url>         Compile service URL (default: from config)
  --libl <libs>       Library list (comma-separated)
  --curlib <lib>      Current library
  --debug             Save request/response JSON to tmp/
  --help              Show this help message

EXAMPLES:
  # Compile RPGLE program
  node scripts/ibmi-compile.js qrpglesrc/mypgm.rpgle --lib TESTLIB

  # Compile and run test program
  node scripts/ibmi-compile.js run-test qrpglesrc/test.rpgle --lib DEVLIB

  # Run batch with DB2 output (multiple tables)
  node scripts/ibmi-compile.js run-batch --program MYPGM --lib DEVLIB \\
    --output-type db2 --tables "DEVLIB/RESULTS,DEVLIB/LOG:logs"

  # Run batch with direct IFS path
  node scripts/ibmi-compile.js run-batch --program RPTPGM --lib DEVLIB \\
    --output-type ifs --ifs-path "/tmp/report.txt"

  # Run batch with IFS database lookup (single key)
  node scripts/ibmi-compile.js run-batch --program EDI856PGM --program-lib EDILIB \\
    --params "123456" --output-type ifs --ifs-lookup \\
    --lookup-lib EDITEST --lookup-table EDIDESADV856 \\
    --lookup-path-col FILE_PATH --lookup-key "PACKING_SLIP=123456" \\
    --lookup-order "CREATED_DATE DESC"

  # Run batch with IFS database lookup (composite key)
  node scripts/ibmi-compile.js run-batch --program EDI856PGM --program-lib EDILIB \\
    --output-type ifs --ifs-lookup \\
    --lookup-lib EDITEST --lookup-table EDIDESADV856 \\
    --lookup-path-col FILE_PATH \\
    --lookup-key "PACKING_SLIP=123456" --lookup-key "WAREHOUSE=WH01"

  # Run batch with spool output
  node scripts/ibmi-compile.js run-batch --program PRINTPGM --lib DEVLIB \\
    --output-type spool --spool-file QPRINT
`;
  console.log(helpText);
}

// -----------------------------------------------------------------------------
// Mode Detection and Object Name Derivation
// -----------------------------------------------------------------------------

function detectMode(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  switch (ext) {
    case '.sqlrpgle':
      return 'SQLRPGLE';
    case '.rpgle':
      return 'BNDRPG';
    case '.clle':
    case '.cl':
      return 'BNDCL';
    default:
      return 'BNDRPG';
  }
}

function deriveObjectName(filePath) {
  const basename = path.basename(filePath);
  const name = basename.replace(/\.[^.]+$/, ''); // Remove extension
  // Uppercase, replace invalid chars, truncate to 10
  const objName = name.toUpperCase().replace(/[^A-Z0-9_]/g, '_').substring(0, 10);
  return objName;
}

function getLanguageFromMode(mode) {
  switch (mode.toUpperCase()) {
    case 'SQLRPGLE':
      return 'SQLRPGLE';
    case 'BNDRPG':
    case 'RPGLE':
      return 'RPGLE';
    case 'BNDCL':
    case 'CLLE':
    case 'CL':
      return 'CLLE';
    default:
      return 'RPGLE';
  }
}

// -----------------------------------------------------------------------------
// HTTP Request
// -----------------------------------------------------------------------------

function makeRequest(url, payload) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const isHttps = urlObj.protocol === 'https:';
    const client = isHttps ? https : http;

    const body = JSON.stringify(payload);

    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port || (isHttps ? 443 : 80),
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body)
      }
    };

    const req = client.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        resolve({ statusCode: res.statusCode, body: data });
      });
    });

    req.on('error', (err) => {
      reject(err);
    });

    req.write(body);
    req.end();
  });
}

// -----------------------------------------------------------------------------
// Debug File Saving
// -----------------------------------------------------------------------------

function saveDebugFiles(prefix, objName, timestamp, request, response) {
  const tmpDir = path.join(process.cwd(), 'tmp');
  if (!fs.existsSync(tmpDir)) {
    fs.mkdirSync(tmpDir, { recursive: true });
  }

  const requestFile = path.join(tmpDir, `${prefix}-request-${objName}-${timestamp}.json`);
  const responseFile = path.join(tmpDir, `${prefix}-response-${objName}-${timestamp}.json`);

  fs.writeFileSync(requestFile, JSON.stringify(request, null, 2));
  console.log(`[ibmi-compile] Saved request: ${requestFile}`);

  if (response) {
    fs.writeFileSync(responseFile, JSON.stringify(response, null, 2));
    console.log(`[ibmi-compile] Saved response: ${responseFile}`);
  }
}

// -----------------------------------------------------------------------------
// Table Spec Parser
// -----------------------------------------------------------------------------

function parseTables(tablesSpec, defaultLimit) {
  // Format: LIB/TABLE or LIB/TABLE:alias (comma-separated)
  if (!tablesSpec) return [];

  return tablesSpec.split(',').map(spec => {
    spec = spec.trim();
    let alias = null;

    // Check for alias (LIB/TABLE:alias)
    const colonIdx = spec.indexOf(':');
    if (colonIdx > 0) {
      alias = spec.substring(colonIdx + 1);
      spec = spec.substring(0, colonIdx);
    }

    // Parse LIB/TABLE
    const slashIdx = spec.indexOf('/');
    if (slashIdx > 0) {
      const lib = spec.substring(0, slashIdx).toUpperCase();
      const table = spec.substring(slashIdx + 1).toUpperCase();
      const result = { library: lib, table: table };
      if (alias) result.alias = alias;
      if (defaultLimit) result.limit = defaultLimit;
      return result;
    } else {
      // Just table name, no library
      const result = { table: spec.toUpperCase() };
      if (alias) result.alias = alias;
      if (defaultLimit) result.limit = defaultLimit;
      return result;
    }
  });
}

// -----------------------------------------------------------------------------
// Build Run-Batch Request
// -----------------------------------------------------------------------------

function buildRunBatchRequest(options, config) {
  const lib = options.lib || config.defaultLibrary;
  const programLib = options.programLib || lib;

  const request = {
    program: {
      library: programLib.toUpperCase(),
      name: options.program.toUpperCase()
    },
    output: {
      type: options.outputType.toLowerCase()
    }
  };

  // Add program parameters if provided
  if (options.params) {
    request.program.params = options.params.split(',').map(p => p.trim());
  }

  // Add environment if library list or curlib specified
  const libl = options.libl ? options.libl.split(',').map(l => l.trim().toUpperCase()) : (config.libraryList || [lib]);
  request.env = { libl: libl };
  if (options.curlib) {
    request.env.curlib = options.curlib.toUpperCase();
  }

  // Configure output based on type
  switch (options.outputType.toLowerCase()) {
    case 'db2':
      request.output.tables = parseTables(options.tables, options.limit);
      if (options.query && request.output.tables.length === 1) {
        request.output.tables[0].query = options.query;
      }
      break;

    case 'ifs':
      if (options.ifsLookup) {
        // Database lookup mode
        request.output.source = 'db';
        request.output.lookup = {
          library: options.lookupLib.toUpperCase(),
          table: options.lookupTable.toUpperCase(),
          pathColumn: options.lookupPathCol.toUpperCase()
        };

        // Add keys (single key shorthand or composite keys array)
        if (options.lookupKeys.length === 1) {
          // Single key - use shorthand
          request.output.lookup.keyColumn = options.lookupKeys[0].column.toUpperCase();
          request.output.lookup.keyValue = options.lookupKeys[0].value;
        } else if (options.lookupKeys.length > 1) {
          // Composite key - use keys array
          request.output.lookup.keys = options.lookupKeys.map(k => ({
            column: k.column.toUpperCase(),
            value: k.value
          }));
        }

        // Add orderBy if specified
        if (options.lookupOrder) {
          request.output.lookup.orderBy = options.lookupOrder;
        }
      } else {
        // Direct path mode
        request.output.path = options.ifsPath;
      }
      break;

    case 'spool':
      request.output.file = options.spoolFile;
      break;
  }

  return request;
}

// -----------------------------------------------------------------------------
// Main
// -----------------------------------------------------------------------------

async function runCompile(options, config, endpoint) {
  // Validate source file for compile commands
  if (!options.sourceFile) {
    console.error('[ibmi-compile] Error: Missing source file path.');
    console.error(`Usage: node scripts/ibmi-compile.js ${options.command === 'run-test' ? 'run-test ' : ''}<source-file> [options]`);
    process.exit(2);
  }

  // Resolve source file path
  const sourceFile = path.resolve(options.sourceFile);
  if (!fs.existsSync(sourceFile)) {
    console.error(`[ibmi-compile] Error: Source file not found: ${sourceFile}`);
    process.exit(2);
  }

  // Merge options with config defaults
  const lib = options.lib || config.defaultLibrary;
  const obj = options.obj || deriveObjectName(sourceFile);
  const type = options.type || config.defaultObjectType || 'PGM';
  const mode = options.mode || detectMode(sourceFile);
  const url = options.url || config.serverUrl;
  const debug = options.debug || config.debugMode;
  const libl = options.libl ? options.libl.split(',').map(l => l.trim().toUpperCase()) : (config.libraryList || [lib]);
  const compileOptions = config.compileOptions || { replace: true, dbgview: '*SOURCE' };

  // Read source content
  const content = fs.readFileSync(sourceFile, 'utf8');
  const filename = path.basename(sourceFile);
  const extension = path.extname(sourceFile).substring(1).toLowerCase();
  const language = getLanguageFromMode(mode);

  // Build request payload
  const request = {
    mode: mode.toUpperCase(),
    output: {
      library: lib.toUpperCase(),
      objectName: obj.toUpperCase(),
      objectType: type.toUpperCase()
    },
    source: {
      kind: 'inline',
      filename: filename,
      extension: extension,
      language: language,
      memberType: language,
      content: content
    },
    env: {
      libl: libl
    },
    options: compileOptions
  };

  if (options.curlib) {
    request.env.curlib = options.curlib.toUpperCase();
  }

  const action = endpoint === '/run-test' ? 'Compiling & Running' : 'Compiling';
  console.log(`[ibmi-compile] ${action} ${filename} -> ${lib}/${obj} (${type}) [${mode}]`);
  console.log(`[ibmi-compile] Server: ${url}`);

  // Generate timestamp once for consistent request/response file naming
  const debugTimestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);
  const prefix = endpoint === '/run-test' ? 'run-test' : 'compile';

  // Save request if debug mode (before compile attempt)
  if (debug) {
    saveDebugFiles(prefix, obj, debugTimestamp, request, null);
  }

  try {
    const requestUrl = url.replace(/\/$/, '') + endpoint;
    const response = await makeRequest(requestUrl, request);

    let result;
    try {
      result = JSON.parse(response.body);
    } catch (e) {
      console.error(`[ibmi-compile] Error: Invalid JSON response from server`);
      console.error(response.body);
      process.exit(1);
    }

    // Save response if debug mode (using same timestamp as request for pairing)
    if (debug) {
      saveDebugFiles(prefix, obj, debugTimestamp, request, result);
    }

    if (response.statusCode !== 200) {
      console.error(`[ibmi-compile] HTTP ${response.statusCode} from compile service`);
      if (result.error) {
        console.error(`[ibmi-compile] Error: ${result.error}`);
      }
      if (result.artifacts?.joblog) {
        console.error('\n--- Job Log ---');
        console.error(result.artifacts.joblog);
      }
      process.exit(1);
    }

    // Handle run-test specific output
    if (endpoint === '/run-test') {
      if (result.success) {
        console.log(`[ibmi-compile] SUCCESS: Compiled and executed ${result.object}`);
        if (result.stdout) {
          console.log('\n--- Program Output (stdout) ---');
          console.log(result.stdout);
        }
        if (result.stderr) {
          console.log('\n--- Program Output (stderr) ---');
          console.log(result.stderr);
        }
        process.exit(0);
      } else {
        console.error(`[ibmi-compile] FAILED: ${result.error || 'Unknown error'}`);
        if (result.compiled === false) {
          console.error('[ibmi-compile] Compilation failed');
          if (result.analysis) {
            console.error(`[ibmi-compile] Severity: ${result.analysis.highestSeverity}, Errors: ${result.analysis.errors}, Warnings: ${result.analysis.warnings}`);
          }
        } else if (result.executed === false) {
          console.error('[ibmi-compile] Execution failed');
          if (result.exitCode !== undefined) {
            console.error(`[ibmi-compile] Exit code: ${result.exitCode}`);
          }
        }
        if (result.stdout) {
          console.error('\n--- Program Output (stdout) ---');
          console.error(result.stdout);
        }
        if (result.stderr) {
          console.error('\n--- Program Output (stderr) ---');
          console.error(result.stderr);
        }
        if (result.artifacts?.joblog) {
          console.error('\n--- Job Log ---');
          console.error(result.artifacts.joblog);
        }
        process.exit(1);
      }
    }

    // Handle compile response
    if (result.success) {
      console.log(`[ibmi-compile] SUCCESS: Created ${result.object} *${result.objectType}`);
      process.exit(0);
    } else {
      console.error(`[ibmi-compile] FAILED: ${result.error || 'Unknown error'}`);
      if (result.analysis) {
        console.error(`[ibmi-compile] Severity: ${result.analysis.highestSeverity}, Errors: ${result.analysis.errors}, Warnings: ${result.analysis.warnings}`);
      }
      if (result.artifacts?.joblog) {
        console.error('\n--- Job Log ---');
        console.error(result.artifacts.joblog);
      }
      process.exit(1);
    }
  } catch (err) {
    console.error(`[ibmi-compile] Error: ${err.message}`);
    process.exit(1);
  }
}

async function runBatch(options, config) {
  // Validate required options
  if (!options.program) {
    console.error('[ibmi-compile] Error: --program is required for run-batch');
    process.exit(2);
  }
  if (!options.outputType) {
    console.error('[ibmi-compile] Error: --output-type is required for run-batch');
    process.exit(2);
  }

  const validOutputTypes = ['db2', 'ifs', 'spool'];
  if (!validOutputTypes.includes(options.outputType.toLowerCase())) {
    console.error(`[ibmi-compile] Error: --output-type must be one of: ${validOutputTypes.join(', ')}`);
    process.exit(2);
  }

  // Validate output-specific requirements
  switch (options.outputType.toLowerCase()) {
    case 'db2':
      if (!options.tables) {
        console.error('[ibmi-compile] Error: --tables is required for db2 output type');
        process.exit(2);
      }
      break;
    case 'ifs':
      if (!options.ifsPath && !options.ifsLookup) {
        console.error('[ibmi-compile] Error: --ifs-path or --ifs-lookup is required for ifs output type');
        process.exit(2);
      }
      if (options.ifsLookup) {
        if (!options.lookupLib || !options.lookupTable || !options.lookupPathCol) {
          console.error('[ibmi-compile] Error: --lookup-lib, --lookup-table, and --lookup-path-col are required for IFS lookup mode');
          process.exit(2);
        }
        if (options.lookupKeys.length === 0) {
          console.error('[ibmi-compile] Error: At least one --lookup-key is required for IFS lookup mode');
          process.exit(2);
        }
      }
      break;
    case 'spool':
      if (!options.spoolFile) {
        console.error('[ibmi-compile] Error: --spool-file is required for spool output type');
        process.exit(2);
      }
      break;
  }

  const url = options.url || config.serverUrl;
  const debug = options.debug || config.debugMode;

  // Build request
  const request = buildRunBatchRequest(options, config);

  const programLib = options.programLib || options.lib || config.defaultLibrary;
  console.log(`[ibmi-compile] Running batch: ${programLib}/${options.program}`);
  if (options.params) {
    console.log(`[ibmi-compile] Parameters: ${options.params}`);
  }
  console.log(`[ibmi-compile] Output type: ${options.outputType}`);
  console.log(`[ibmi-compile] Server: ${url}`);

  // Generate timestamp
  const debugTimestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19);

  // Save request if debug mode
  if (debug) {
    saveDebugFiles('run-batch', options.program, debugTimestamp, request, null);
  }

  try {
    const requestUrl = url.replace(/\/$/, '') + '/run-batch';
    const response = await makeRequest(requestUrl, request);

    let result;
    try {
      result = JSON.parse(response.body);
    } catch (e) {
      console.error(`[ibmi-compile] Error: Invalid JSON response from server`);
      console.error(response.body);
      process.exit(1);
    }

    // Save response if debug mode
    if (debug) {
      saveDebugFiles('run-batch', options.program, debugTimestamp, request, result);
    }

    if (response.statusCode !== 200) {
      console.error(`[ibmi-compile] HTTP ${response.statusCode} from compile service`);
      if (result.error) {
        console.error(`[ibmi-compile] Error: ${result.error}`);
      }
      if (result.errorCode) {
        console.error(`[ibmi-compile] Error code: ${result.errorCode}`);
      }
      if (result.details) {
        console.error(`[ibmi-compile] Details: ${JSON.stringify(result.details)}`);
      }
      process.exit(1);
    }

    if (result.success) {
      console.log(`[ibmi-compile] SUCCESS: Executed ${result.program?.library}/${result.program?.name}`);

      // Display output based on type
      if (result.output) {
        switch (result.output.type) {
          case 'db2':
            console.log('\n--- DB2 Output ---');
            if (result.output.data) {
              for (const [tableName, rows] of Object.entries(result.output.data)) {
                const meta = result.output.metadata?.[tableName];
                console.log(`\nTable: ${tableName} (${rows.length} rows${meta?.fetchDurationMs ? `, ${meta.fetchDurationMs}ms` : ''})`);
                if (rows.length > 0) {
                  console.log(JSON.stringify(rows, null, 2));
                }
              }
            }
            break;

          case 'ifs':
            console.log('\n--- IFS Output ---');
            console.log(`Path: ${result.output.path}`);
            if (result.output.metadata) {
              console.log(`Size: ${result.output.metadata.size} bytes`);
              if (result.output.metadata.modified) {
                console.log(`Modified: ${result.output.metadata.modified}`);
              }
            }
            if (result.output.lookup) {
              console.log(`\nLookup: ${result.output.lookup.config?.library}/${result.output.lookup.config?.table}`);
              console.log(`Resolved path: ${result.output.lookup.resolvedPath}`);
            }
            console.log('\n--- Content ---');
            console.log(result.output.content);
            break;

          case 'spool':
            console.log('\n--- Spool Output ---');
            console.log(result.output.content);
            break;
        }
      }
      process.exit(0);
    } else {
      console.error(`[ibmi-compile] FAILED: ${result.error || 'Unknown error'}`);
      if (result.errorCode) {
        console.error(`[ibmi-compile] Error code: ${result.errorCode}`);
      }
      if (result.details) {
        console.error(`[ibmi-compile] Details: ${JSON.stringify(result.details)}`);
      }
      process.exit(1);
    }
  } catch (err) {
    console.error(`[ibmi-compile] Error: ${err.message}`);
    process.exit(1);
  }
}

async function main() {
  const args = process.argv.slice(2);
  const options = parseArgs(args);

  if (options.help) {
    showHelp();
    process.exit(0);
  }

  // Load configuration
  const config = loadConfig();

  // Dispatch to appropriate handler
  switch (options.command) {
    case 'run-batch':
      await runBatch(options, config);
      break;
    case 'run-test':
      await runCompile(options, config, '/run-test');
      break;
    case 'compile':
    default:
      await runCompile(options, config, '/compile');
      break;
  }
}

main();
