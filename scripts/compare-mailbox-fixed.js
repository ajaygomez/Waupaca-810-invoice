#!/usr/bin/env node
/**
 * compare-mailbox-fixed.js
 *
 * Compares EDI mailbox data (EDI32DTAT.EDOTBX) against fixed-format IFS output files
 * for invoice records in EDITEST.EDIINVOIC810.
 *
 * Usage:
 *   node scripts/compare-mailbox-fixed.js
 *
 * Output:
 *   JSON to stdout and written to C:/Users/gomeza/tmp/comparison-results.json
 */

'use strict';

const http = require('http');
const { execSync } = require('child_process');
const fs = require('fs');

// ─── Configuration ────────────────────────────────────────────────────────────

const SQL_API_URL = 'http://as400:3000/api/compare/query';
const SQL_API_USER = 'gomeza';
const SQL_API_PASS = 'p@ckers9';
const SSH_USER = 'gomeza';
const SSH_HOST = 'as400';
const SSH_ASKPASS = 'C:/Users/gomeza/tmp/ssh_askpass.sh';
const OUTPUT_FILE = 'C:/Users/gomeza/tmp/comparison-results.json';

// ─── HTTP helper ──────────────────────────────────────────────────────────────

function sqlQuery(sql) {
  return new Promise((resolve, reject) => {
    const body = JSON.stringify({ sql, format: 'json' });
    const options = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
        'X-DB-User': SQL_API_USER,
        'X-DB-Pass': SQL_API_PASS,
      },
    };
    const req = http.request(SQL_API_URL, options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error('Failed to parse SQL response: ' + data.slice(0, 200)));
        }
      });
    });
    req.on('error', reject);
    req.write(body);
    req.end();
  });
}

// ─── SSH helper ───────────────────────────────────────────────────────────────

function readIfsFile(filePath) {
  try {
    const env = Object.assign({}, process.env, {
      SSH_ASKPASS: SSH_ASKPASS,
      SSH_ASKPASS_REQUIRE: 'force',
      DISPLAY: 'dummy',
    });
    const result = execSync(
      `ssh -o StrictHostKeyChecking=no -o BatchMode=no ${SSH_USER}@${SSH_HOST} "cat '${filePath}'"`,
      { env, encoding: 'utf8', timeout: 30000 }
    );
    return result;
  } catch (e) {
    return null;
  }
}

// ─── X12 IFS parser ───────────────────────────────────────────────────────────

function parseX12Ifs(content) {
  const lines = content.split('\n');
  const items = [];
  let invoiceTotal = null;
  let lineCount = null;
  let charges = 0;
  let currency = null;
  let uomList = [];

  for (const line of lines) {
    const seg = line.substring(0, 3).trim();

    if (seg === 'IT1') {
      // IT1 fixed-width: positions vary; parse by splitting on whitespace runs
      // Format: IT1<lineNum 5chars><qty 12chars><uom 6chars><price 10chars>...
      // But the exact positions aren't perfectly regular — split on spaces
      const rest = line.substring(3);
      // Remove leading whitespace for line number, then parse tokens
      const tokens = rest.trim().split(/\s+/);
      // tokens[0] = line number, tokens[1] = qty, tokens[2] = uom, tokens[3] = price
      const qty = parseFloat(tokens[1]) || 0;
      const uom = tokens[2] || '';
      const price = parseFloat(tokens[3]) || 0;
      items.push({ qty, uom, price });
      if (uom && !uomList.includes(uom)) uomList.push(uom);
    } else if (seg === 'TDS') {
      // TDS<value in integer cents>
      const val = line.substring(3).trim().replace(/\s+.*$/, '');
      invoiceTotal = parseInt(val, 10) / 100;
    } else if (seg === 'CTT') {
      const rest = line.substring(3).trim().split(/\s+/);
      lineCount = parseInt(rest[0], 10);
    } else if (seg === 'SAC') {
      // SAC<C|A><2chars code><...><amount> — amount is integer cents somewhere in line
      // SAC line: SACC = charge, SACA = allowance
      // Parse the amount — it appears after various fixed fields
      // Typical: SACC + 2-char type + ... then amount field
      // Use simple approach: find last numeric run in the line
      const matches = line.match(/(\d+)\s*$/);
      if (matches) {
        charges += parseInt(matches[1], 10) / 100;
      }
    } else if (seg === 'CUR') {
      // CURBYUSD or CURSEUSD — qualifier at positions 3-4
      currency = line.substring(3, 5).trim();
    }
  }

  const totalQty = items.reduce((s, i) => s + i.qty, 0);
  // For unit price: use the first item's price (or average if splitting)
  const unitPrice = items.length > 0 ? items[0].price : null;

  return {
    lineItemCount: items.length,
    totalQuantity: totalQty,
    unitPrice,
    invoiceTotal,
    charges,
    uom: uomList.length === 1 ? uomList[0] : (uomList.length > 1 ? uomList.join('/') : null),
    currency,
  };
}

// ─── X12 Mailbox parser ───────────────────────────────────────────────────────

function parseX12Mailbox(rows) {
  // Each row has DATA field (135-char fixed). Concatenate and split on EDI segment delimiters.
  // X12 uses * as element separator and ~ as segment terminator (but here newlines used)
  const lines = rows.map(r => (r.DATA || '').trimEnd());

  const items = [];
  let invoiceTotal = null;
  let lineCount = null;
  let charges = 0;
  let currency = null;
  let uomList = [];

  for (const line of lines) {
    if (!line.trim()) continue;
    const seg = line.substring(0, 2);

    if (seg === 'IT') {
      // IT1*<linenum>*<qty>*<uom>*<price>*<qualifier>*...
      const full = line;
      if (full.startsWith('IT1')) {
        const parts = full.split('*');
        // parts[0]=IT1, parts[1]=line#, parts[2]=qty, parts[3]=uom, parts[4]=price
        const qty = parseFloat(parts[2]) || 0;
        const uom = (parts[3] || '').trim();
        const price = parseFloat(parts[4]) || 0;
        items.push({ qty, uom, price });
        if (uom && !uomList.includes(uom)) uomList.push(uom);
      }
    } else if (line.startsWith('TDS')) {
      const parts = line.split('*');
      invoiceTotal = parseInt(parts[1], 10) / 100;
    } else if (line.startsWith('CTT')) {
      const parts = line.split('*');
      lineCount = parseInt(parts[1], 10);
    } else if (line.startsWith('SAC')) {
      const parts = line.split('*');
      // SAC*A/C*charge-code*...*amount
      if (parts[5]) {
        charges += parseInt(parts[5], 10) / 100;
      }
    } else if (line.startsWith('CUR')) {
      const parts = line.split('*');
      currency = (parts[1] || '').trim();
    }
  }

  const totalQty = items.reduce((s, i) => s + i.qty, 0);
  const unitPrice = items.length > 0 ? items[0].price : null;

  return {
    lineItemCount: items.length,
    totalQuantity: totalQty,
    unitPrice,
    invoiceTotal,
    charges,
    uom: uomList.length === 1 ? uomList[0] : (uomList.length > 1 ? uomList.join('/') : null),
    currency,
  };
}

// ─── EDIFACT IFS parser ───────────────────────────────────────────────────────

function parseEdifactIfs(content) {
  const lines = content.split('\n');
  const items = [];
  let invoiceTotal = null;
  let charges = 0;
  let uomList = [];
  let currentItem = null;
  let inAlc = false;
  let alcMoaSum = 0;

  for (const line of lines) {
    if (!line.trim()) continue;
    const seg = line.substring(0, 3).trim();

    if (seg === 'LIN') {
      if (currentItem) items.push(currentItem);
      currentItem = { qty: 0, uom: '', price: 0, moaLine: 0 };
      inAlc = false;
    } else if (seg === 'QTY') {
      // QTY<qualifier 2chars> <qty> <uom>
      // e.g. QTY12 36             EA
      const rest = line.substring(3);
      // qualifier is 2 chars after QTY
      const qualifier = rest.substring(0, 2).trim();
      if (qualifier === '12' || qualifier === '47') {
        // invoiced quantity
        const parts = rest.substring(2).trim().split(/\s+/);
        const qty = parseFloat(parts[0]) || 0;
        const uom = parts[1] || '';
        if (currentItem) {
          currentItem.qty = qty;
          currentItem.uom = uom;
        }
        if (uom && !uomList.includes(uom)) uomList.push(uom);
      }
    } else if (seg === 'PRI') {
      // PRIAAB47.35  or PRI+AAB:47.35
      const rest = line.substring(3);
      // Fixed: skip qualifier (3 chars AAB/AAA) then price
      const priceStr = rest.substring(3).trim().split(/\s+/)[0];
      const price = parseFloat(priceStr) || 0;
      if (currentItem) currentItem.price = price;
    } else if (seg === 'MOA') {
      // MOA<qualifier 2-3chars><spaces><value><spaces><currency>
      // e.g. MOA38 2048.40                            USD
      //      MOA79 1704.60
      const rest = line.substring(3);
      // Qualifier: up to first digit or space
      const qMatch = rest.match(/^(\d+)\s+([\d.]+)/);
      if (qMatch) {
        const qual = qMatch[1];
        const val = parseFloat(qMatch[2]);
        if (qual === '38' && currentItem) {
          currentItem.moaLine = val;
        } else if (qual === '77') {
          invoiceTotal = val;
        } else if (qual === '8' && inAlc) {
          // ALC-related charge amount
          alcMoaSum += val;
        }
      }
    } else if (seg === 'ALC') {
      inAlc = true;
    } else if (seg === 'UNT') {
      if (currentItem) {
        items.push(currentItem);
        currentItem = null;
      }
    }
  }

  if (currentItem) items.push(currentItem);
  charges = alcMoaSum;

  const totalQty = items.reduce((s, i) => s + i.qty, 0);
  const unitPrice = items.length > 0 ? items[0].price : null;

  return {
    lineItemCount: items.length,
    totalQuantity: totalQty,
    unitPrice,
    invoiceTotal,
    charges,
    uom: uomList.length === 1 ? uomList[0] : (uomList.length > 1 ? uomList.join('/') : null),
    currency: null, // Not separately tracked in EDIFACT IFS (embedded in MOA)
  };
}

// ─── EDIFACT Mailbox parser ───────────────────────────────────────────────────

function parseEdifactMailbox(rows) {
  // EDIFACT uses + : ' as delimiters. Each DATA row is 135-char fixed.
  // Reconstruct the full message by trimming trailing spaces and joining
  const raw = rows.map(r => (r.DATA || '').trimEnd()).join('');
  // Segments are terminated by '
  const segments = raw.split("'").map(s => s.trim()).filter(s => s.length > 0);

  const items = [];
  let invoiceTotal = null;
  let charges = 0;
  let uomList = [];
  let currentItem = null;
  let inAlc = false;
  let alcMoaSum = 0;
  let currency = null;

  for (const seg of segments) {
    const tag = seg.substring(0, 3);
    const rest = seg.substring(4); // skip tag and first +

    if (tag === 'LIN') {
      if (currentItem) items.push(currentItem);
      currentItem = { qty: 0, uom: '', price: 0, moaLine: 0 };
      inAlc = false;
    } else if (tag === 'QTY') {
      // QTY+47:36:PCE or QTY+12:36:PCE
      const parts = rest.split('+');
      const subParts = (parts[0] || rest).split(':');
      const qualifier = subParts[0];
      if (qualifier === '47' || qualifier === '12') {
        const qty = parseFloat(subParts[1]) || 0;
        const uom = subParts[2] || '';
        if (currentItem) {
          currentItem.qty = qty;
          currentItem.uom = uom;
        }
        if (uom && !uomList.includes(uom)) uomList.push(uom);
      }
    } else if (tag === 'PRI') {
      // PRI+AAB:47.35:::1:PCE or PRI+AAB:56.90:::1:PCE
      const parts = rest.split('+');
      const subParts = (parts[0] || rest).split(':');
      // subParts[0] = qualifier (AAB/AAA), subParts[1] = price
      const price = parseFloat(subParts[1]) || 0;
      if (currentItem) currentItem.price = price;
    } else if (tag === 'MOA') {
      // MOA+38:2048.40:USD or MOA+77:2048.40:USD:4
      const parts = rest.split('+');
      const subParts = (parts[0] || rest).split(':');
      const qual = subParts[0];
      const val = parseFloat(subParts[1]);
      const cur = subParts[2] || null;
      if (cur && !currency) currency = cur;
      if (qual === '38' && currentItem) {
        currentItem.moaLine = val;
      } else if (qual === '77') {
        invoiceTotal = val;
      } else if (qual === '8' && inAlc) {
        alcMoaSum += val;
      }
    } else if (tag === 'ALC') {
      inAlc = true;
    } else if (tag === 'UNT') {
      if (currentItem) {
        items.push(currentItem);
        currentItem = null;
      }
    }
  }

  if (currentItem) items.push(currentItem);
  charges = alcMoaSum;

  const totalQty = items.reduce((s, i) => s + i.qty, 0);
  const unitPrice = items.length > 0 ? items[0].price : null;

  return {
    lineItemCount: items.length,
    totalQuantity: totalQty,
    unitPrice,
    invoiceTotal,
    charges,
    uom: uomList.length === 1 ? uomList[0] : (uomList.length > 1 ? uomList.join('/') : null),
    currency,
  };
}

// ─── Comparison logic ─────────────────────────────────────────────────────────

function round2(n) {
  if (n === null || n === undefined) return null;
  return Math.round(n * 100) / 100;
}

function compareValues(mailboxVal, ifsVal, label, differences) {
  const mRounded = round2(mailboxVal);
  const iRounded = round2(ifsVal);
  const match = mRounded !== null && iRounded !== null
    ? Math.abs(mRounded - iRounded) < 0.005
    : String(mailboxVal) === String(ifsVal);
  if (!match) {
    differences.push(`${label}: ${mailboxVal} in mailbox → ${ifsVal} in IFS`);
  }
  return { mailbox: mailboxVal, ifs: ifsVal, match };
}

function compareStrings(mailboxVal, ifsVal, label, differences) {
  const match = (mailboxVal || '').trim() === (ifsVal || '').trim();
  if (!match) {
    differences.push(`${label}: ${mailboxVal} in mailbox → ${ifsVal} in IFS`);
  }
  return { mailbox: mailboxVal, ifs: ifsVal, match };
}

function buildComparison(mbox, ifs_, isX12) {
  const differences = [];

  const lineItemCount = {
    mailbox: mbox.lineItemCount,
    ifs: ifs_.lineItemCount,
    match: mbox.lineItemCount === ifs_.lineItemCount,
  };
  if (!lineItemCount.match) {
    differences.push(
      `Line items: ${mbox.lineItemCount} in mailbox → ${ifs_.lineItemCount} in IFS` +
      (ifs_.lineItemCount > mbox.lineItemCount ? ' (pallet splitting?)' : '')
    );
  }

  const totalQuantity = compareValues(mbox.totalQuantity, ifs_.totalQuantity, 'Total quantity', differences);
  const unitPrice = compareValues(mbox.unitPrice, ifs_.unitPrice, 'Unit price', differences);
  const invoiceTotal = compareValues(mbox.invoiceTotal, ifs_.invoiceTotal, 'Invoice total', differences);
  const charges = compareValues(mbox.charges, ifs_.charges, 'Charges', differences);
  const uom = compareStrings(mbox.uom, ifs_.uom, 'UOM', differences);

  const comparison = {
    lineItemCount,
    totalQuantity,
    unitPrice,
    invoiceTotal,
    charges,
    uom,
  };

  if (isX12) {
    const currency = compareStrings(mbox.currency, ifs_.currency, 'Currency qualifier', differences);
    comparison.currency = currency;
  }

  return { comparison, differences };
}

// ─── Mailbox SQL builders ─────────────────────────────────────────────────────

function buildX12MailboxSql(packSlip) {
  // Use delimiter-bounded matching (*PS* or *PS followed by space) to prevent
  // false positives from control numbers (e.g. ST*810*8230007 matching PS 230007)
  return `SELECT Cast(A.OTBOX As Char(10) CCSID 37) AS MBOX, Cast(A.OTDTA As Char(135) CCSID 37) AS DATA ` +
    `FROM EDI32DTAT.EDOTBX A ` +
    `WHERE Cast(A.OTBOX As Char(10) CCSID 37) = (` +
      `SELECT Max(Cast(B.OTBOX As Char(10) CCSID 37)) ` +
      `FROM EDI32DTAT.EDOTBX B ` +
      `WHERE (Cast(B.OTDTA As Char(135) CCSID 37) LIKE '%*${packSlip}*%'` +
        ` OR Cast(B.OTDTA As Char(135) CCSID 37) LIKE '%*${packSlip} %')` +
        ` AND Exists (` +
          `SELECT 1 FROM EDI32DTAT.EDOTBX C ` +
          `WHERE C.OTBOX = B.OTBOX ` +
            `AND Cast(C.OTDTA As Char(135) CCSID 37) LIKE '%ST*810*%'` +
        `)` +
    `) ORDER BY 1`;
}

function buildEdifactMailboxSql(packSlip) {
  // Use ':' prefix to match PS in EDIFACT component fields (e.g. RFF+ON:230007)
  // and prevent false positives from UNH/UNT references (which use '+' separators)
  return `SELECT Cast(A.OTBOX As Char(10) CCSID 37) AS MBOX, Cast(A.OTDTA As Char(135) CCSID 37) AS DATA ` +
    `FROM EDI32DTAT.EDOTBX A ` +
    `WHERE Cast(A.OTBOX As Char(10) CCSID 37) = (` +
      `SELECT Max(Cast(B.OTBOX As Char(10) CCSID 37)) ` +
      `FROM EDI32DTAT.EDOTBX B ` +
      `WHERE Cast(B.OTDTA As Char(135) CCSID 37) LIKE '%:${packSlip}%'` +
        ` AND Exists (` +
          `SELECT 1 FROM EDI32DTAT.EDOTBX C ` +
          `WHERE C.OTBOX = B.OTBOX ` +
            `AND Cast(C.OTDTA As Char(135) CCSID 37) LIKE '%UNH+%'` +
            `AND Cast(C.OTDTA As Char(135) CCSID 37) LIKE '%INVOIC%'` +
        `)` +
    `) ORDER BY 1`;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  // 1. Fetch all processed records
  console.error('[1/3] Fetching processed records from EDITEST.EDIINVOIC810...');
  const recordsSql = `SELECT ID, PACKING_SLIP, CUSTOMER_NUMBER, INVOICE_NUMBER, X12EDIFACT, FILE_PATH ` +
    `FROM EDITEST.EDIINVOIC810 ` +
    `WHERE PROCESSED_FLAG = 'Y' ` +
    `ORDER BY X12EDIFACT, ID`;

  const recordsResp = await sqlQuery(recordsSql);
  const records = recordsResp.data || [];
  console.error(`    Found ${records.length} records.`);

  const results = [];
  let ifsFilesFound = 0;
  let mailboxFound = 0;
  let totalMatchCount = 0;
  let totalDiffCount = 0;

  // 2. Process each record
  console.error('[2/3] Processing each record...');
  for (let i = 0; i < records.length; i++) {
    const rec = records[i];
    const id = rec.ID;
    const packingSlip = (rec.PACKING_SLIP || '').trim();
    const customer = (rec.CUSTOMER_NUMBER || '').trim();
    const invoiceNumber = (rec.INVOICE_NUMBER || '').trim();
    const type = (rec.X12EDIFACT || '').trim();
    const filePath = (rec.FILE_PATH || '').trim();
    const isX12 = type === 'X12';

    console.error(`    [${i + 1}/${records.length}] PS=${packingSlip} Cust=${customer} Type=${type}`);

    const result = {
      id,
      packingSlip,
      customer,
      invoiceNumber,
      type,
      filePath,
      mailboxNum: null,
      mailboxFound: false,
      ifsFileFound: false,
      comparison: null,
      differences: [],
      errors: [],
    };

    // Read IFS file
    let ifsContent = null;
    if (filePath) {
      console.error(`        Reading IFS file: ${filePath}`);
      ifsContent = readIfsFile(filePath);
      if (ifsContent) {
        ifsFilesFound++;
        result.ifsFileFound = true;
      } else {
        result.errors.push('IFS file not found or unreadable');
        console.error(`        IFS file not found`);
      }
    } else {
      result.errors.push('No FILE_PATH in record');
    }

    // Fetch mailbox data
    let mailboxRows = [];
    let mailboxNum = null;
    try {
      const mboxSql = isX12
        ? buildX12MailboxSql(packingSlip)
        : buildEdifactMailboxSql(packingSlip);
      const mboxResp = await sqlQuery(mboxSql);
      mailboxRows = mboxResp.data || [];
      if (mailboxRows.length > 0) {
        mailboxNum = (mailboxRows[0].MBOX || '').trim();
        result.mailboxNum = mailboxNum;
        result.mailboxFound = true;
        mailboxFound++;
        console.error(`        Mailbox: ${mailboxNum} (${mailboxRows.length} rows)`);
      } else {
        result.errors.push('Mailbox not found for packing slip');
        console.error(`        Mailbox not found`);
      }
    } catch (e) {
      result.errors.push('Mailbox query error: ' + e.message);
      console.error(`        Mailbox query error: ${e.message}`);
    }

    // Parse and compare
    if (ifsContent && mailboxRows.length > 0) {
      try {
        const ifsParsed = isX12
          ? parseX12Ifs(ifsContent)
          : parseEdifactIfs(ifsContent);

        const mboxParsed = isX12
          ? parseX12Mailbox(mailboxRows)
          : parseEdifactMailbox(mailboxRows);

        const { comparison, differences } = buildComparison(mboxParsed, ifsParsed, isX12);
        result.comparison = comparison;
        result.differences = differences;

        const hasMatch = differences.length === 0;
        if (hasMatch) {
          totalMatchCount++;
        } else {
          totalDiffCount++;
        }
      } catch (e) {
        result.errors.push('Parse/compare error: ' + e.message);
        console.error(`        Parse error: ${e.message}`);
      }
    } else if (!ifsContent && mailboxRows.length > 0) {
      // Still count as diff
      totalDiffCount++;
    } else if (ifsContent && mailboxRows.length === 0) {
      totalDiffCount++;
    }

    results.push(result);

    // Small pause to avoid overwhelming the server
    await new Promise(r => setTimeout(r, 100));
  }

  // 3. Build output
  console.error('[3/3] Building output...');
  const output = {
    records: results,
    summary: {
      totalRecords: records.length,
      ifsFilesFound,
      mailboxFound,
      totalMatchCount,
      totalDiffCount,
    },
  };

  const jsonOutput = JSON.stringify(output, null, 2);

  // Write to file
  fs.writeFileSync(OUTPUT_FILE, jsonOutput, 'utf8');
  console.error(`Results written to ${OUTPUT_FILE}`);

  // Print to stdout
  process.stdout.write(jsonOutput + '\n');
}

main().catch(err => {
  console.error('FATAL:', err.message);
  process.exit(1);
});
