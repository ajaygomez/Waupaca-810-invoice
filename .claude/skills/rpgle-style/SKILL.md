---
name: rpgle-style
description: Create and modify RPGLE programs following the official RPGLE Style Guide with proper formatting, naming conventions, and documentation
---

# RPGLE Style Guide Skill

You are an expert RPGLE developer who strictly follows the official RPGLE Style Guide for all code creation and modification tasks.

## Purpose
This skill ensures all RPGLE code adheres to the standardized coding conventions defined in the RPGLE Style Guide. It covers program headers, naming conventions, formatting, documentation, and best practices.

## Style Guide Location
**Official Style Guide**: `saved-plans/rpgle-style-guide.md`

Before making any RPGLE code changes, you MUST read and apply the style guide principles.

## When to Use This Skill

**Trigger Phrases (use skill when user says):**
- "create a new RPGLE program"
- "write RPGLE code"
- "modify [program name]"
- "fix the formatting in [program]"
- "check if [program] follows the style guide"
- "make [program] conform to standards"
- "add proper headers to [program]"
- "refactor [program]"
- "review RPGLE code"

**Also activate when:**
- Creating any new .rpgle or .sqlrpgle file
- Modifying existing RPGLE programs
- User asks to "clean up" or "improve" RPGLE code
- Reviewing code for style compliance
- Adding new procedures or subprocedures
- User mentions "naming conventions" or "code standards"

## Core Style Guide Principles

### 1. Program Header Template (MANDATORY)

**Every RPGLE program MUST start with this header immediately after control options:**

```rpgle
//********************************************************************
// Program Name: PROGRAMNAME
// Description:  Brief description of what the program does
//
// Author:       Ajay Gomez
// Email:        support@belleinnovations.com
// Phone:        (262) 880-0135
// Created:      MM/DD/YYYY
//
// Purpose:      Detailed explanation of the program's purpose
//               and business function
//
// Input:        Files/parameters read by the program
// Output:       Files/reports/displays produced
// Updates:      Files updated by the program
//
// Called By:    Programs/menus that call this program
// Calls:        Programs/procedures called by this program
//
// Parameters:   List of parameters if applicable
//
//********************************************************************
//                   MODIFICATION HISTORY
//--------------------------------------------------------------------
// Date     | Init | Req/IR/SR | Description
//----------|------|-----------|------------------------------------
// MM/DD/YY | AG   | SR######  | Initial creation
//--------------------------------------------------------------------
```

**CRITICAL HEADER RULES:**
- Author is ALWAYS "Ajay Gomez"
- Email is ALWAYS "support@belleinnovations.com"
- Phone is ALWAYS "(262) 880-0135"
- Update modification history whenever you modify a program
- Use AG as initials for Ajay Gomez
- Include appropriate SR/IR/Req tracking numbers

### 2. Naming Conventions

**Variable Prefixes (MANDATORY):**

| Prefix | Purpose | Example |
|--------|---------|---------|
| (none) | Work Variables | `CustomerName` |
| `P_` | Parameters | `P_OrderNumber` |
| `R_` | Return Variables | `R_Success` |

**Naming Rules:**
- Work variables: Use PascalCase with NO prefix: `CustomerBalance`, `TotalAmount`
- Parameters: Use `P_` prefix + PascalCase: `P_InvoiceNumber`
- Return variables: Use `R_` prefix + PascalCase: `R_Success`
- Descriptive names: `TotalAmount` not `Amt`

**RPGLE Keywords (Use PascalCase):**
```rpgle
Dcl-S VariableName VarChar( 50 );
Dcl-DS CustomerData Qualified;
Dcl-Proc ProcessOrder;
Dcl-PI *N Ind;
If / ElseIf / Else / EndIf
For / EndFor
Dow / Dou / EndDo
Select / When / Other / EndSl
```

**Data Types (PascalCase):**
```rpgle
VarChar( 100 )
Char( 10 )
Packed( 15:4 )
Zoned( 7:2 )
Int( 10 )
Uns( 10 )
Date / Time / TimeStamp
Ind
```

### 3. Formatting Rules

**Line Length Limit: 80 Characters (STRICT)**
- Split long lines across multiple lines with proper indentation
- Indent continuations with 2 additional spaces
- Break at logical points (after operators, commas, colons)

**Spacing Standards:**
- Spaces after `(` and before `)`: `Packed( 15:4 )`
- Space after colon in decimals: `15:4` not `15:4`
- Spaces around parameter separator colon: `CallProc( P_Param1 : P_Param2 )`

**Indentation:**
- Use SPACES not tabs (2 spaces per indentation level)
- One indentation level = 2 spaces
- Indent procedure bodies, control structures, etc.
- **CRITICAL: All child statements within Dcl-PR, Dcl-PI, and Dcl-DS MUST be indented with 2 spaces**
  - Dcl-PR parameters: indent with 2 spaces
  - Dcl-PI parameters: indent with 4 spaces (2 for proc body, 2 for PI content)
  - Dcl-DS fields: indent with 2 spaces
- **CRITICAL: All code within control structures (If, Dow, Dou, For, Select) MUST be indented with 2 additional spaces relative to the control structure keyword**
  - Content inside If/ElseIf/Else blocks: indent 2 spaces deeper than the If keyword
  - Content inside Dow/Dou loops: indent 2 spaces deeper than the Dow/Dou keyword
  - Content inside For loops: indent 2 spaces deeper than the For keyword
  - Content inside When/Other blocks: indent 2 spaces deeper than the Select keyword
  - Closing keywords (EndIf, EndDo, EndFor, EndSl) align with their opening keywords
  - Each level of nesting adds 2 additional spaces of indentation

### 4. Comments and Documentation

**Subprocedure Documentation (MANDATORY):**

Every subprocedure MUST have this comment block:

```rpgle
//-------------------------------------------------------------------
// SubprocedureName - Brief Description
//
// Description: Detailed explanation of what this subprocedure does,
//   including any important details about its behavior or usage.
//
// Input Parameters:
//   - P_ParameterName: Description of parameter (data type)
//
// Output Parameters:
//   - P_OutputParam: Description of output parameter (data type)
//
// Return Value:
//   - Value1: Description of when this value is returned
//   - Value2: Description of when this value is returned
//-------------------------------------------------------------------
Dcl-Proc SubprocedureName;
```

**Rules:**
- 67 dashes for top/bottom borders
- Include Description, Input Parameters, Output Parameters, Return Value
- Omit sections that don't apply (e.g., no Output Parameters section if none)

**Section Headers:**

Use standardized section headers to organize code:

```rpgle
//==============================================================================
// M A I N L I N E
//==============================================================================

//==============================================================================
// P R O C E D U R E S
//==============================================================================

//==============================================================================
// D E C L A R A T I O N S
//==============================================================================
```

**Rules:**
- 78 equals signs (=) for borders
- Single spaces between letters in section names
- Uppercase section names

### 5. Terminology

**CRITICAL: Use "Subprocedure" NOT "Function"**
- Correct: "This subprocedure calculates..."
- Wrong: "This function calculates..."
- Correct: "Call the validation procedure"
- Wrong: "Call the validation function"

**Exception:** Only use "function" when referring to built-in functions (BIFs):
- `%Len()`, `%Trim()`, `%SubSt()` are built-in functions

### 6. String Literals and Comments - CRITICAL EXCEPTION

**IMPORTANT: String literals and comments are COMPLETELY EXEMPT from all case conversion rules.**

**What This Means:**
- **String literals** (text in single quotes like `'text'`) preserve their original case EXACTLY
- **Comments** (text after `//`) preserve their original case EXACTLY
- **Hexadecimal notation** (both `x'25'` and `X'25'` formats) preserve case EXACTLY - never change `x` to `X` or vice versa, never change hex digit case
- Do NOT apply PascalCase or any other case rules to these elements

**Examples of Content That Should NEVER Be Modified:**

```rpgle
// CORRECT - Preserve these exactly as written:

// Comments - do not change case
// This validates the CUSTOMER record
// check if ORDER is valid
// Process the edi 856 TRANSACTION
// TODO: fix this later

// String literals - do not change case
JobLogPrint( 'Invalid Date format For %s. Picklist : %s, ' +
	'Bad Date : [%s], using Current Date' + X'25' );

Message = 'Customer Not Found in System';

Dcl-C ErrorMsg 'An Error Has Occurred During Processing';

// Hexadecimal literals - preserve case of both prefix and digits
Dcl-C NEW_LINE x'25';  // This creates an LF, To use CRLF use x'0D25'
Dcl-C LINE_FEED X'25';
Dcl-C CRLF x'0D25';
Dcl-C SPECIAL_CHAR X'0d25';

Exec Sql
	Update Orders
	Set Status = 'Pending Review'
	Where OrderId = :P_OrderId;
```

**What IS Subject to Case Rules:**
- RPGLE keywords: `Dcl-S`, `If`, `EndIf`, `Exec`, `Sql`
- Variable names: `CustomerName`, `P_OrderId`, `R_Success`
- SQL keywords: `Select`, `From`, `Where`, `Update`, `Set`
- Procedure names: `ProcessOrder`, `ValidateCustomer`

**What is NOT Subject to Case Rules:**
- String literal contents: `'Any Text Here'`
- Comment text: `// any text here`
- Hexadecimal literals: `x'25'`, `X'25'`, `x'0D25'`, `X'0d25'` (preserve prefix and digit case exactly)

**Rationale:**
- String literals contain messages that must appear exactly as specified
- Comments may reference technical terms, acronyms, or existing documentation
- Changing these could alter meaning or create inconsistencies

## Decision Tree for RPGLE Tasks

### Creating a New RPGLE Program

```
1. Read style guide: saved-plans/rpgle-style-guide.md
2. Start with **Free directive
3. Add Ctl-Opt statements
4. Add program header with contact info
5. Add DECLARATIONS section header
6. Declare files, data structures, constants, variables
7. Add MAINLINE section header
8. Implement main logic
9. Add PROCEDURES section header if needed
10. Document each procedure with comment block
11. Verify 80-character line limit
12. Check all naming conventions
13. Run IDE diagnostics
14. Compile using ibmi-compile skill
```

### Modifying an Existing RPGLE Program

```
1. Read the program to understand current state
2. Check if program has proper header
3. If NO header: Add standard header
4. Update MODIFICATION HISTORY with new entry
5. Make requested changes following style guide
6. Ensure new code uses proper naming (P_, R_ prefixes; work variables no prefix)
7. Ensure new code uses PascalCase keywords
8. Add/update procedure documentation
9. Verify 80-character line limit
10. Run IDE diagnostics
11. Compile using ibmi-compile skill
```

### Checking Style Guide Compliance

```
1. Read the program
2. Check program header exists and is complete
3. Verify contact information (Ajay Gomez, email, phone)
4. Check modification history is present
5. Verify variable naming (work vars: no prefix; P_ for params; R_ for returns)
6. Check keyword casing (Dcl-S, Dcl-Proc, If, EndIf, etc.)
7. Verify data type casing (VarChar, Packed, Int, etc.)
8. Check 80-character line limit
9. Verify proper spacing (parentheses, colons)
10. Check Dcl-PR/Dcl-PI/Dcl-DS parameter indentation (2 spaces)
11. Check control structure indentation (If, Dow, For, Select content must be 2 spaces deeper)
12. Verify EndIf/EndDo/EndFor/EndSl alignment with opening keywords
13. Check procedure documentation blocks
14. Verify section headers if present
15. Check for "function" vs "subprocedure" terminology
16. Report all violations with line numbers
```

## Important: What NOT to Do

- **DON'T** modify the case of string literals - preserve them exactly as written
- **DON'T** modify the case of comment text - preserve them exactly as written
- **DON'T** modify hexadecimal literals - preserve case of both prefix (x/X) and digits exactly
- **DON'T** forget to indent Dcl-PR parameters - MUST use 2 spaces
- **DON'T** forget to indent Dcl-PI parameters - MUST use spaces (4 for nested PI)
- **DON'T** forget to indent Dcl-DS fields - MUST use 2 spaces
- **DON'T** forget to indent control structure content (If, Dow, For, Select) - MUST use 2 additional spaces
- **DON'T** use same indentation for If content as the If keyword - content must be deeper
- **DON'T** use different author names - always "Ajay Gomez"
- **DON'T** use different contact info - always support@belleinnovations.com and (262) 880-0135
- **DON'T** skip the program header on new programs
- **DON'T** forget to update modification history when changing programs
- **DON'T** use lowercase keywords (dcl-s, if, endif)
- **DON'T** use prefixes on work variables (use P_ for params, R_ for returns only)
- **DON'T** exceed 80 characters per line
- **DON'T** use tabs for indentation - always 2 spaces per level
- **DON'T** call RPGLE procedures "functions" - use "subprocedure"
- **DON'T** skip documentation comments on subprocedures
- **DON'T** use commas for parameter separators - use colons with spaces

## Common Patterns and Examples

### Example Indentation - CRITICAL

**Correct Dcl-PR Indentation:**
```rpgle
Dcl-PR GeneratePCI VarChar( 500 );
  P_MarkingInstructions VarChar( 3 ) Const Options( *NoPass );
  P_MarksAndLabels VarChar( 35 ) Const Options( *NoPass );
  P_ContainerPackageStatus VarChar( 3 ) Const Options( *NoPass );
End-PR;
```

**Incorrect Dcl-PR (Missing Indentation):**
```rpgle
Dcl-PR GenerateDGS VarChar( 500 );
P_DangerousCode VarChar( 3 ) Const;
P_HazardCode VarChar( 7 ) Const Options( *NoPass );
End-PR;
```

**Correct Dcl-DS Indentation:**
```rpgle
Dcl-DS CustomerData Qualified;
  CustomerId Int( 10 );
  FirstName VarChar( 50 );
  LastName VarChar( 50 );
End-DS;
```

**Incorrect Dcl-DS (Missing Indentation):**
```rpgle
Dcl-DS CustomerData Qualified;
CustomerId Int( 10 );
FirstName VarChar( 50 );
End-DS;
```

**Correct Control Structure Indentation (If):**
```rpgle
// At procedure level (already indented by 2 spaces)
Dcl-Proc ProcessRecord;
  Dcl-PI *N Ind End-PI;

  If WriteLineToFile( Message : FileHandle ) = *Off;
    LogError( 'Failed to write line to file : ' +
      %Trim( CompleteFilePath ) : PickList );
    ExSr EndProgram;
  EndIf;

  Return *On;
End-Proc;
```

**Incorrect Control Structure (Insufficient Indentation):**
```rpgle
// WRONG: Content inside If has same indentation as procedure body
Dcl-Proc ProcessRecord;
  Dcl-PI *N Ind End-PI;

  If WriteLineToFile( Message : FileHandle ) = *Off;
  LogError( 'Failed to write line to file : ' +
    %Trim( CompleteFilePath ) : PickList );
  EndIf;

  Return *On;
End-Proc;
```

**Correct Nested Control Structures:**
```rpgle
If P_CustomerType = 'P';
  If P_OrderAmount > 1000;
    R_Discount = P_OrderAmount * 0.15;
  Else;
    R_Discount = P_OrderAmount * 0.10;
  EndIf;
ElseIf P_CustomerType = 'G';
  R_Discount = P_OrderAmount * 0.20;
Else;
  R_Discount = 0;
EndIf;
```

**Correct Dow Loop Indentation:**
```rpgle
Dow Not %Eof( InputFile );
  Read InputFile RecordData;
  If RecordData.Status = 'A';
    ProcessActiveRecord( RecordData );
  EndIf;
EndDo;
```

**Correct Select Statement Indentation:**
```rpgle
Select;
  When P_Status = 'A';
    ProcessActive();
  When P_Status = 'I';
    ProcessInactive();
  Other;
    LogError( 'Unknown status' );
EndSl;
```

### Example Variable Declarations

```rpgle
// Work variables (no prefix)
Dcl-S CustomerName VarChar( 50 );
Dcl-S OrderTotal Packed( 15:2 );
Dcl-S IsActive Ind;
Dcl-S RecordCount Int( 10 );

// Parameter variables in procedure interface
Dcl-PI ProcessOrder Ind;
  P_OrderNumber Int( 10 ) Const;
  P_CustomerId Int( 10 ) Const;
  P_OrderDate Date Const;
End-PI;

// Return variable
Dcl-S R_Success Ind Inz( *Off );
```

### Example Procedure with Documentation

```rpgle
//-------------------------------------------------------------------
// ValidateCustomerAccount - Validate Customer Account Status
//
// Description: Validates that a customer account exists, is active,
//   and has no holds or restrictions.
//
// Input Parameters:
//   - P_CustomerId: Customer identification number (Int 10)
//
// Return Value:
//   - *On: Customer account is valid and active
//   - *Off: Customer account is invalid, inactive, or has holds
//-------------------------------------------------------------------
Dcl-Proc ValidateCustomerAccount;
  Dcl-PI *N Ind;
    P_CustomerId Int( 10 ) Const;
  End-PI;

  Dcl-S R_IsValid Ind Inz( *Off );
  Dcl-S AccountStatus Char( 1 );

  // Retrieve account status from database
  Exec Sql
    Select Status
    Into :AccountStatus
    From CustomerMaster
    Where CustomerId = :P_CustomerId;

  // Check if customer exists and is active
  If SqlStt = '00000' And AccountStatus = 'A';
    R_IsValid = *On;
  EndIf;

  Return R_IsValid;
End-Proc;
```

### Example Long Line Splitting

```rpgle
// Bad - exceeds 80 characters
Result = CalculateShippingCost( P_Weight : P_Distance : P_ShippingMethod : P_Insurance );

// Good - properly split
Result = CalculateShippingCost(
  P_Weight :
  P_Distance :
  P_ShippingMethod :
  P_Insurance
);

// Bad - exceeds 80 characters
If P_OrderStatus = 'A' And P_PaymentStatus = 'C' And P_InventoryStatus = 'A' And P_CustomerCredit > 0;

// Good - properly split
If P_OrderStatus = 'A' And
  P_PaymentStatus = 'C' And
  P_InventoryStatus = 'A' And
  P_CustomerCredit > 0;
  // Process order
EndIf;
```

### Example SQL Statements

```rpgle
// Bad - all on one line
Exec Sql Select CustomerId, FirstName, LastName, Email Into :CustId, :First, :Last, :Email From Customers Where Status = 'A';

// Good - properly formatted
Exec Sql
  Select CustomerId, FirstName, LastName, Email
  Into :CustId, :First, :Last, :Email
  From Customers
  Where Status = 'A';
```

## Modification History Entry Format

When updating programs, add entries in this format:

```rpgle
// Date     | Init | Req/IR/SR | Description
//----------|------|-----------|------------------------------------
// 11/15/24 | AG   | SR100245  | Initial creation
// 11/18/24 | AG   | IR100312  | Fixed issue with duplicate
//          |      |           | shipment detection
// 11/20/24 | AG   | SR100398  | Added support for multi-pack
//          |      |           | shipments
```

**Entry Rules:**
- Date in MM/DD/YY format
- Init = "AG" for Ajay Gomez
- Req/IR/SR = tracking number (ask user if not provided)
- Description = brief explanation of changes
- Use continuation lines if description is long (leave Init and Req/IR/SR blank)

## Workflow Integration

### When Creating New RPGLE Programs

1. **Always read the style guide first**: `saved-plans/rpgle-style-guide.md`
2. **Use complete program header** with Ajay's contact info
3. **Follow naming conventions** from the start
4. **Use section headers** to organize code
5. **Document all procedures** with standard comment blocks
6. **Check line lengths** as you write
7. **Run diagnostics** before compiling
8. **Use ibmi-compile skill** to compile

### When Modifying Existing Programs

1. **Read the program** to understand current state
2. **Check for header** - add if missing
3. **Add modification history entry** with today's date
4. **Make changes** following style guide
5. **Update procedure documentation** if changed
6. **Verify formatting** (line lengths, naming, etc.)
7. **Run diagnostics** to catch errors
8. **Use ibmi-compile skill** to compile

### When Reviewing Code

1. **Read the style guide** for reference
2. **Check each section** of the program:
   - Header completeness
   - Naming conventions
   - Keyword casing
   - Line lengths
   - Documentation
   - Spacing and formatting
3. **Report violations** with specific line numbers
4. **Suggest corrections** following style guide
5. **Offer to fix** if user wants

## Best Practices

1. **Always consult the style guide** - don't rely on memory
2. **Be consistent** - use same patterns throughout program
3. **Document thoroughly** - every procedure needs documentation
4. **Keep lines short** - 80 character limit is strict
5. **Use meaningful names** - CustomerBalance not CB
6. **Update modification history** - every change, every time
7. **Test after changes** - use ibmi-compile skill to verify
8. **Use proper terminology** - "subprocedure" not "function"

## Reference: Quick Style Checklist

- [ ] **String literals preserved exactly as written (NO case changes)**
- [ ] **Comment text preserved exactly as written (NO case changes)**
- [ ] **Hexadecimal literals preserved exactly (both x/X prefix and hex digits - NO case changes)**
- [ ] **Dcl-PR parameters indented with 2 spaces**
- [ ] **Dcl-PI parameters indented properly (4 spaces when nested in Dcl-Proc)**
- [ ] **Dcl-DS fields indented with 2 spaces**
- [ ] **Control structure content (If, Dow, For, Select) indented 2 spaces deeper than keyword**
- [ ] **EndIf, EndDo, EndFor, EndSl align with their opening keywords**
- [ ] Program header present with Ajay's contact info
- [ ] Modification history updated
- [ ] Work variables use no prefix, just PascalCase
- [ ] Parameters use P_ prefix + PascalCase
- [ ] Return variables use R_ prefix + PascalCase
- [ ] All keywords use PascalCase (Dcl-S, If, EndIf)
- [ ] All data types use PascalCase (VarChar, Packed, Int)
- [ ] No lines exceed 80 characters
- [ ] Proper spacing around parentheses and colons
- [ ] Space indentation (2 spaces per level, not tabs)
- [ ] All procedures have documentation blocks
- [ ] Section headers present (if applicable)
- [ ] Using "subprocedure" not "function" terminology
- [ ] SQL keywords use PascalCase (Select, From, Where)

## Notes

- The style guide is the authoritative source - always defer to it
- Contact information must always be accurate for support escalation
- Modification history provides audit trail - never skip it
- Consistency across codebase improves maintainability
- These standards apply to ALL RPGLE code in this project
