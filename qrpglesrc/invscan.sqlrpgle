**FREE
Ctl-Opt DftActGrp( *No ) ActGrp( *Caller )
  Option( *SrcStmt:*NoDebugIo );

//********************************************************************
// Program Name: INVSCAN
// Description:  Scan mailbox for invoices and generate fixed files
//
// Author:       Ajay Gomez
// Email:        support@belleinnovations.com
// Phone:        (262) 880-0135
// Created:      03/16/2026
//
// Purpose:      Searches the EDI mailbox (EDI32DTAT.EDOTBX) for
//               X12 810 and EDIFACT INVOIC documents transmitted
//               on a target date, then calls INVDRIVER to generate
//               fixed-format output files via INVOICE/EDI810.
//
//               Bridges the legacy mailbox system (EDI027/031/041)
//               with the new fixed-file generation system.
//
// Input:        WFLIB.EDIMSTR - EDI master (transmission date)
//               EDI32DTAT.EDOTBX - EDI mailbox (doc type detect)
//               WFLIB.IVCHDR/IVCHDRH - Invoice number lookup
//               EDITEST.EDIINVOIC810 - Deduplication check
//
// Output:       Calls INVDRIVER which creates IFS output files
//               in /edidev/OUTBOUND/INVOICE/
//
// Updates:      EDIINVOIC810 (via INVDRIVER) - inserts new rows
//               EDITEST.ERRLOG - error/info logging
//
// Called By:    Job scheduler or manual batch submission
//
// Calls:        INVDRIVER - Invoice driver CL program
//
// Parameters:   InDate - YYYYMMDD date or blanks for yesterday
//
// Library List: WFLIB (*FIRST), WFDTA, EDITEST, AGLIB
//               (Same as INVTEST - needed for INVOICE/EDI810)
//
//********************************************************************
//                   MODIFICATION HISTORY
//--------------------------------------------------------------------
// Date     | Init | Req/IR/SR | Description
//----------|------|-----------|------------------------------------
// 03/16/26 | AG   | New       | Initial creation
//--------------------------------------------------------------------

//==============================================================================
// D E C L A R A T I O N S
//==============================================================================

Exec Sql Set Option Commit = *None,
  ClosQlCsr = *EndMod;

// INVDRIVER prototype (qualified to EDITEST)
Dcl-Pr CallInvDriver
  ExtPgm( 'EDITEST/INVDRIVER' );
  P_PackSlip Char( 6 );
  P_CustNum Char( 6 );
  P_InvNum Char( 7 );
  P_InvType Char( 2 );
End-Pr;

// Direct program calls for reprocessing (qualified to EDITEST)
Dcl-Pr CallInvoice ExtPgm( 'EDITEST/INVOICE' );
End-Pr;
Dcl-Pr CallEdi810 ExtPgm( 'EDITEST/EDI810' );
End-Pr;

// QCMDEXC for library list management
Dcl-Pr CallCmd ExtPgm( 'QCMDEXC' );
  P_Cmd Char( 2500 );
  P_CmdLen Packed( 15:5 );
End-Pr;

// Program interface
Dcl-Pi INVSCAN;
  InDate Char( 8 );
End-Pi;

// Constants
Dcl-C PGM_NAME 'INVSCAN';

// Date handling
Dcl-S TargetDate Date;
Dcl-S TargetYYMMDD Packed( 6:0 );
Dcl-S TargetDateStr Char( 8 );

// EDIMSTR cursor fields
Dcl-S CustNum Packed( 5:0 );
Dcl-S BillNum Packed( 8:0 );
Dcl-S PackSlip Packed( 6:0 );
Dcl-S InvDate Packed( 6:0 );
Dcl-S SupplierNum Packed( 4:0 );

// Mailbox lookup
Dcl-S MailboxNum Char( 10 );
Dcl-S MailboxInd Int( 5 );
Dcl-S DocType Char( 3 );
Dcl-S PackSlipStr Char( 8 );
Dcl-S PackSlipPattern Char( 20 );

// Invoice number from IVCHDR/IVCHDRH
Dcl-S InvoiceNum Packed( 6:0 );

// Duplicate check
Dcl-S DupDone Int( 10 );
Dcl-S DupPending Int( 10 );
Dcl-S ReprocessCnt Int( 10 ) Inz( 0 );

// INVDRIVER parameter values
Dcl-S ParmPackSlip Char( 6 );
Dcl-S ParmCustNum Char( 6 );
Dcl-S ParmInvNum Char( 7 );
Dcl-S ParmInvType Char( 2 );

// Counters
Dcl-S ProcessedCnt Int( 10 ) Inz( 0 );
Dcl-S SkipDupCnt Int( 10 ) Inz( 0 );
Dcl-S SkipNoMboxCnt Int( 10 ) Inz( 0 );
Dcl-S SkipNoInvCnt Int( 10 ) Inz( 0 );
Dcl-S ErrorCnt Int( 10 ) Inz( 0 );
Dcl-S TotalRows Int( 10 ) Inz( 0 );

// Logging
Dcl-S LogKeyField VarChar( 256 );
Dcl-S LogMessage VarChar( 500 );

// Library list management
Dcl-S CmdString Char( 2500 );
Dcl-S CmdLength Packed( 15:5 );

//==============================================================================
// M A I N L I N E
//==============================================================================

// Setup library list (same as INVTEST)
ExSr SetupLibList;

// Determine target date
ExSr DetermineDate;

// Log start
LogKeyField = TargetDateStr;
LogMessage = 'INVSCAN starting for date '
  + TargetDateStr + ' (EDI019='
  + %Char( TargetYYMMDD ) + ')';
ExSr LogInfo;

// Open cursor on EDIMSTR for target date
Exec Sql
  Declare EdimstrCur Cursor For
    Select EDI001, EDI002, EDI017,
           EDI018, EDI026
    From WFLIB.EDIMSTR
    Where EDI019 = :TargetYYMMDD
      And EDI019 <> 0
    Order By EDI017;

Exec Sql Open EdimstrCur;

If SqlState <> '00000';
  LogKeyField = TargetDateStr;
  LogMessage =
    'Error opening EDIMSTR cursor: '
    + SqlState;
  ExSr LogError;
  ExSr EndProgram;
EndIf;

// Process each EDIMSTR record
Dow '1' = '1';
  Exec Sql
    Fetch Next From EdimstrCur
    Into :CustNum, :BillNum, :PackSlip,
         :InvDate, :SupplierNum;

  If SqlState = '02000';
    Leave;
  EndIf;

  If SqlState <> '00000';
    LogKeyField = TargetDateStr;
    LogMessage = 'Error fetching EDIMSTR: '
      + SqlState;
    ExSr LogError;
    Leave;
  EndIf;

  TotalRows += 1;

  // Build search pattern for mailbox
  PackSlipStr = %Char( PackSlip );
  PackSlipPattern =
    '%' + %Trim( PackSlipStr ) + '%';

  // Search mailbox and detect type
  ExSr FindInMailbox;

  If DocType = *Blanks;
    SkipNoMboxCnt += 1;
    Iter;
  EndIf;

  // Look up invoice number
  ExSr LookupInvoiceNum;

  If InvoiceNum = 0;
    SkipNoInvCnt += 1;
    Iter;
  EndIf;

  // Check existing records in EDIINVOIC810
  ExSr CheckExisting;

  // Already processed successfully - skip
  If DupDone > 0;
    SkipDupCnt += 1;
    Iter;
  EndIf;

  // Pending (N or I) - reprocess directly
  If DupPending > 0;
    ExSr ReprocessInvoice;
    Iter;
  EndIf;

  // New - call INVDRIVER to insert + process
  ExSr CallDriver;

EndDo;

Exec Sql Close EdimstrCur;

// Log summary
LogKeyField = TargetDateStr;
LogMessage = 'INVSCAN complete: '
  + %Char( ProcessedCnt ) + ' new, '
  + %Char( ReprocessCnt ) + ' reprocessed, '
  + %Char( SkipDupCnt ) + ' already done, '
  + %Char( SkipNoMboxCnt )
  + ' no inv in mbox, '
  + %Char( SkipNoInvCnt )
  + ' no inv hdr, '
  + %Char( ErrorCnt ) + ' errors '
  + '(of ' + %Char( TotalRows )
  + ' EDIMSTR rows)';
ExSr LogInfo;

ExSr EndProgram;

//==============================================================================
// S U B R O U T I N E S
//==============================================================================

//------------------------------------------------------------
// SetupLibList - Add required libraries
//   WFLIB *FIRST - production data files
//   WFDTA - additional data files
//   EDITEST - EDI test (EDIINVOIC810, INVDRIVER)
//   AGLIB - development (compiled programs)
//------------------------------------------------------------
BegSr SetupLibList;

  CmdString =
    'ADDLIBLE LIB(WFLIB) POSITION(*FIRST)';
  CmdLength = %Len( %Trim( CmdString ) );
  Monitor;
    CallCmd( CmdString : CmdLength );
  On-Error;
    // Already in library list - OK
  EndMon;

  CmdString = 'ADDLIBLE LIB(WFDTA)';
  CmdLength = %Len( %Trim( CmdString ) );
  Monitor;
    CallCmd( CmdString : CmdLength );
  On-Error;
  EndMon;

  CmdString = 'ADDLIBLE LIB(EDITEST)';
  CmdLength = %Len( %Trim( CmdString ) );
  Monitor;
    CallCmd( CmdString : CmdLength );
  On-Error;
  EndMon;

EndSr;

//------------------------------------------------------------
// DetermineDate - Parse input date or use yesterday
//------------------------------------------------------------
BegSr DetermineDate;

  If InDate = *Blanks Or InDate = '00000000';
    TargetDate = %Date() - %Days( 1 );
  Else;
    Monitor;
      TargetDate = %Date( InDate : *ISO0 );
    On-Error;
      LogKeyField = InDate;
      LogMessage =
        'Invalid date parameter: ' + InDate;
      ExSr LogError;
      ExSr EndProgram;
    EndMon;
  EndIf;

  // Convert to YYMMDD for EDI019 comparison
  TargetYYMMDD =
    ( %SubDt( TargetDate : *Years ) - 2000 )
      * 10000
    + %SubDt( TargetDate : *Months ) * 100
    + %SubDt( TargetDate : *Days );

  TargetDateStr = %Char( TargetDate : *ISO0 );

EndSr;

//------------------------------------------------------------
// FindInMailbox - Search mailbox for INVOIC/810
//------------------------------------------------------------
BegSr FindInMailbox;

  DocType = *Blanks;
  MailboxNum = *Blanks;

  // Try EDIFACT INVOIC first
  MailboxInd = 0;
  Exec Sql
    Select
      Max( Cast( A.OTBOX
        As Char( 10 ) CCSID 37 ) )
    Into :MailboxNum :MailboxInd
    From EDI32DTAT.EDOTBX A
    Where Cast( A.OTDTA
      As Char( 135 ) CCSID 37 )
      Like :PackSlipPattern
      And Exists (
        Select 1
        From EDI32DTAT.EDOTBX B
        Where B.OTBOX = A.OTBOX
          And Cast( B.OTDTA
            As Char( 135 ) CCSID 37 )
            Like '%UNH+%'
          And Cast( B.OTDTA
            As Char( 135 ) CCSID 37 )
            Like '%INVOIC%'
      );

  If SqlState = '00000'
    And MailboxInd >= 0
    And MailboxNum <> *Blanks;
    DocType = 'EDI';
    LeaveSr;
  EndIf;

  // Try X12 810
  MailboxNum = *Blanks;
  MailboxInd = 0;
  Exec Sql
    Select
      Max( Cast( A.OTBOX
        As Char( 10 ) CCSID 37 ) )
    Into :MailboxNum :MailboxInd
    From EDI32DTAT.EDOTBX A
    Where Cast( A.OTDTA
      As Char( 135 ) CCSID 37 )
      Like :PackSlipPattern
      And Exists (
        Select 1
        From EDI32DTAT.EDOTBX B
        Where B.OTBOX = A.OTBOX
          And Cast( B.OTDTA
            As Char( 135 ) CCSID 37 )
            Like '%ST*810*%'
      );

  If SqlState = '00000'
    And MailboxInd >= 0
    And MailboxNum <> *Blanks;
    DocType = 'X12';
  EndIf;

EndSr;

//------------------------------------------------------------
// LookupInvoiceNum - Get IVH027 from IVCHDR/IVCHDRH
//------------------------------------------------------------
BegSr LookupInvoiceNum;

  InvoiceNum = 0;

  // Try IVCHDR first (active invoices)
  Exec Sql
    Select IVH027
    Into :InvoiceNum
    From WFLIB.IVCHDR
    Where IVH001 = :PackSlip
    Fetch First 1 Row Only;

  If SqlState = '00000';
    LeaveSr;
  EndIf;

  // Fall back to IVCHDRH (history)
  Exec Sql
    Select IVH027
    Into :InvoiceNum
    From WFLIB.IVCHDRH
    Where IVH001 = :PackSlip
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    LogKeyField = %Trim( PackSlipStr );
    LogMessage =
      'No invoice header for PS='
      + %Trim( PackSlipStr );
    ExSr LogError;
    InvoiceNum = 0;
  EndIf;

EndSr;

//------------------------------------------------------------
// CheckExisting - Check EDIINVOIC810 for existing records
//   DupDone = count with PROCESSED_FLAG = 'Y'
//   DupPending = count with PROCESSED_FLAG IN ('N','I')
//------------------------------------------------------------
BegSr CheckExisting;

  DupDone = 0;
  DupPending = 0;

  Exec Sql
    Select Count(*)
    Into :DupDone
    From EDITEST.EDIINVOIC810
    Where PACKING_SLIP = :PackSlip
      And CUSTOMER_NUMBER = :CustNum
      And PROCESSED_FLAG = 'Y';

  Exec Sql
    Select Count(*)
    Into :DupPending
    From EDITEST.EDIINVOIC810
    Where PACKING_SLIP = :PackSlip
      And CUSTOMER_NUMBER = :CustNum
      And PROCESSED_FLAG In ( 'N', 'I' );

EndSr;

//------------------------------------------------------------
// ReprocessInvoice - Call INVOICE/EDI810 directly
//   for existing unprocessed EDIINVOIC810 records
//------------------------------------------------------------
BegSr ReprocessInvoice;

  LogKeyField = %Trim( PackSlipStr );
  LogMessage = 'Reprocessing PS='
    + %Trim( PackSlipStr )
    + ' CUST=' + %Char( CustNum )
    + ' type=' + %Trim( DocType );
  ExSr LogInfo;

  Monitor;
    If DocType = 'EDI';
      CallInvoice();
    Else;
      CallEdi810();
    EndIf;
    ReprocessCnt += 1;
  On-Error;
    LogKeyField = %Trim( PackSlipStr );
    LogMessage = 'Reprocess failed for PS='
      + %Trim( PackSlipStr )
      + ' type=' + %Trim( DocType );
    ExSr LogError;
    ErrorCnt += 1;
  EndMon;

EndSr;

//------------------------------------------------------------
// CallDriver - Format params and call INVDRIVER
//------------------------------------------------------------
BegSr CallDriver;

  // Format packing slip (6 chars, zero-padded)
  ParmPackSlip = %EditC( PackSlip : 'X' );

  // Format customer number (5 digits in 6 chars)
  ParmCustNum = %EditC( CustNum : 'X' );

  // Format invoice number (6 digits in 7 chars)
  ParmInvNum = %EditC( InvoiceNum : 'X' );

  // Set invoice type
  If DocType = 'EDI';
    ParmInvType = '9 ';
  Else;
    ParmInvType = '00';
  EndIf;

  LogKeyField = %Trim( ParmPackSlip );
  LogMessage = 'Processing PS='
    + %Trim( ParmPackSlip )
    + ' CUST=' + %Trim( ParmCustNum )
    + ' INV=' + %Trim( ParmInvNum )
    + ' type=' + %Trim( DocType )
    + ' OTBOX=' + %Trim( MailboxNum );
  ExSr LogInfo;

  Monitor;
    CallInvDriver(
      ParmPackSlip :
      ParmCustNum :
      ParmInvNum :
      ParmInvType );
    ProcessedCnt += 1;
  On-Error;
    LogKeyField = %Trim( ParmPackSlip );
    LogMessage = 'INVDRIVER failed for PS='
      + %Trim( ParmPackSlip )
      + ' CUST=' + %Trim( ParmCustNum );
    ExSr LogError;
    ErrorCnt += 1;
  EndMon;

EndSr;

//------------------------------------------------------------
// LogInfo - Log informational message to ERRLOG
//------------------------------------------------------------
BegSr LogInfo;

  Exec Sql
    Insert Into EDITEST.ERRLOG
      ( ERR_PROGRAM, ERR_KEYFIELD,
        ERR_MESSAGE )
    Values
      ( :PGM_NAME, :LogKeyField,
        :LogMessage );

EndSr;

//------------------------------------------------------------
// LogError - Log error message to ERRLOG
//------------------------------------------------------------
BegSr LogError;

  Exec Sql
    Insert Into EDITEST.ERRLOG
      ( ERR_PROGRAM, ERR_KEYFIELD,
        ERR_MESSAGE )
    Values
      ( :PGM_NAME, :LogKeyField,
        'ERROR: ' Concat :LogMessage );

EndSr;

//------------------------------------------------------------
// EndProgram - Clean up and exit
//------------------------------------------------------------
BegSr EndProgram;

  *InLR = *On;
  Return;

EndSr;
