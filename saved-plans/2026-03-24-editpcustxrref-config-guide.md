# EDITPCUSTXRREF Configuration Guide — 810 & INVOIC Options

**Date:** 2026-03-24
**Context:** The `EDITEST.EDITPCUSTXRREF` table controls how each trading partner's invoices are generated. Each row maps a ship-to customer number to a set of options that determine the format, content, and structure of the outbound 810 (X12) or INVOIC (EDIFACT) document. This document explains every option a business analyst needs to understand when setting up or modifying a customer's invoice configuration.

---

## Master Switch

### SEND810INVOICE — Enable/Disable Invoice Generation
| Value | Meaning |
|---|---|
| **Y** | Invoices will be generated for this customer |
| **N** | Customer is completely skipped — no output produced |

This is the first thing to set. If N, nothing else in this table matters for this customer.

### SEND810TYPE — Document Format
| Value | Meaning | Program |
|---|---|---|
| **X12** | ANSI X12 810 Invoice format (US standard) | EDI810 |
| **EDIFACT** | UN/EDIFACT INVOIC format (international) | INVOICE |

Determines which program processes the customer and which document standard is used. Most domestic customers use X12. International customers (ZF, Cummins, Volvo) use EDIFACT.

---

## Invoice Header Options (X12 only)

### INV810TRANSTYPE — Transaction Type Code (BIG07)
Controls what type of invoice this is. Appears in the BIG segment (Beginning Segment for Invoice).

| Value | EDI Meaning | When to Use |
|---|---|---|
| **DI** | Debit Invoice (Original) | Standard first-time invoice — the most common setting |
| **DR** | Debit Invoice (Reissue) | Replacement invoice (e.g., Baldor Electric) |
| **CI** | Consolidated Invoice | Multiple shipments billed together (e.g., Hyster-Yale) |
| **CA** | Credit/Adjustment | Credit memo or price adjustment (e.g., Caterpillar SAP) |

**Default:** DI

### INV810SENDBIGPODT — Include PO Date in Invoice Header
| Value | Meaning |
|---|---|
| **Y** | Ship date is placed in BIG03 (Purchase Order Date) |
| **N** | BIG03 is left empty |

Most trading partners don't require this. **Default:** N

---

## Currency & Payment Terms (X12 only)

### INV810CURPARTYCODE — Currency Owner (CUR01)
Identifies whose currency is being stated on the invoice.

| Value | Meaning | Typical Use |
|---|---|---|
| **BY** | Buyer's currency | Most customers (JD, Ford, GM, Discovery) |
| **SE** | Seller's currency | Caterpillar locations, Baldor, Hyster-Yale |
| **SU** | Supplier's currency | Sauerdanfoss |
| **ZZ** | Mutually defined | Discovery Energy |

All invoices are in USD. This code tells the receiver's system which party "owns" the currency declaration. The trading partner's EDI spec will say which value they require. **Default:** BY

### INV810ITDTYPECODE — Payment Terms Type (ITD01)
| Value | Meaning |
|---|---|
| **05** | Discount not applicable — standard net terms |
| **14** | Special terms (used for extended net periods) |
| *(empty)* | Skip the ITD segment entirely |

### INV810ITDNETDAYS — Net Payment Days (ITD07)
| Value | Meaning |
|---|---|
| **30** | Payment due in 30 days |
| **60** | Payment due in 60 days |

### INV810ITDDISCPCT / INV810ITDDISCDAYS — Discount Terms
Currently unused by all customers. If populated (e.g., `2.00` and `10`), the invoice would show "2% discount if paid within 10 days, net 30."

---

## Line Item Options (X12 only)

### INV810IT1UOMCODE — Unit of Measure
| Value | Meaning | Typical Use |
|---|---|---|
| **EA** | Each | Most customers |
| **PC** | Piece | Caterpillar Mossville, Caterpillar Dyersburg |

The trading partner's spec determines which to use. Some ERP systems treat EA and PC identically. **Default:** EA

### INV810IT1LINENUMSTL — Line Numbering Style
| Value | Meaning |
|---|---|
| **S** | Sequential — lines numbered 1, 2, 3, 4... |
| **A** | Always 1 — every line gets number "1" |

Most trading partners expect sequential. Use "A" only if the partner's system ignores line numbers. **Default:** S

### INV810SENDPID — Include Part Description
| Value | Meaning |
|---|---|
| **Y** | Add a PID segment after each line item with the part description |
| **N** | No part description in the invoice |

**Default:** N. Enable if the trading partner needs human-readable descriptions on each line.

---

## Pricing & Surcharges

### INV810ADDSURCHARGE — Fold Surcharges into Unit Price
This is one of the most important settings. It controls whether material surcharge and energy surcharge are visible as separate charges or hidden in the per-piece price.

| Value | Unit Price Shows | Surcharge Appears As | Example (base $10 + $2 surcharge, 100 EA) |
|---|---|---|---|
| **Y** | Base + Surcharge + Energy combined | Nothing separate — absorbed into price | IT1: 100 EA @ $12.00 = $1,200. No SAC. |
| **N** | Base price only | Separate SAC segment at invoice summary | IT1: 100 EA @ $10.00 = $1,000. SAC H550 = $200. Total = $1,200. |

**When to use Y:** Trading partner wants an all-in price and doesn't need surcharge breakdowns (JD, Sauerdanfoss, Caterpillar Mossville, Baldor).

**When to use N:** Trading partner's system expects surcharges as separate line items or charges (Caterpillar Decatur, GM, Ford, Hyster-Yale, CNH).

**Default:** N

### INV810SACSURCHCODE — Surcharge SAC Code
Only used when ADDSURCHARGE = N. Controls the code in the SAC segment.

| Value | Meaning |
|---|---|
| **H550** | Charge type H (Handling), code 550 (Fuel/Energy) |

Format: First character = H (Handling charge) or R (Allowance). Next 3 = SAC industry code.

Currently all customers use H550. A different code could be used if a trading partner's spec requires it (e.g., `H750` for freight). **Default:** H550

---

## Dunnage (Packaging/Container Charges)

Dunnage refers to charges for returnable containers, skids, pallets, plywood dividers, and other packaging materials. These charges come from the EDIDUNN table.

### INV810DUNNSEGTYPE — How Dunnage Appears in the Invoice
| Value | Output Format | Description | Typical Use |
|---|---|---|---|
| **SAC** | `SAC*C*R060*...*[amount]` | Summary-level SAC charge segment | CNH, Bobcat, NACCO, Bolzoni, ZF, Volvo, Cummins |
| **ITA** | `ITA*A*S0050*...*[amount]` | Allowance/charge detail segment | Caterpillar US locations (Decatur, Mossville, etc.) |
| **IT1** | `IT1*[line]*[qty]*EA*[price]**RC*[code]` | Additional line items with RC qualifier | Caterpillar Dyersburg (2 customers) |
| **NONE** | *(nothing)* | No dunnage charges on the invoice at all | JD, Ford, GM, Discovery, Sauerdanfoss |

**How to choose:**
- Check the trading partner's 810 implementation guide. It will specify whether they accept SAC, ITA, IT1, or no dunnage.
- **SAC** is the most common for partners that accept dunnage charges.
- **ITA** is Caterpillar-specific (their EDI spec calls for ITA segments).
- **IT1** is rare — only use if the partner wants dunnage as regular line items.
- **NONE** means dunnage is billed separately (outside EDI) or not applicable.

**Default:** SAC

### INV810SACDUNNCODE — Dunnage SAC/ITA Code
| Value | Meaning |
|---|---|
| **R060** | Charge type R, code 060 (Container/Packaging) |

Used when DUNNSEGTYPE = SAC. All customers currently use R060. **Default:** R060

### INV810ITAAXCODE — ITA Allowance/Charge Code
| Value | Meaning |
|---|---|
| **S0050** | Special charge, code 0050 |

Used when DUNNSEGTYPE = ITA (Caterpillar style). **Default:** S0050

### INV810DUNNSACLINLVL — Dunnage at Line Level vs Summary
| Value | Meaning |
|---|---|
| **N** | Dunnage SAC/ITA segments appear once at the invoice summary level (after all line items) |
| **Y** | Dunnage segments appear after each individual line item |

Most partners expect summary-level. Use Y only if the partner's spec requires line-level dunnage allocation. **Default:** N

---

## Address Parties (N1 Loops)

### INV810N1PARTIES — Which Address Blocks to Include
Pipe-delimited list of party codes. Each code generates an N1/N3/N4 segment group with name and address.

| Code | Party | Address Source |
|---|---|---|
| **ST** | Ship-To | Customer address (CUSTADRS record type 2) |
| **SE** | Seller | Corporate headquarters |
| **SF** | Ship-From | Plant address (PLANTDSC) |
| **BT** | Bill-To | Customer billing address (CUSTADRS record type 1) |
| **BY** | Buyer | Same as BT |

| Common Configurations | Meaning |
|---|---|
| `ST\|SE` | Ship-to + Seller (most customers) |
| `ST\|SE\|SF` | Ship-to + Seller + Ship-from (Caterpillar Dyersburg) |

**Default:** `ST|SE`

---

## Reference Numbers (REF Segments)

REF segments carry reference numbers that help the trading partner match the invoice to other documents.

### INV810REFHDRQUALS — Header-Level References
Pipe-delimited list of REF qualifier codes placed in the invoice header (before line items).

| Code | Meaning | Value Source |
|---|---|---|
| **PK** | Packing Slip Number | EDIINVOIC810 packing slip |
| **VN** | Vendor Number | Could be added if partner needs it |

**Default:** `PK`

### INV810REFDETQUALS — Detail-Level References
Same format, but placed after each IT1 line item. Currently unused by all customers.

### INV810REFSUMQUALS — Summary-Level References
Same format, placed in the summary section (after all IT1s, before TDS). Only Caterpillar Dyersburg uses `PK` here.

---

## Envelope Overrides (ISA/UNB)

These override the default sender/recipient identifiers from the EDICUSTOMERVALUES table. Use when a specific ship-to customer needs different envelope addresses than the trading partner default.

| Column | Segment | Element | Purpose |
|---|---|---|---|
| **INV810SENDERQUAL** | ISA05 / UNB | Sender qualifier | e.g., `ZZ` (mutually defined), `01` (DUNS) |
| **INV810SENDERID** | ISA06 / UNB | Sender identification | e.g., `006133441` (Waupaca DUNS) |
| **INV810RECIPQUAL** | ISA07 / UNB | Receiver qualifier | Same codes as sender |
| **INV810RECIPID** | ISA08 / UNB | Receiver identification | Trading partner's ID |

If left blank, the values from EDICUSTOMERVALUES (the parent trading partner record) are used.

---

## EDIFACT-Specific Options

These apply only when SEND810TYPE = EDIFACT.

| Column | UNH Element | Purpose | Example Values |
|---|---|---|---|
| **EDIFACTMSGVERSION** | S009/0052 | Message version | `D` (Draft) |
| **EDIFACTMSGRELEASE** | S009/0054 | Message release | `97B`, `07A`, `03A` |
| **EDIFACTCTLAGENCY** | S009/0051 | Controlling agency | `UN` (United Nations) |
| **EDIFACTASSOCCODE** | S009/0057 | Association assigned code | `GAVA11` (German Auto VDA), `GMI012` (GM) |

**Note:** The INVOICE program currently overrides these based on customer type (ZF gets D/07A/UN/GAVA11, Volvo gets D/03A/UN, Standard Cummins gets D/97B/UN). The EDITPCX values are loaded first but then overwritten. A future improvement could remove the hardcoded overrides and use only the config table values.

---

## Current Customer Profiles (Summary)

| Trading Partner | Format | Trans Type | Surcharge | Dunnage | Notable |
|---|---|---|---|---|---|
| **J.D. Engine (SAP)** | X12 | DI | Folded in (Y) | None | Largest group (~9,800 ship-tos) |
| **Caterpillar (Decatur etc.)** | X12 | DI | Separate (N) | ITA | SE currency, ITA dunnage |
| **Caterpillar (Mossville)** | X12 | DI | Folded in (Y) | ITA | PC unit of measure |
| **Caterpillar (Dyersburg)** | X12 | — | Folded in (Y) | IT1 | Dunnage as line items, SF party, summary REF |
| **Caterpillar (MACH1 SAP)** | X12 | CA | Separate (N) | None | Credit/adjustment type |
| **Cummins** | EDIFACT | DI | Separate (N) | SAC | D:97B standard |
| **ZF (all plants)** | EDIFACT | DI | Separate (N) | SAC | D:07A + GAVA11 association |
| **Volvo/Mack** | EDIFACT | DI | Separate (N) | SAC | D:03A standard |
| **Baldor Electric** | X12 | DR | Folded in (Y) | SAC | Debit reissue type |
| **Hyster-Yale** | X12 | CI | Separate (N) | SAC | Consolidated invoice |
| **Ford** | X12 | DI | Separate (N) | None | No dunnage |
| **General Motors** | X12 | DI | Separate (N) | None | No dunnage |
| **Discovery Energy** | X12 | DI | Separate (N) | None | ZZ currency party code |
| **Sauerdanfoss** | X12 | DI | Folded in (Y) | None | SU currency party code |
| **World Class Industries** | X12 | DI | Folded in (Y) | SAC | Recently enabled (was NONE) |

---

## Setting Up a New Customer

1. **Get the trading partner's 810/INVOIC implementation guide** — this document specifies every option.
2. **Set SEND810INVOICE = Y** and **SEND810TYPE** to X12 or EDIFACT.
3. **Choose INV810TRANSTYPE** — almost always DI unless the partner spec says otherwise.
4. **Set INV810CURPARTYCODE** — look for "CUR segment" in their spec.
5. **Set INV810ADDSURCHARGE** — does their spec show surcharges in the unit price or as separate SAC segments?
6. **Set INV810DUNNSEGTYPE** — does their spec accept SAC, ITA, IT1, or no dunnage?
7. **Set INV810N1PARTIES** — which address loops does their spec require?
8. **Set payment terms** (ITDTYPECODE, ITDNETDAYS) per your contract.
9. **Set envelope IDs** (SENDERQUAL/ID, RECIPQUAL/ID) if this ship-to needs different values than the trading partner default.
10. **Test with INVSCAN** — run for a date with this customer's shipments and verify the output.
