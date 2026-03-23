**FREE
Ctl-Opt DftActGrp( *No ) ActGrp( *Caller )
  Option( *SrcStmt:*NoDebugIo );

//********************************************************************
// Program Name: EDI810
// Description:  Process EDI X12 810 Invoice transactions
//
// Author:       Ajay Gomez
// Created:      02/16/2026
//
// Purpose:      Processes EDI X12 810 (Invoice) transactions from
//               the EDIINVOIC810 table and generates X12 format
//               files on the IFS for transmission to trading partners.
//
// Input:        EDIINVOIC810, IVCHDR/IVCHDRH, IVCPRT/IVCPRTH,
//               EDIMSTR, EDIDETL, EDIDUNN, WAREPSPL, ASNCUST,
//               CUSMF, CUSTADRS, ECSVAL, EDITPCX, PARTFILE,
//               PRTDSC01, IVCPARTS, PDUNNS, PLANTDSC, BILLTO
//
// Output:       EDI X12 810 files in /edidev/OUTBOUND/INVOICE/
//               Format: WF_INV_[invoice]_[datetime].txt
//
// Called By:    INVDRIVER - Invoice batch processing driver
//********************************************************************
//                   MODIFICATION HISTORY
//--------------------------------------------------------------------
// Date     | Init | Req/IR/SR | Description
//----------|------|-----------|------------------------------------
// 02/16/26 | AG   | Initial   | Initial creation
//--------------------------------------------------------------------

//==============================================================================
// D E C L A R A T I O N S
//==============================================================================

/copy AGLIB/QCPY,IFSAPIS
Dcl-C NEW_LINE x'25';

// IFS output
Dcl-S FilePath VarChar( 256 ) Inz( '/edidev/OUTBOUND/INVOICE/' );
Dcl-S CompleteFilePath VarChar( 256 );
Dcl-S TempFileName VarChar( 256 );
Dcl-S FileName VarChar( 256 );
Dcl-S Mode VarChar( 20 ) Inz( 'w+' );
Dcl-S Message VarChar( 2000 ) Inz( *Blanks );
Dcl-S FHandle Pointer;

// Command call for iconv/rm steps
Dcl-S CmdString Char( 2500 );
Dcl-S CmdLength Packed( 15: 5 );
Dcl-PR CallCmd ExtPgm( 'QCMDEXC' );
  Cmd Like( CmdString );
  CmdLen Like( CmdLength );
End-PR;

// SQL options
Exec Sql Set Option Commit = *None, ClosQlCsr = *EndMod;

// Working variables
Dcl-S CustomerNumber VarChar( 50 );
Dcl-S PackingSlip VarChar( 50 );
Dcl-S InvoiceNumber VarChar( 50 );
Dcl-S PrevPackingSlip VarChar( 50 ) Inz( '' );
Dcl-S PackSlipSeq Packed( 2: 0 ) Inz( 0 );
Dcl-S PackSlipBIG VarChar( 10 );
Dcl-S PlantNumber VarChar( 5 );
Dcl-S RowsFetched Zoned( 3: 0 );
Dcl-S ReadState Char( 5 );

// Loop counters
Dcl-S CustomerCurRow Zoned( 3: 0 );
Dcl-S InvoiceCurRow Zoned( 3: 0 );
Dcl-S InvoiceRowsFetched Zoned( 3: 0 );
Dcl-S DetailCurRow Zoned( 3: 0 );
Dcl-S DetailRowsFetched Zoned( 3: 0 );
Dcl-S CurRow Zoned( 3: 0 );

// Segment counting for SE (ST..SE inclusive)
Dcl-S SegCountTxn Int( 10 ) Inz( 0 );
Dcl-S LineItems Int( 10 ) Inz( 0 );
Dcl-S SuccessCount Int( 10 ) Inz( 0 );

// Variables for *PSSR error handler
Dcl-S PsrErrMsg VarChar( 1000 );
Dcl-S PsrKeyInfo VarChar( 256 );

// Host variables for SQL (address lookups)
Dcl-S Gv_Name VarChar( 50 );
Dcl-S Gv_Addr VarChar( 50 );
Dcl-S Gv_City VarChar( 35 );
Dcl-S Gv_State VarChar( 9 );
Dcl-S Gv_Zip VarChar( 9 );

// Date/time working variables
Dcl-S Gv_DocDT Char( 14 );
Dcl-S Gv_CurDate Char( 8 );
Dcl-S Gv_CurTime Char( 6 );
Dcl-S Gv_StCtrl Char( 4 );

// Invoice accumulators
Dcl-S TotalInvoiceAmt Packed( 11: 2 ) Inz( 0 );
Dcl-S TotalSurcharge Packed( 9: 2 ) Inz( 0 );
Dcl-S TotalEnergySurcharge Packed( 9: 2 ) Inz( 0 );
Dcl-S TotalDunnage Packed( 9: 2 ) Inz( 0 );
Dcl-S TotalDetailAmt Packed( 11: 2 ) Inz( 0 );

// ASNCUST party config (BY=Bill To, ST=Ship To, SF=Ship From)
Dcl-S Gv_P1Entity VarChar( 2 );   // ASN011
Dcl-S Gv_P1Name VarChar( 60 );    // ASN012
Dcl-S Gv_P1IdQual VarChar( 2 );   // ASN013
Dcl-S Gv_P1Id VarChar( 80 );      // ASN014
Dcl-S Gv_P2Entity VarChar( 2 );   // ASN015
Dcl-S Gv_P2Name VarChar( 60 );    // ASN016
Dcl-S Gv_P2IdQual VarChar( 2 );   // ASN017
Dcl-S Gv_P2Id VarChar( 80 );      // ASN018
Dcl-S Gv_P3Entity VarChar( 2 );   // ASN019
Dcl-S Gv_P3Name VarChar( 60 );    // ASN020
Dcl-S Gv_P3IdQual VarChar( 2 );   // ASN021
Dcl-S Gv_P3Id VarChar( 80 );      // ASN022
Dcl-S Gv_P4Entity VarChar( 2 );   // ASN023
Dcl-S Gv_P4Name VarChar( 60 );    // ASN024
Dcl-S Gv_P4IdQual VarChar( 2 );   // ASN025
Dcl-S Gv_P4Id VarChar( 80 );      // ASN026
Dcl-S Gv_CurrCode VarChar( 3 );   // ASN037

// CUSMF plant codes for Ship From override
Dcl-S Gv_Cmf074 VarChar( 15 );    // Plant 1 ship-from code
Dcl-S Gv_Cmf075 VarChar( 15 );    // Plant 2/3 ship-from code
Dcl-S Gv_Cmf077 VarChar( 15 );    // Plant 4 ship-from code
Dcl-S Gv_Cmf092 VarChar( 15 );    // Plant 5 ship-from code
Dcl-S Gv_Cmf093 VarChar( 15 );    // Plant 6 ship-from code
Dcl-S Gv_PlantShipFrom VarChar( 15 );
Dcl-S Gv_Cmf017 VarChar( 15 );    // Company number
Dcl-S Gv_Cmf066 VarChar( 1 );     // EDI invoicing flag

// Corporate DUNS and address data
Dcl-S Gv_CorpDunns VarChar( 15 );
Dcl-S Gv_CorpName VarChar( 50 );
Dcl-S Gv_CorpAddr1 VarChar( 40 );
Dcl-S Gv_CorpAddr2 VarChar( 40 );
Dcl-S Gv_CorpCity VarChar( 25 );
Dcl-S Gv_CorpState VarChar( 2 );
Dcl-S Gv_CorpZip VarChar( 10 );

// Ship-from plant DUNS and address data
Dcl-S Gv_ShipFromDunns VarChar( 15 );
Dcl-S Gv_ShipFromName VarChar( 50 );
Dcl-S Gv_ShipFromAddr1 VarChar( 40 );
Dcl-S Gv_ShipFromAddr2 VarChar( 40 );
Dcl-S Gv_ShipFromCity VarChar( 25 );
Dcl-S Gv_ShipFromState VarChar( 2 );
Dcl-S Gv_ShipFromZip VarChar( 10 );

// Trading partner data from ECSVAL for HDR segment
Dcl-S wSenderQual VarChar( 4 );
Dcl-S wSenderID VarChar( 35 );
Dcl-S wRecipQual VarChar( 4 );
Dcl-S wRecipID VarChar( 35 );

// EDITPCX configuration values (shared with 856)
Dcl-S Pcx_IsaVersion VarChar( 5 ) Inz( '00401' );
Dcl-S Pcx_GsVerRel VarChar( 6 ) Inz( '004010' );
Dcl-S Pcx_FobPayment VarChar( 2 ) Inz( 'CC' );
Dcl-S Pcx_FobLocQual VarChar( 2 ) Inz( '' );
Dcl-S Pcx_FobDesc VarChar( 80 ) Inz( '' );

// EDITPCX configuration values (810 specific)
Dcl-S Pcx_TransType VarChar( 2 ) Inz( 'DI' );
Dcl-S Pcx_CurPartyCode VarChar( 3 ) Inz( 'BY' );
Dcl-S Pcx_ItdTypeCode VarChar( 2 ) Inz( '05' );
Dcl-S Pcx_ItdNetDays VarChar( 3 ) Inz( '30' );
Dcl-S Pcx_ItdDiscPct VarChar( 6 ) Inz( '' );
Dcl-S Pcx_ItdDiscDays VarChar( 3 ) Inz( '' );
Dcl-S Pcx_It1Uom VarChar( 3 ) Inz( 'EA' );
Dcl-S Pcx_It1LineNumStyle VarChar( 1 ) Inz( 'S' );
Dcl-S Pcx_AddSurcharge VarChar( 1 ) Inz( 'N' );
Dcl-S Pcx_DunnageSegType VarChar( 4 ) Inz( 'SAC' );
Dcl-S Pcx_SacSurchCode VarChar( 4 ) Inz( 'H550' );
Dcl-S Pcx_SacDunnCode VarChar( 4 ) Inz( 'R060' );
Dcl-S Pcx_SendBigPoDt VarChar( 1 ) Inz( 'N' );
Dcl-S Pcx_SendPid VarChar( 1 ) Inz( 'N' );
Dcl-S Pcx_SendCad VarChar( 1 ) Inz( 'N' );
Dcl-S Pcx_RefHdrQuals VarChar( 20 ) Inz( 'PK' );
Dcl-S Pcx_RefDetQuals VarChar( 20 ) Inz( '' );
Dcl-S Pcx_N1Parties VarChar( 20 ) Inz( 'ST|SE' );
Dcl-S Pcx_ItaAxCode VarChar( 5 ) Inz( 'S0050' );
Dcl-S Pcx_DunnSacLinLvl VarChar( 1 ) Inz( 'N' );
Dcl-S Pcx_RefSumQuals VarChar( 20 ) Inz( '' );

// ECSVAL date/time format for 810
Dcl-S Pcx_DateFormat VarChar( 5 ) Inz( '102' );
Dcl-S Pcx_TimeFormat VarChar( 5 ) Inz( '204' );

// Multiple PO tracking (set by DeterminePONumber)
Dcl-S Gv_MultiplePOs Ind Inz( *Off );
Dcl-S Gv_SinglePO VarChar( 20 ) Inz( '' );

// Payment terms (set by GetPaymentTerms)
Dcl-S Gv_TermsDays VarChar( 3 ) Inz( '30' );
Dcl-S Gv_TermsCode VarChar( 3 ) Inz( '' );

// Invoice header working variables
Dcl-S InvDate VarChar( 8 );
Dcl-S ShipDate VarChar( 8 );
Dcl-S PrepaidCollect VarChar( 1 );
Dcl-S PODate VarChar( 8 );

// N1 party loop variables
Dcl-S N1PartyIdx Int( 10 );
Dcl-S N1PartyCode VarChar( 3 );
Dcl-S N1IdQual VarChar( 2 );
Dcl-S N1Id VarChar( 80 );

// REF loop variables
Dcl-S RefIdx Int( 10 );
Dcl-S RefQual VarChar( 3 );
Dcl-S RefValue VarChar( 80 );

// Detail line working variables
Dcl-S UnitPrice Packed( 9: 2 );
Dcl-S LineNum VarChar( 6 );
Dcl-S DetailCount Int( 10 );
Dcl-S ExtAmt Packed( 11: 2 );
Dcl-S dtlPartNum VarChar( 15 );
Dcl-S dtlPO VarChar( 20 );
Dcl-S dtlQty Packed( 5: 0 );
Dcl-S dtlPrice Packed( 7: 2 );
Dcl-S dtlSurcharge Packed( 5: 2 );
Dcl-S dtlEngSurch Packed( 5: 2 );
Dcl-S dtlWeight Packed( 7: 3 );
Dcl-S dtlPORel Packed( 3: 0 );
Dcl-S dtlRevLevel VarChar( 20 );
Dcl-S dtlBuyerPart VarChar( 15 );
Dcl-S dtlDesc VarChar( 40 );

// Summary segment working variables
Dcl-S TotalCents Packed( 13: 0 );
Dcl-S SurchAmtCents Packed( 13: 0 );
Dcl-S DunAmtCents Packed( 11: 0 );
Dcl-S DunLineNum Packed( 3: 0 );
Dcl-S DunNum VarChar( 9 );
Dcl-S DunDesc VarChar( 16 );
Dcl-S DunQty Packed( 5: 0 );
Dcl-S DunPrice Packed( 5: 2 );
Dcl-S DunExtPrice Packed( 7: 2 );
Dcl-S DunReturnable VarChar( 1 );
Dcl-S sacSegment VarChar( 200 );
Dcl-S sacPos Int( 10 );

// Date/Time helpers
Dcl-DS Result Qualified Template;
  FormattedDate VarChar( 14 );
  ReturnCode Int( 10 );
End-DS;
Dcl-DS DateResult LikeDS( Result );

// Driver arrays
Dcl-DS driverData Qualified Dim( 50 );
  packingSlip Packed( 6: 0 );
  invoiceNumber Packed( 8: 0 );
End-DS;

Dcl-DS CustomerNumbers Qualified Dim( 50 );
  number Packed( 6: 0 );
End-DS;

// Invoice detail results
Dcl-DS InvDetailDS Qualified Dim( 200 );
  PartNumber VarChar( 15 );
  PurchaseOrder VarChar( 20 );
  QtyShipped Packed( 5: 0 );
  PricePerPiece Packed( 7: 2 );
  SurchargePerPiece Packed( 5: 2 );
  EngSurcharge Packed( 5: 2 );
  PartWeight Packed( 7: 3 );
  POReleaseNum Packed( 3: 0 );
  RevisionLevel VarChar( 20 );
  BuyerPartNumber VarChar( 15 );
  PartDescription VarChar( 40 );
End-DS;

// Program Status Data Structure for error handling
Dcl-DS PgmStat PSDS;
  PgmName *Proc;
  PgmStatus *Status;
  PgmLib Char( 10 ) Pos( 81 );
  ExcpMsgId Char( 7 ) Pos( 40 );
  ExcpData Char( 80 ) Pos( 91 );
  ExcpType Char( 3 ) Pos( 171 );
  ExcpNumber Char( 4 ) Pos( 174 );
  ExcpMsgText Char( 132 ) Pos( 91 );
  CurrentUser Char( 10 ) Pos( 254 );
  ExcpLineNumber Char( 8 ) Pos( 21 );
End-DS;

// HDR segment data structure (32 fields, same as edi856)
Dcl-DS HDR_DS Qualified;
  GroupFuncCode      VarChar( 3 )  Inz( *Blanks );
  SenderQual         VarChar( 4 )  Inz( *Blanks );
  SenderID           VarChar( 35 ) Inz( *Blanks );
  RecipQual          VarChar( 4 )  Inz( *Blanks );
  RecipID            VarChar( 35 ) Inz( *Blanks );
  InterchgCtrlNum    VarChar( 14 ) Inz( *Blanks );
  GroupSenderID      VarChar( 35 ) Inz( *Blanks );
  GroupRecipID       VarChar( 35 ) Inz( *Blanks );
  GroupCtrlNum       VarChar( 9 )  Inz( *Blanks );
  GroupDate          VarChar( 8 )  Inz( *Blanks );
  GroupTime          VarChar( 8 )  Inz( *Blanks );
  TransCtrlNum       VarChar( 9 )  Inz( *Blanks );
  GroupVerRel        VarChar( 12 ) Inz( *Blanks );
  TransType          VarChar( 6 )  Inz( *Blanks );
  Agency             VarChar( 6 )  Inz( *Blanks );
  InterchgVer        VarChar( 8 )  Inz( *Blanks );
  InterchgDate       VarChar( 8 )  Inz( *Blanks );
  InterchgTime       VarChar( 6 )  Inz( *Blanks );
  TestInd            VarChar( 1 )  Inz( *Blanks );
  SyntaxId           VarChar( 4 )  Inz( *Blanks );
  SyntaxVerNo        VarChar( 1 )  Inz( *Blanks );
  RecipPass          VarChar( 14 ) Inz( *Blanks );
  RecipPassQual      VarChar( 3 )  Inz( *Blanks );
  AppRef             VarChar( 14 ) Inz( *Blanks );
  AckReq             VarChar( 1 )  Inz( *Blanks );
  PriorCode          VarChar( 1 )  Inz( *Blanks );
  CommAgrmtID        VarChar( 40 ) Inz( *Blanks );
  MessageRefNum      VarChar( 14 ) Inz( *Blanks );
  ControllingAgency  VarChar( 3 )  Inz( *Blanks );
  AccessRef          VarChar( 40 ) Inz( *Blanks );
  SeqMsgTransferNo   VarChar( 2 )  Inz( *Blanks );
  SeqMsgTransferInd  VarChar( 1 )  Inz( *Blanks );
End-DS;

//-------------------------------------------------------------------------
// Prototypes: utilities copied from edi856
//-------------------------------------------------------------------------
Dcl-PR WriteLineToFile Ind;
  lineText VarChar( 2000 ) Const;
  fileHandle Pointer;
End-PR;

Dcl-PR ConvertDateFormat LikeDS( Result );
  P_InputDate Char( 14 ) Const;
  P_FormatCode Int( 10 ) Const;
End-PR;

Dcl-PR getDateTimeChar Char( 15 );
End-PR;
Dcl-PR getDateTimeChar14 Char( 14 );
End-PR;

Dcl-PR LogError;
  P_ErrorMessage VarChar( 1000 ) Const;
  P_KeyField VarChar( 256 ) Const Options( *NoPass );
End-PR;

Dcl-PR JobLogPrint Int( 10 ) ExtProc( 'Qp0zLprintf' );
  String Pointer Value Options( *String );
  p1 Pointer Value Options( *String : *NoPass );
  p2 Pointer Value Options( *String : *NoPass );
  p3 Pointer Value Options( *String : *NoPass );
  p4 Pointer Value Options( *String : *NoPass );
  p5 Pointer Value Options( *String : *NoPass );
  p6 Pointer Value Options( *String : *NoPass );
  p7 Pointer Value Options( *String : *NoPass );
  p8 Pointer Value Options( *String : *NoPass );
End-PR;

Dcl-PR PadField VarChar( 512 );
  P_FieldValue VarChar( 512 ) Const;
  P_FieldLength Int( 10 ) Const;
End-PR;

Dcl-PR PadWithZeros VarChar( 20 );
  P_Value Packed( 15: 0 ) Const;
  P_Length Int( 10 ) Const;
End-PR;

Dcl-PR FormatDbNumber VarChar( 20 );
  P_Value Packed( 15: 0 ) Const;
End-PR;

Dcl-PR FormatDecimal VarChar( 15 );
  P_Value Packed( 9: 2 ) Const;
End-PR;

// Segment generators (copied from edi856)
Dcl-PR GenerateHDR VarChar( 1000 );
  P_GroupFuncCode     VarChar( 3 )  Const;
  P_SenderQual        VarChar( 4 )  Const;
  P_SenderID          VarChar( 35 ) Const;
  P_RecipQual         VarChar( 4 )  Const;
  P_RecipID           VarChar( 35 ) Const;
  P_InterchgCtrlNum   VarChar( 14 ) Const;
  P_GroupSenderID     VarChar( 35 ) Const;
  P_GroupRecipID      VarChar( 35 ) Const;
  P_GroupCtrlNum      VarChar( 9 )  Const;
  P_GroupDate         VarChar( 8 )  Const;
  P_GroupTime         VarChar( 8 )  Const;
  P_TransCtrlNum      VarChar( 9 )  Const;
  P_GroupVerRelCode   VarChar( 12 ) Const;
  P_TransType         VarChar( 6 )  Const;
  P_Agency            VarChar( 6 )  Const;
  P_InterchgVer       VarChar( 8 )  Const;
  P_InterchgDate      VarChar( 8 )  Const;
  P_InterchgTime      VarChar( 6 )  Const;
  P_TestInd           VarChar( 1 )  Const;
  P_SyntaxId          VarChar( 4 )  Const;
  P_SyntaxVerNo       VarChar( 1 )  Const;
  P_RecipPass         VarChar( 14 ) Const;
  P_RecipPassQual     VarChar( 3 )  Const;
  P_AppRef            VarChar( 14 ) Const;
  P_AckReq            VarChar( 1 )  Const;
  P_PriorCode         VarChar( 1 )  Const;
  P_CommAgrmtID       VarChar( 40 ) Const;
  P_MessageRefNum     VarChar( 14 ) Const;
  P_ControllingAgency VarChar( 3 )  Const;
  P_AccessRef         VarChar( 40 ) Const;
  P_SeqMsgTransferNo  VarChar( 2 )  Const;
  P_SeqMsgTransferInd VarChar( 1 )  Const;
End-PR;

Dcl-PR GenerateST VarChar( 200 );
  P_ControlNum VarChar( 9 ) Const;
  P_ImplRef    VarChar( 12 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateDTM VarChar( 300 );
  P_Qual VarChar( 3 ) Const;
  P_Date VarChar( 8 ) Const Options( *NoPass );
  P_Time VarChar( 8 ) Const Options( *NoPass );
  P_TimeCode VarChar( 2 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateN1 VarChar( 400 );
  P_Entitycode VarChar( 2 ) Const;
  P_Name       VarChar( 60 ) Const Options( *NoPass );
  P_IDQual     VarChar( 2 ) Const Options( *NoPass );
  P_Id         VarChar( 80 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateN2 VarChar( 400 );
  P_Name2 VarChar( 60 ) Const;
  P_Name3 VarChar( 60 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateN3 VarChar( 400 );
  P_Addr1 VarChar( 55 ) Const;
  P_Addr2 VarChar( 55 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateN4 VarChar( 400 );
  P_City    VarChar( 30 ) Const;
  P_State   VarChar( 2 ) Const Options( *NoPass );
  P_Zip     VarChar( 15 ) Const Options( *NoPass );
  P_Country VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GeneratePER VarChar( 400 );
  P_ContactFunc VarChar( 2 ) Const;
  P_Name        VarChar( 35 ) Const Options( *NoPass );
  P_CommQual    VarChar( 2 ) Const Options( *NoPass );
  P_Comm        VarChar( 80 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateREF VarChar( 300 );
  P_Qual VarChar( 3 ) Const;
  P_Val  VarChar( 80 ) Const;
End-PR;

Dcl-PR GetRefValue VarChar( 80 );
  P_Qualifier VarChar( 3 ) Const;
  P_PackingSlip VarChar( 50 ) Const;
  P_VehicleNumber VarChar( 20 ) Const;
  P_TrackingNumber VarChar( 20 ) Const;
  P_PlantShipFrom VarChar( 15 ) Const;
End-PR;

Dcl-PR GenerateCUR VarChar( 300 );
  P_Entity VarChar( 2 ) Const;
  P_Currency VarChar( 3 ) Const;
End-PR;

Dcl-PR GenerateSAC VarChar( 400 );
  p1 VarChar( 3 ) Const;
  p2 VarChar( 2 ) Const Options( *NoPass );
  p3 VarChar( 18 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateITA VarChar( 400 );
  P_Qualifier VarChar( 3 ) Const Options( *NoPass );
  P_ChargeRateCode VarChar( 3 ) Const Options( *NoPass );
  P_ChargeCode VarChar( 5 ) Const Options( *NoPass );
  P_UnitPrice VarChar( 15 ) Const Options( *NoPass );
  P_Quantity VarChar( 10 ) Const Options( *NoPass );
  P_Uom VarChar( 3 ) Const Options( *NoPass );
  P_Description VarChar( 80 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateFOB VarChar( 300 );
  P_Paymentcode VarChar( 2 ) Const;
  P_Locationqual VarChar( 2 ) Const Options( *NoPass );
  P_Location     VarChar( 30 ) Const Options( *NoPass );
End-PR;

Dcl-PR GeneratePID VarChar( 400 );
  P_Itemdesctype VarChar( 1 ) Const;
  P_Productcode  VarChar( 3 ) Const Options( *NoPass );
  P_Desc         VarChar( 256 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateCTT VarChar( 200 );
  P_Linecount VarChar( 9 ) Const;
  P_HashTotal VarChar( 15 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateSE VarChar( 200 );
  P_Segcount VarChar( 9 ) Const;
  P_Control  VarChar( 9 ) Const;
End-PR;

Dcl-PR GetBuyerPartNumber VarChar( 15 );
  P_PartNumber VarChar( 15 ) Const;
  P_OrderNumber VarChar( 22 ) Const;
  P_CustomerNumber VarChar( 50 ) Const;
End-PR;

//-------------------------------------------------------------------------
// Prototypes: new 810-specific procedures
//-------------------------------------------------------------------------
Dcl-PR GenerateBIG VarChar( 300 );
  P_InvoiceDate VarChar( 8 ) Const;
  P_InvoiceNumber VarChar( 22 ) Const;
  P_PODate VarChar( 8 ) Const Options( *NoPass );
  P_PONumber VarChar( 22 ) Const Options( *NoPass );
  P_TransTypeCode VarChar( 2 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateIT1 VarChar( 500 );
  P_LineNumber VarChar( 6 ) Const;
  P_Qty VarChar( 15 ) Const;
  P_UOM VarChar( 3 ) Const;
  P_UnitPrice VarChar( 15 ) Const;
  P_BasisCode VarChar( 2 ) Const Options( *NoPass );
  P_Qual1 VarChar( 2 ) Const Options( *NoPass );
  P_ID1 VarChar( 48 ) Const Options( *NoPass );
  P_Qual2 VarChar( 2 ) Const Options( *NoPass );
  P_ID2 VarChar( 48 ) Const Options( *NoPass );
  P_Qual3 VarChar( 2 ) Const Options( *NoPass );
  P_ID3 VarChar( 48 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateITD VarChar( 300 );
  P_TermsType VarChar( 2 ) Const;
  P_TermsBasis VarChar( 2 ) Const Options( *NoPass );
  P_DiscPercent VarChar( 6 ) Const Options( *NoPass );
  P_DiscDays VarChar( 3 ) Const Options( *NoPass );
  P_NetDays VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateTDS VarChar( 200 );
  P_TotalAmount VarChar( 15 ) Const;
End-PR;

Dcl-PR GenerateCAD VarChar( 300 );
  P_TransportMethod VarChar( 2 ) Const Options( *NoPass );
  P_EquipInit VarChar( 4 ) Const Options( *NoPass );
  P_EquipNumber VarChar( 10 ) Const Options( *NoPass );
  P_CarrierCode VarChar( 4 ) Const Options( *NoPass );
  P_RoutingSeq VarChar( 35 ) Const Options( *NoPass );
End-PR;

Dcl-PR DeterminePONumber;
  P_PackingSlip VarChar( 50 ) Const;
End-PR;

Dcl-PR GetPaymentTerms;
  P_CustomerNumber VarChar( 50 ) Const;
End-PR;

Dcl-PR ParsePipeDelimited VarChar( 20 );
  P_InputString VarChar( 100 ) Const;
  P_Index Int( 10 ) Const;
End-PR;

//==============================================================================
// M A I N L I N E
//==============================================================================

// Get list of distinct customers to process
Exec Sql Declare CUSTOMERCUR Scroll Cursor For
  Select Distinct CUSTOMER_NUMBER From EDIINVOIC810
  Where PROCESSED_FLAG = 'N' And X12EDIFACT = 'X12';
Exec Sql Open CUSTOMERCUR;

If SqlState <> '00000';
  LogError( 'Error opening customer cursor. SqlState: ' + SqlState );
  ExSr EndProgram;
EndIf;

Exec Sql Fetch First From CUSTOMERCUR For 50 Rows Into :CustomerNumbers;
Exec Sql Get Diagnostics :rowsFetched = Row_Count;
If rowsFetched <= 0;
  ExSr EndProgram;
EndIf;

For customerCurRow = 1 to rowsFetched;
  customerNumber = %Char( CustomerNumbers( customerCurRow ).number );

  // =====================================================================
  // Load ASNCUST party config (4 party slots + currency)
  // =====================================================================
  Exec Sql
    Select Trim( ASN011 ), Trim( ASN012 ), Trim( ASN013 ), Trim( ASN014 ),
           Trim( ASN015 ), Trim( ASN016 ), Trim( ASN017 ), Trim( ASN018 ),
           Trim( ASN019 ), Trim( ASN020 ), Trim( ASN021 ), Trim( ASN022 ),
           Trim( ASN023 ), Trim( ASN024 ), Trim( ASN025 ), Trim( ASN026 ),
           Case When Trim( Coalesce( ASN037, '' ) ) = ''
                Then 'USD' Else Trim( ASN037 ) End
    Into :Gv_P1Entity, :Gv_P1Name, :Gv_P1IdQual, :Gv_P1Id,
         :Gv_P2Entity, :Gv_P2Name, :Gv_P2IdQual, :Gv_P2Id,
         :Gv_P3Entity, :Gv_P3Name, :Gv_P3IdQual, :Gv_P3Id,
         :Gv_P4Entity, :Gv_P4Name, :Gv_P4IdQual, :Gv_P4Id,
         :Gv_CurrCode
    From ASNCUST
    Where ASN001 = :customerNumber
    Fetch First 1 Row Only;
  If SqlState <> '00000';
    Gv_P1Entity = '';
    Gv_P1Name = '';
    Gv_P1IdQual = '';
    Gv_P1Id = '';
    Gv_P2Entity = '';
    Gv_P2Name = '';
    Gv_P2IdQual = '';
    Gv_P2Id = '';
    Gv_P3Entity = '';
    Gv_P3Name = '';
    Gv_P3IdQual = '';
    Gv_P3Id = '';
    Gv_P4Entity = '';
    Gv_P4Name = '';
    Gv_P4IdQual = '';
    Gv_P4Id = '';
    Gv_CurrCode = 'USD';
  EndIf;

  // =====================================================================
  // Load CUSMF plant codes, EDI invoicing flag, company number
  // =====================================================================
  Exec Sql
    Select Trim( CMF074 ), Trim( CMF075 ), Trim( CMF077 ),
           Trim( CMF092 ), Trim( CMF093 ),
           Trim( Coalesce( CMF066, '' ) ),
           Trim( Coalesce( CMF017, '' ) )
    Into :Gv_Cmf074, :Gv_Cmf075, :Gv_Cmf077,
         :Gv_Cmf092, :Gv_Cmf093,
         :Gv_Cmf066, :Gv_Cmf017
    From CUSMF
    Where CMF001 = :customerNumber
    Fetch First 1 Row Only;
  If SqlState <> '00000';
    Gv_Cmf074 = '';
    Gv_Cmf075 = '';
    Gv_Cmf077 = '';
    Gv_Cmf092 = '';
    Gv_Cmf093 = '';
    Gv_Cmf066 = '';
    Gv_Cmf017 = '';
  EndIf;

  // =====================================================================
  // Load corporate DUNS and address (plant 0)
  // =====================================================================
  Exec Sql Select Trim( PDU002 ) Into :Gv_CorpDunns
    From PDUNNS Where PDU001 In ( 0, 2, 3 )
    Fetch First 1 Row Only;
  If SqlState <> '00000';
    Gv_CorpDunns = '';
  EndIf;

  Exec Sql Select
      Trim( PLA002 ), Trim( PLA007 ), Trim( PLA008 ),
      Trim( PLA009 ), Trim( PLA010 ),
      Case When PLA011 > 0 Then Trim( Char( PLA011 ) ) Else '' End
    Into :Gv_CorpName, :Gv_CorpAddr1, :Gv_CorpAddr2,
         :Gv_CorpCity, :Gv_CorpState, :Gv_CorpZip
    From PLANTDSC Where PLA001 = 0
    Fetch First 1 Row Only;
  If SqlState <> '00000';
    Gv_CorpName = 'WAUPACA FOUNDRY';
    Gv_CorpAddr1 = '';
    Gv_CorpAddr2 = '';
    Gv_CorpCity = '';
    Gv_CorpState = '';
    Gv_CorpZip = '';
  EndIf;

  // =====================================================================
  // Load ECSVAL + EDITPCX trading partner IDs and 810 config
  // =====================================================================
  Exec Sql
    Select Coalesce( Nullif( p.INV810SENDERQUAL, '' ), e.WFQUALIFIER ),
           Coalesce( Nullif( p.INV810SENDERID, '' ), e.WFTRADINGPARTNERID ),
           Coalesce( Nullif( p.INV810RECIPQUAL, '' ), e.PARTNERQUALIFIERID ),
           Coalesce( Nullif( p.INV810RECIPID, '' ), e.TRADINGPARTNERID ),
           Trim( Coalesce( p.ISAVERSIONNUM, '00401' ) ),
           Trim( Coalesce( p.GSVERSIONREL, '004010' ) ),
           Trim( Coalesce( p.INV810TRANSTYPE, 'DI' ) ),
           Trim( Coalesce( p.INV810CURPARTYCODE, 'BY' ) ),
           Trim( Coalesce( p.INV810ITDTYPECODE, '05' ) ),
           Trim( Coalesce( p.INV810ITDNETDAYS, '30' ) ),
           Trim( Coalesce( p.INV810ITDDISCPCT, '' ) ),
           Trim( Coalesce( p.INV810ITDDISCDAYS, '' ) ),
           Trim( Coalesce( p.INV810IT1UOMCODE, 'EA' ) ),
           Trim( Coalesce( p.INV810IT1LINENUMSTL, 'S' ) ),
           Trim( Coalesce( p.INV810ADDSURCHARGE, 'N' ) ),
           Trim( Coalesce( p.INV810DUNNSEGTYPE, 'SAC' ) ),
           Trim( Coalesce( p.INV810SACSURCHCODE, 'H550' ) ),
           Trim( Coalesce( p.INV810SACDUNNCODE, 'R060' ) ),
           Trim( Coalesce( p.INV810SENDBIGPODT, 'N' ) ),
           Trim( Coalesce( p.INV810SENDPID, 'N' ) ),
           Trim( Coalesce( p.INV810SENDCAD, 'N' ) ),
           Trim( Coalesce( p.INV810REFHDRQUALS, 'PK' ) ),
           Trim( Coalesce( p.INV810REFDETQUALS, '' ) ),
           Trim( Coalesce( p.INV810N1PARTIES, 'ST|SE' ) ),
           Trim( Coalesce( p.INV810ITAAXCODE, 'S0050' ) ),
           Trim( Coalesce( p.INV810DUNNSACLINLVL, 'N' ) ),
           Trim( Coalesce( p.INV810REFSUMQUALS, '' ) ),
           Trim( Coalesce( p.FOBPAYMENTCODE, 'CC' ) ),
           Trim( Coalesce( p.FOBLOCQUALIFIER, '' ) ),
           Trim( Coalesce( p.FOBDESCRIPTION, '' ) )
    Into :wSenderQual, :wSenderID, :wRecipQual, :wRecipID,
         :Pcx_IsaVersion, :Pcx_GsVerRel,
         :Pcx_TransType, :Pcx_CurPartyCode,
         :Pcx_ItdTypeCode, :Pcx_ItdNetDays,
         :Pcx_ItdDiscPct, :Pcx_ItdDiscDays,
         :Pcx_It1Uom, :Pcx_It1LineNumStyle,
         :Pcx_AddSurcharge, :Pcx_DunnageSegType,
         :Pcx_SacSurchCode, :Pcx_SacDunnCode,
         :Pcx_SendBigPoDt, :Pcx_SendPid,
         :Pcx_SendCad, :Pcx_RefHdrQuals,
         :Pcx_RefDetQuals, :Pcx_N1Parties,
         :Pcx_ItaAxCode, :Pcx_DunnSacLinLvl,
         :Pcx_RefSumQuals,
         :Pcx_FobPayment, :Pcx_FobLocQual, :Pcx_FobDesc
    From EDICUSTOMERVALUES e
    Join EDITPCUSTXRREF p On e.EDICUSTOMERVALUES_ID = p.ECSVALKEY
    Where e.RECORDSTATUS = 'A'
      And p.SHIPTOCUST = :customerNumber
      And p.SEND810INVOICE = 'Y'
      And p.SEND810TYPE = 'X12'
    Fetch First 1 Row Only;
  If SqlState <> '00000';
    LogError( 'No ECSVAL/EDITPCX config for customer ' +
              %Trim( customerNumber ) + '. Skipping.' );
    Iter;
  EndIf;

  // =====================================================================
  // Invoice cursor for this customer
  // =====================================================================
  Exec Sql Declare INVOICECUR Scroll Cursor For
    Select PACKING_SLIP, INVOICE_NUMBER
    From EDIINVOIC810
    Where CUSTOMER_NUMBER = :customerNumber
      And PROCESSED_FLAG = 'N' And X12EDIFACT = 'X12';
  Exec Sql Open INVOICECUR;

  If SqlState <> '00000';
    LogError( 'Error opening invoice cursor for customer ' +
              %Trim( customerNumber ) + '. SqlState: ' + SqlState );
    Iter;
  EndIf;

  Exec Sql Fetch First From INVOICECUR For 50 Rows Into :driverData;
  Exec Sql Get Diagnostics :invoiceRowsFetched = Row_Count;
  If invoiceRowsFetched <= 0;
    Exec Sql Close INVOICECUR;
    Iter;
  EndIf;

  // Mark records as in-process
  Exec Sql Update EDIINVOIC810
           Set PROCESSED_FLAG = 'I'
           Where CUSTOMER_NUMBER = :customerNumber
             And PROCESSED_FLAG = 'N'
             And X12EDIFACT = 'X12';

  // Open IFS file using first invoice number
  InvoiceNumber = %Char( driverData( 1 ).invoiceNumber );
  TempFileName = 'RAW_INV_' + %Trim( InvoiceNumber ) +
                 '_' + getDateTimeChar( ) + '.txt';
  FileName = 'WF_INV_' + %Trim( InvoiceNumber ) +
             '_' + getDateTimeChar( ) + '.txt';
  CompleteFilePath = FilePath + TempFileName;
  FHandle = OpenFile( %Trim( CompleteFilePath ): %Trim( Mode ) );
  If FHandle = *Null;
    LogError( 'Error opening IFS file: ' + %Trim( CompleteFilePath ) :
              %Trim( InvoiceNumber ) );
    Exec Sql Close INVOICECUR;
    Iter;
  EndIf;

  // =====================================================================
  // Process each invoice
  // =====================================================================
  SuccessCount = 0;
  For InvoiceCurRow = 1 to InvoiceRowsFetched;
    PackingSlip = %Char( driverData( InvoiceCurRow ).packingSlip );
    InvoiceNumber = %Char( driverData( InvoiceCurRow ).invoiceNumber );

    // Compute packing slip sequence (01, 02, 03...)
    If PackingSlip <> PrevPackingSlip;
      PackSlipSeq = 1;
      PrevPackingSlip = PackingSlip;
    Else;
      PackSlipSeq += 1;
    EndIf;
    PackSlipBIG = %Trim(PackingSlip) + %EditC(PackSlipSeq:'X');

    // Get invoice header: plant, ship date, invoice date, prepaid/collect
    Exec Sql Select Trim( Char( IVH018 ) ),
                    Trim( Char( IVH017 ) ),
                    Trim( Char( IVH022 ) ),
                    Trim( Coalesce( IVH020, '' ) )
      Into :PlantNumber, :ShipDate, :InvDate, :PrepaidCollect
      From IVCHDR
      Where IVH001 = :PackingSlip
      Fetch First 1 Row Only;
    If SqlState <> '00000';
      Exec Sql Select Trim( Char( IVH018 ) ),
                      Trim( Char( IVH017 ) ),
                      Trim( Char( IVH022 ) ),
                      Trim( Coalesce( IVH020, '' ) )
        Into :PlantNumber, :ShipDate, :InvDate, :PrepaidCollect
        From IVCHDRH
        Where IVH001 = :PackingSlip
        Fetch First 1 Row Only;
      If SqlState <> '00000';
        LogError( 'Unable to get invoice header for PS ' +
                 %Trim( PackingSlip ) : %Trim( InvoiceNumber ) );
        Iter;
      EndIf;
    EndIf;

    // Resolve ship-from plant code based on plant number
    Gv_PlantShipFrom = '';
    Select;
      When PlantNumber = '1';
        Gv_PlantShipFrom = Gv_Cmf074;
      When PlantNumber = '2' Or PlantNumber = '3';
        Gv_PlantShipFrom = Gv_Cmf075;
      When PlantNumber = '4';
        Gv_PlantShipFrom = Gv_Cmf077;
      When PlantNumber = '5';
        Gv_PlantShipFrom = Gv_Cmf092;
      When PlantNumber = '6';
        Gv_PlantShipFrom = Gv_Cmf093;
    EndSl;

    // Get ship-from plant DUNS
    Exec Sql Select Trim( PDU002 ) Into :Gv_ShipFromDunns
      From PDUNNS Where PDU001 = :PlantNumber
      Fetch First 1 Row Only;
    If SqlState <> '00000';
      Gv_ShipFromDunns = '';
    EndIf;

    // Get ship-from plant address
    Exec Sql Select
        Trim( PLA002 ), Trim( PLA007 ), Trim( PLA008 ),
        Trim( PLA009 ), Trim( PLA010 ),
        Case When PLA011 > 0 Then Trim( Char( PLA011 ) ) Else '' End
      Into :Gv_ShipFromName, :Gv_ShipFromAddr1, :Gv_ShipFromAddr2,
           :Gv_ShipFromCity, :Gv_ShipFromState, :Gv_ShipFromZip
      From PLANTDSC Where PLA001 = :PlantNumber
      Fetch First 1 Row Only;
    If SqlState <> '00000';
      Gv_ShipFromName = '';
      Gv_ShipFromAddr1 = '';
      Gv_ShipFromAddr2 = '';
      Gv_ShipFromCity = '';
      Gv_ShipFromState = '';
      Gv_ShipFromZip = '';
    EndIf;

    // Determine PO number (single vs multiple)
    DeterminePONumber( PackingSlip );

    // Get payment terms from BILLTO
    GetPaymentTerms( CustomerNumber );

    // Reset counters for this transaction
    SegCountTxn = 0;
    LineItems = 0;
    TotalInvoiceAmt = 0;
    TotalSurcharge = 0;
    TotalEnergySurcharge = 0;
    TotalDunnage = 0;
    TotalDetailAmt = 0;
    Gv_StCtrl = '0001';

    // =================================================================
    // HDR segment (ISA/GS envelope) - GroupFuncCode='IN', TransType='810'
    // =================================================================
    Clear HDR_DS;
    HDR_DS.GroupFuncCode = 'IN';
    HDR_DS.SenderQual = wSenderQual;
    HDR_DS.SenderID = wSenderID;
    HDR_DS.RecipQual = wRecipQual;
    HDR_DS.RecipID = wRecipID;
    HDR_DS.InterchgCtrlNum = '1';
    HDR_DS.GroupSenderID = wSenderID;
    HDR_DS.GroupRecipID = wRecipID;
    HDR_DS.GroupCtrlNum = '1';
    HDR_DS.GroupDate = %Char( %Date(): *ISO0 );
    HDR_DS.GroupTime = %Char( %Time(): *ISO0 );
    HDR_DS.TransCtrlNum = Gv_StCtrl;
    HDR_DS.GroupVerRel = Pcx_GsVerRel;
    HDR_DS.TransType = '810';
    HDR_DS.Agency = '';
    HDR_DS.InterchgVer = Pcx_IsaVersion;
    HDR_DS.InterchgDate = HDR_DS.GroupDate;
    HDR_DS.InterchgTime = HDR_DS.GroupTime;
    HDR_DS.TestInd = 'P';
    HDR_DS.SyntaxId = '';
    HDR_DS.SyntaxVerNo = '';
    HDR_DS.RecipPass = '';
    HDR_DS.RecipPassQual = '';
    HDR_DS.AppRef = '';
    HDR_DS.AckReq = '';
    HDR_DS.PriorCode = '';
    HDR_DS.CommAgrmtID = '';
    HDR_DS.MessageRefNum = '';
    HDR_DS.ControllingAgency = '';
    HDR_DS.AccessRef = '';
    HDR_DS.SeqMsgTransferNo = '';
    HDR_DS.SeqMsgTransferInd = '';

    Message = GenerateHDR(
      %Trim(HDR_DS.GroupFuncCode):
      %Trim(HDR_DS.SenderQual):
      %Trim(HDR_DS.SenderID):
      %Trim(HDR_DS.RecipQual):
      %Trim(HDR_DS.RecipID):
      %Trim(HDR_DS.InterchgCtrlNum):
      %Trim(HDR_DS.GroupSenderID):
      %Trim(HDR_DS.GroupRecipID):
      %Trim(HDR_DS.GroupCtrlNum):
      %Trim(HDR_DS.GroupDate):
      %Trim(HDR_DS.GroupTime):
      %Trim(HDR_DS.TransCtrlNum):
      %Trim(HDR_DS.GroupVerRel):
      %Trim(HDR_DS.TransType):
      %Trim(HDR_DS.Agency):
      %Trim(HDR_DS.InterchgVer):
      %Trim(HDR_DS.InterchgDate):
      %Trim(HDR_DS.InterchgTime):
      %Trim(HDR_DS.TestInd):
      %Trim(HDR_DS.SyntaxId):
      %Trim(HDR_DS.SyntaxVerNo):
      %Trim(HDR_DS.RecipPass):
      %Trim(HDR_DS.RecipPassQual):
      %Trim(HDR_DS.AppRef):
      %Trim(HDR_DS.AckReq):
      %Trim(HDR_DS.PriorCode):
      %Trim(HDR_DS.CommAgrmtID):
      %Trim(HDR_DS.MessageRefNum):
      %Trim(HDR_DS.ControllingAgency):
      %Trim(HDR_DS.AccessRef):
      %Trim(HDR_DS.SeqMsgTransferNo):
      %Trim(HDR_DS.SeqMsgTransferInd));
    WriteLineToFile( Message + NEW_LINE: FHandle );

    // =================================================================
    // ST - Transaction Set Header (810)
    // =================================================================
    Message = GenerateST( Gv_StCtrl );
    WriteLineToFile( Message + NEW_LINE: FHandle );
    SegCountTxn += 1;

    // =================================================================
    // BIG - Beginning Segment for Invoice
    // =================================================================
    // Format invoice date (IVH022 is YYYYMMDD numeric)
    Gv_DocDT = InvDate + '000000';
    DateResult = ConvertDateFormat( Gv_DocDT: 102 );
    InvDate = %Subst(DateResult.FormattedDate:3);

    // PO date (if configured to include)
    PODate = '';
    If Pcx_SendBigPoDt = 'Y';
      Gv_DocDT = ShipDate + '000000';
      DateResult = ConvertDateFormat( Gv_DocDT: 102 );
      PODate = %Subst(DateResult.FormattedDate:3);
    EndIf;

    If Not Gv_MultiplePOs And Gv_SinglePO <> '';
      Message = GenerateBIG( InvDate: %Trim( PackSlipBIG ):
                             PODate: Gv_SinglePO: Pcx_TransType );
    Else;
      Message = GenerateBIG( InvDate: %Trim( PackSlipBIG ):
                             PODate: '': Pcx_TransType );
    EndIf;
    WriteLineToFile( Message + NEW_LINE: FHandle );
    SegCountTxn += 1;

    // =================================================================
    // CUR - Currency
    // =================================================================
    Message = GenerateCUR( Pcx_CurPartyCode: Gv_CurrCode );
    WriteLineToFile( Message + NEW_LINE: FHandle );
    SegCountTxn += 1;

    // =================================================================
    // REF - Header-level Reference Identification (pipe-delimited)
    // =================================================================
    RefIdx = 1;
    RefQual = ParsePipeDelimited( Pcx_RefHdrQuals: RefIdx );
    Dow RefQual <> '';
      RefValue = GetRefValue( RefQual: PackingSlip: '': '':
                              Gv_PlantShipFrom );
      If RefValue <> '';
        Message = GenerateREF( RefQual: RefValue );
        WriteLineToFile( Message + NEW_LINE: FHandle );
        SegCountTxn += 1;
      EndIf;
      RefIdx += 1;
      RefQual = ParsePipeDelimited( Pcx_RefHdrQuals: RefIdx );
    EndDo;

    // =================================================================
    // N1/N3/N4 - Party Identification (pipe-delimited from EDITPCX)
    // =================================================================
    N1PartyIdx = 1;
    N1PartyCode = ParsePipeDelimited( Pcx_N1Parties: N1PartyIdx );
    Dow N1PartyCode <> '';

      // Determine address data source based on party code
      Gv_Name = '';
      Gv_Addr = '';
      Gv_City = '';
      Gv_State = '';
      Gv_Zip = '';

      Select;
        When N1PartyCode = 'BT' Or N1PartyCode = 'BY'
          Or N1PartyCode = 'RI';
          Exec Sql Select Trim(CAD003), Trim(CAD004),
                          Trim(CAD006), Trim(CAD007), Trim(CAD008)
            Into :Gv_Name, :Gv_Addr, :Gv_City, :Gv_State, :Gv_Zip
            From CUSTADRS Where CAD001=:customerNumber And CAD002=1
            Fetch First 1 Row Only;
        When N1PartyCode = 'ST' Or N1PartyCode = 'RE';
          Exec Sql Select Trim(CAD003), Trim(CAD004),
                          Trim(CAD006), Trim(CAD007), Trim(CAD008)
            Into :Gv_Name, :Gv_Addr, :Gv_City, :Gv_State, :Gv_Zip
            From CUSTADRS Where CAD001=:customerNumber And CAD002=2
            Fetch First 1 Row Only;
        When N1PartyCode = 'SE';
          // Seller uses corporate (HQ) data
          Gv_Name = Gv_CorpName;
          Gv_Addr = Gv_CorpAddr1;
          Gv_City = Gv_CorpCity;
          Gv_State = Gv_CorpState;
          Gv_Zip = Gv_CorpZip;
        When N1PartyCode = 'SF';
          // Ship-From uses plant data
          Gv_Name = Gv_ShipFromName;
          Gv_Addr = Gv_ShipFromAddr1;
          Gv_City = Gv_ShipFromCity;
          Gv_State = Gv_ShipFromState;
          Gv_Zip = Gv_ShipFromZip;
        When N1PartyCode = 'SU' Or N1PartyCode = 'VN';
          Gv_Name = Gv_CorpName;
          Gv_Addr = Gv_CorpAddr1;
          Gv_City = Gv_CorpCity;
          Gv_State = Gv_CorpState;
          Gv_Zip = Gv_CorpZip;
      EndSl;

      // Find ASNCUST ID qualifier and ID for this party code
      N1IdQual = '';
      N1Id = '';
      If Gv_P1Entity = N1PartyCode;
        N1IdQual = Gv_P1IdQual;
        N1Id = Gv_P1Id;
      ElseIf Gv_P2Entity = N1PartyCode;
        N1IdQual = Gv_P2IdQual;
        N1Id = Gv_P2Id;
      ElseIf Gv_P3Entity = N1PartyCode;
        N1IdQual = Gv_P3IdQual;
        N1Id = Gv_P3Id;
      ElseIf Gv_P4Entity = N1PartyCode;
        N1IdQual = Gv_P4IdQual;
        N1Id = Gv_P4Id;
      EndIf;

      // For SE, fall back to SF ASNCUST entry if no SE match
      If N1PartyCode = 'SE' And N1IdQual = '';
        If Gv_P1Entity = 'SF';
          N1IdQual = Gv_P1IdQual;
          N1Id = Gv_P1Id;
        ElseIf Gv_P2Entity = 'SF';
          N1IdQual = Gv_P2IdQual;
          N1Id = Gv_P2Id;
        ElseIf Gv_P3Entity = 'SF';
          N1IdQual = Gv_P3IdQual;
          N1Id = Gv_P3Id;
        ElseIf Gv_P4Entity = 'SF';
          N1IdQual = Gv_P4IdQual;
          N1Id = Gv_P4Id;
        EndIf;
      EndIf;

      // Override ID for SF with plant ship-from supplier code
      If N1PartyCode = 'SF' And %Trim( Gv_PlantShipFrom ) <> '';
        N1Id = Gv_PlantShipFrom;
      EndIf;

      // Fallback to DUNS for SE/SF/SU/VN if no ASNCUST match
      If N1IdQual = '';
        If N1PartyCode = 'SE' And Gv_CorpDunns <> '';
          N1IdQual = '01';
          N1Id = Gv_CorpDunns;
        ElseIf N1PartyCode = 'SF' And Gv_ShipFromDunns <> '';
          N1IdQual = '01';
          N1Id = Gv_ShipFromDunns;
        ElseIf ( N1PartyCode = 'SU' Or N1PartyCode = 'VN' )
            And Gv_CorpDunns <> '';
          N1IdQual = '01';
          N1Id = Gv_CorpDunns;
        EndIf;
      EndIf;

      // Generate N1
      If N1IdQual <> '' And %Trim( N1Id ) <> '';
        Message = GenerateN1( N1PartyCode: %Trim(Gv_Name):
                              N1IdQual: N1Id );
      Else;
        Message = GenerateN1( N1PartyCode: %Trim(Gv_Name) );
      EndIf;
      WriteLineToFile( Message + NEW_LINE: FHandle );
      SegCountTxn += 1;

      // N3 - Address
      If %Trim( Gv_Addr ) <> '';
        Message = GenerateN3( %Trim( Gv_Addr ) );
        WriteLineToFile( Message + NEW_LINE: FHandle );
        SegCountTxn += 1;
      EndIf;

      // N4 - City/State/Zip
      If %Trim( Gv_City ) <> '';
        Message = GenerateN4( %Trim(Gv_City): %Trim(Gv_State):
                              %Trim(Gv_Zip) );
        WriteLineToFile( Message + NEW_LINE: FHandle );
        SegCountTxn += 1;
      EndIf;

      N1PartyIdx += 1;
      N1PartyCode = ParsePipeDelimited( Pcx_N1Parties: N1PartyIdx );
    EndDo;

    // =================================================================
    // ITD - Terms of Sale (only if type code is configured)
    // =================================================================
    If %Trim( Pcx_ItdTypeCode ) <> '';
      If Pcx_ItdDiscPct <> '' And Pcx_ItdDiscDays <> '';
        Message = GenerateITD( Pcx_ItdTypeCode: '': Pcx_ItdDiscPct:
                               Pcx_ItdDiscDays: Pcx_ItdNetDays );
      Else;
        Message = GenerateITD( Pcx_ItdTypeCode: '': '': '':
                               Pcx_ItdNetDays );
      EndIf;
      WriteLineToFile( Message + NEW_LINE: FHandle );
      SegCountTxn += 1;
    EndIf;

    // =================================================================
    // DTM*011 - Ship Date
    // =================================================================
    Gv_DocDT = ShipDate + '000000';
    DateResult = ConvertDateFormat( Gv_DocDT: 102 );
    Message = GenerateDTM( '011': DateResult.FormattedDate );
    WriteLineToFile( Message + NEW_LINE: FHandle );
    SegCountTxn += 1;

    // =================================================================
    // FOB - F.O.B. Related Instructions
    // =================================================================
    If Pcx_FobPayment <> '';
      If Pcx_FobLocQual <> '' And Pcx_FobDesc <> '';
        Message = GenerateFOB( Pcx_FobPayment: Pcx_FobLocQual:
                               Pcx_FobDesc );
      Else;
        Message = GenerateFOB( Pcx_FobPayment );
      EndIf;
      WriteLineToFile( Message + NEW_LINE: FHandle );
      SegCountTxn += 1;
    EndIf;

    // =================================================================
    // Detail Loop: IT1/PID/REF/SAC per line item
    // IVCPRT (active) with automatic IVCPRTH (history) fallback
    // =================================================================
    Exec Sql Declare DETAILCUR Cursor For
      Select p.IVP002, p.IVP003,
             p.IVP008, p.IVP009,
             p.IVP010, p.IVP033,
             p.IVP017, p.IVP031,
             p.IVP032,
             Coalesce( Trim( d.PDS003 ), '' )
      From WFLIB.IVCPRT p
      Left Join WFLIB.PARTFILE f On f.PTF001 = p.IVP002
      Left Join WFLIB.PRTDSC01 d On d.PDS002 = f.PTF016
      Where p.IVP001 = :PackingSlip
        And p.IVP002 <> ''
        And p.IVP008 > 0
      Union All
      Select p.IVP002, p.IVP003,
             p.IVP008, p.IVP009,
             p.IVP010, p.IVP033,
             p.IVP017, p.IVP031,
             p.IVP032,
             Coalesce( Trim( d.PDS003 ), '' )
      From WFLIB.IVCPRTH p
      Left Join WFLIB.PARTFILE f On f.PTF001 = p.IVP002
      Left Join WFLIB.PRTDSC01 d On d.PDS002 = f.PTF016
      Where p.IVP001 = :PackingSlip
        And p.IVP002 <> ''
        And p.IVP008 > 0
        And Not Exists (
          Select 1 From WFLIB.IVCPRT q
          Where q.IVP001 = :PackingSlip
            And q.IVP002 <> ''
            And q.IVP008 > 0
        );

    Exec Sql Open DETAILCUR;
    DetailCount = 0;

    If SqlState = '00000';
      Exec Sql
        Fetch Next From DETAILCUR
        Into :dtlPartNum, :dtlPO, :dtlQty, :dtlPrice,
             :dtlSurcharge, :dtlEngSurch, :dtlWeight,
             :dtlPORel, :dtlRevLevel, :dtlDesc;
    EndIf;

    Dow SqlState = '00000';
      DetailCount += 1;
      LineItems += 1;

      // Get buyer part number via cross-reference lookup
      dtlBuyerPart = GetBuyerPartNumber(
                       %Trim( dtlPartNum ) :
                       %Trim( dtlPO ) :
                       CustomerNumber );

      // Calculate unit price (optionally include surcharges)
      UnitPrice = dtlPrice;
      If Pcx_AddSurcharge = 'Y';
        UnitPrice += dtlSurcharge;
        UnitPrice += dtlEngSurch;
      EndIf;

      // Determine line number based on style config
      If Pcx_It1LineNumStyle = 'A';
        LineNum = '1';
      Else;
        LineNum = %Char( DetailCount );
      EndIf;

      // IT1 - Baseline Item Data
      If %Trim( dtlBuyerPart ) <> '' And
         %Trim( dtlBuyerPart ) <> %Trim( dtlPartNum );
        // Buyer part differs from vendor part - send both BP and VP
        If %Trim( dtlPO ) <> '';
          Message = GenerateIT1(
            %Trim( LineNum ) :
            %Char( dtlQty ) :
            Pcx_It1Uom :
            FormatDecimal( UnitPrice ) :
            'PE' :
            'BP' : %Trim( dtlBuyerPart ) :
            'VP' : %Trim( dtlPartNum ) :
            'PO' : %Trim( dtlPO ) );
        Else;
          Message = GenerateIT1(
            %Trim( LineNum ) :
            %Char( dtlQty ) :
            Pcx_It1Uom :
            FormatDecimal( UnitPrice ) :
            'PE' :
            'BP' : %Trim( dtlBuyerPart ) :
            'VP' : %Trim( dtlPartNum ) );
        EndIf;
      Else;
        // No buyer part cross-ref - use BP (buyer's part number)
        If %Trim( dtlPO ) <> '';
          Message = GenerateIT1(
            %Trim( LineNum ) :
            %Char( dtlQty ) :
            Pcx_It1Uom :
            FormatDecimal( UnitPrice ) :
            'PE' :
            'BP' : %Trim( dtlPartNum ) :
            'PO' : %Trim( dtlPO ) );
        Else;
          Message = GenerateIT1(
            %Trim( LineNum ) :
            %Char( dtlQty ) :
            Pcx_It1Uom :
            FormatDecimal( UnitPrice ) :
            'PE' :
            'BP' : %Trim( dtlPartNum ) );
        EndIf;
      EndIf;
      WriteLineToFile( Message + NEW_LINE : FHandle );
      SegCountTxn += 1;

      // PID - Product/Item Description (if configured)
      If Pcx_SendPid = 'Y' And %Trim( dtlDesc ) <> '';
        Message = GeneratePID( 'F' : '' : %Trim( dtlDesc ) );
        WriteLineToFile( Message + NEW_LINE : FHandle );
        SegCountTxn += 1;
      EndIf;

      // REF - Detail-level references (pipe-delimited config)
      If %Trim( Pcx_RefDetQuals ) <> '';
        RefIdx = 1;
        RefQual = ParsePipeDelimited( Pcx_RefDetQuals : RefIdx );
        Dow %Trim( RefQual ) <> '';
          RefValue = GetRefValue( RefQual : PackingSlip :
                                  '' : '' : Gv_PlantShipFrom );
          If %Trim( RefValue ) <> '';
            Message = GenerateREF( RefQual : %Trim( RefValue ) );
            WriteLineToFile( Message + NEW_LINE : FHandle );
            SegCountTxn += 1;
          EndIf;
          RefIdx += 1;
          RefQual = ParsePipeDelimited( Pcx_RefDetQuals : RefIdx );
        EndDo;
      EndIf;

      // SAC - Line-level dunnage (DTNA-style, handled in Phase 5)

      // Accumulate line amounts
      ExtAmt = dtlQty * UnitPrice;
      TotalDetailAmt += ExtAmt;
      If Pcx_AddSurcharge <> 'Y';
        TotalSurcharge += dtlQty * dtlSurcharge;
        TotalEnergySurcharge += dtlQty * dtlEngSurch;
      EndIf;

      // Fetch next detail line
      Exec Sql
        Fetch Next From DETAILCUR
        Into :dtlPartNum, :dtlPO, :dtlQty, :dtlPrice,
             :dtlSurcharge, :dtlEngSurch, :dtlWeight,
             :dtlPORel, :dtlRevLevel, :dtlDesc;
    EndDo;

    Exec Sql Close DETAILCUR;

    // Log warning if no detail lines found for this invoice
    If DetailCount = 0;
      LogError( 'No detail lines found for invoice' :
                'INV:' + %Trim( InvoiceNumber ) +
                ' PS:' + %Trim( PackingSlip ) );
    EndIf;

    // =================================================================
    // Summary Segments: TDS, CAD, SAC surcharge, SAC/ITA dunnage
    // =================================================================

    // Accumulate dunnage total from EDIDUNN (before TDS calculation)
    // EDIDUNN is keyed by PackSlipBIG (packing slip + sequence), not invoice number
    TotalDunnage = 0;
    If Pcx_DunnageSegType <> 'NONE';
      Exec Sql
        Select Coalesce( Sum( EDG008 ), 0 )
        Into :TotalDunnage
        From WFLIB.EDIDUNN
        Where EDG001 = :PackSlipBIG
          And EDG008 <> 0;
      If SqlState <> '00000';
        TotalDunnage = 0;
      EndIf;
    EndIf;

    // =================================================================
    // Dunnage as IT1 lines (RC = Returnable Container)
    // When Pcx_DunnageSegType = 'IT1', output each EDIDUNN record
    // as an IT1 segment instead of SAC/ITA at the summary level.
    // =================================================================
    If Pcx_DunnageSegType = 'IT1' And TotalDunnage > 0;

      Exec Sql Declare DUNNIT1CUR Cursor For
        Select EDG002, EDG003, EDG004, EDG005,
               EDG007, EDG008, EDG009
        From WFLIB.EDIDUNN
        Where EDG001 = :PackSlipBIG
          And EDG008 <> 0;

      Exec Sql Open DUNNIT1CUR;

      If SqlState = '00000';
        Exec Sql
          Fetch Next From DUNNIT1CUR
          Into :DunLineNum, :DunNum, :DunDesc, :DunQty,
               :DunPrice, :DunExtPrice, :DunReturnable;
      EndIf;

      Dow SqlState = '00000';
        LineItems += 1;
        Message = GenerateIT1(
          '' :
          %Char( DunQty ) :
          'EA' :
          FormatDecimal( DunPrice ) :
          '' :
          'RC' :
          %Subst( %Trim( DunDesc ) : 1 : 3 ) );
        WriteLineToFile( Message + NEW_LINE : FHandle );
        SegCountTxn += 1;

        Exec Sql
          Fetch Next From DUNNIT1CUR
          Into :DunLineNum, :DunNum, :DunDesc, :DunQty,
               :DunPrice, :DunExtPrice, :DunReturnable;
      EndDo;

      Exec Sql Close DUNNIT1CUR;
    EndIf;

    // =================================================================
    // Summary-level REF (after all IT1 lines, before TDS)
    // =================================================================
    If %Trim( Pcx_RefSumQuals ) <> '';
      RefIdx = 1;
      RefQual = ParsePipeDelimited( Pcx_RefSumQuals : RefIdx );
      Dow %Trim( RefQual ) <> '';
        RefValue = GetRefValue( RefQual : PackingSlip :
                                '' : '' : Gv_PlantShipFrom );
        If %Trim( RefValue ) <> '';
          Message = GenerateREF( RefQual : %Trim( RefValue ) );
          WriteLineToFile( Message + NEW_LINE : FHandle );
          SegCountTxn += 1;
        EndIf;
        RefIdx += 1;
        RefQual = ParsePipeDelimited( Pcx_RefSumQuals : RefIdx );
      EndDo;
    EndIf;

    // TDS - Total Monetary Value Summary (amount in cents)
    TotalInvoiceAmt = TotalDetailAmt + TotalSurcharge +
                      TotalEnergySurcharge + TotalDunnage;
    TotalCents = TotalInvoiceAmt * 100;
    Message = GenerateTDS( %Char( TotalCents ) );
    WriteLineToFile( Message + NEW_LINE : FHandle );
    SegCountTxn += 1;

    // CAD - Carrier Detail (if configured)
    If Pcx_SendCad = 'Y';
      Message = GenerateCAD();
      WriteLineToFile( Message + NEW_LINE : FHandle );
      SegCountTxn += 1;
    EndIf;

    // SAC - Summary surcharge (when surcharges NOT folded into unit price)
    If Pcx_AddSurcharge <> 'Y' And
       ( TotalSurcharge + TotalEnergySurcharge ) > 0;
      sacSegment = *Blanks;
      sacPos = 1;
      %Subst( sacSegment : sacPos : 3 ) = 'SAC';
      sacPos += 3;
      %Subst( sacSegment : sacPos : 1 ) = 'C';
      sacPos += 1;
      %Subst( sacSegment : sacPos : 4 ) = %Trim( Pcx_SacSurchCode );
      sacPos += 4;
      sacPos += 2;
      sacPos += 2;
      SurchAmtCents = ( TotalSurcharge + TotalEnergySurcharge ) * 100;
      %Subst( sacSegment : sacPos : 15 ) =
        %Trim( %Char( SurchAmtCents ) );
      Message = sacSegment;
      WriteLineToFile( Message + NEW_LINE : FHandle );
      SegCountTxn += 1;
    EndIf;

    // SAC/ITA - Dunnage segments from EDIDUNN
    // Summary-level only (line-level dunnage for DTNA handled separately)
    If Pcx_DunnageSegType <> 'NONE' And TotalDunnage > 0
       And Pcx_DunnSacLinLvl <> 'Y';

      Exec Sql Declare DUNNCUR Cursor For
        Select EDG002, EDG003, EDG004, EDG005,
               EDG007, EDG008, EDG009
        From WFLIB.EDIDUNN
        Where EDG001 = :PackSlipBIG
          And EDG008 <> 0;

      Exec Sql Open DUNNCUR;

      If SqlState = '00000';
        Exec Sql
          Fetch Next From DUNNCUR
          Into :DunLineNum, :DunNum, :DunDesc, :DunQty,
               :DunPrice, :DunExtPrice, :DunReturnable;
      EndIf;

      Dow SqlState = '00000';
        If Pcx_DunnageSegType = 'ITA';
          // ITA segment for dunnage (Cat US/MX style)
          Message = GenerateITA( 'A' : '06' :
                      %Trim( Pcx_ItaAxCode ) :
                      FormatDecimal( DunPrice ) :
                      %Char( DunQty ) : 'PC' :
                      %Trim( DunDesc ) );
        Else;
          // SAC segment for dunnage (CNH/Bobcat/NACCO style)
          sacSegment = *Blanks;
          sacPos = 1;
          %Subst( sacSegment : sacPos : 3 ) = 'SAC';
          sacPos += 3;
          %Subst( sacSegment : sacPos : 1 ) = 'C';
          sacPos += 1;
          %Subst( sacSegment : sacPos : 4 ) =
            %Trim( Pcx_SacDunnCode );
          sacPos += 4;
          sacPos += 2;
          sacPos += 2;
          DunAmtCents = DunExtPrice * 100;
          %Subst( sacSegment : sacPos : 15 ) =
            %Trim( %Char( DunAmtCents ) );
          Message = sacSegment;
        EndIf;
        WriteLineToFile( Message + NEW_LINE : FHandle );
        SegCountTxn += 1;

        Exec Sql
          Fetch Next From DUNNCUR
          Into :DunLineNum, :DunNum, :DunDesc, :DunQty,
               :DunPrice, :DunExtPrice, :DunReturnable;
      EndDo;

      Exec Sql Close DUNNCUR;
    EndIf;

    // CTT - Transaction Totals
    Message = GenerateCTT( %Char( LineItems ) );
    WriteLineToFile( Message + NEW_LINE: FHandle );
    SegCountTxn += 1;

    // SE - Transaction Set Trailer (count includes ST and SE)
    Message = GenerateSE( %Char( SegCountTxn + 1 ): Gv_StCtrl );
    WriteLineToFile( Message + NEW_LINE: FHandle );

    SuccessCount += 1;

  EndFor;

  // Close IFS file
  CloseFile( FHandle );

  If SuccessCount > 0;
    // Convert EBCDIC to UTF-8
    CmdString = 'CALL QP2SHELL PARM(''/QOpenSys/usr/bin/sh'' ''-c'' ' +
        '''/QOpenSys/usr/bin/iconv -f IBM-037 -t UTF-8 < ' +
        %Trim( FilePath ) + %Trim( TempFileName ) + ' > ' +
        %Trim( FilePath ) + %Trim( FileName ) + ''')';
    CmdLength = %Len( %Trimr( CmdString ) );
    CallCmd( CmdString: CmdLength );

    // Remove RAW_ temp file
    CmdString = 'CALL QP2SHELL PARM(''/QOpenSys/usr/bin/sh'' ''-c'' ' +
        '''/QOpenSys/usr/bin/rm -f ' + %Trim( FilePath ) +
        %Trim( TempFileName ) + ''')';
    CmdLength = %Len( %Trimr( CmdString ) );
    CallCmd( CmdString: CmdLength );

    // Update driver table: PROCESSED_FLAG=Y with FILE_PATH
    CompleteFilePath = FilePath + FileName;
    Exec Sql Update EDIINVOIC810
             Set PROCESSED_FLAG = 'Y', FILE_PATH = :CompleteFilePath
             Where CUSTOMER_NUMBER = :customerNumber
               And PROCESSED_FLAG = 'I'
               And X12EDIFACT = 'X12';
  Else;
    // No invoices written - revert to N for retry
    Exec Sql Update EDIINVOIC810
             Set PROCESSED_FLAG = 'N'
             Where CUSTOMER_NUMBER = :customerNumber
               And PROCESSED_FLAG = 'I'
               And X12EDIFACT = 'X12';

    // Clean up empty files
    CmdString = 'CALL QP2SHELL PARM(''/QOpenSys/usr/bin/sh'' ''-c'' ' +
        '''/QOpenSys/usr/bin/rm -f ' + %Trim( FilePath ) +
        %Trim( TempFileName ) + ' ' + %Trim( FilePath ) +
        %Trim( FileName ) + ''')';
    CmdLength = %Len( %Trimr( CmdString ) );
    CallCmd( CmdString: CmdLength );
  EndIf;

  Exec Sql Close INVOICECUR;
EndFor;

Exec Sql Close CUSTOMERCUR;

ExSr EndProgram;

//==============================================================================
// S U B R O U T I N E S
//==============================================================================

BegSr ClearMessage;
  Message = *Blanks;
EndSr;

BegSr EndProgram;
  *InLR = *On;
  Return;
EndSr;

//==============================================================================
// *PSSR - Program Status Subroutine (Error Handler)
//==============================================================================
// Catches all unhandled runtime errors to prevent interactive inquiry messages.
//==============================================================================
BegSr *PSSR;
  psrErrMsg = 'Runtime error ' + %Trim( ExcpMsgId ) +
              ' at line ' + %Trim( ExcpLineNumber ) +
              ': ' + %Trim( ExcpData );

  If InvoiceNumber <> *Blanks;
    psrKeyInfo = 'INV:' + %Trim( InvoiceNumber );
  ElseIf PackingSlip <> *Blanks;
    psrKeyInfo = 'PS:' + %Trim( PackingSlip );
  Else;
    psrKeyInfo = 'Unknown context';
  EndIf;

  LogError( psrErrMsg : psrKeyInfo );
  Return;
EndSr;

//==============================================================================
// S U B P R O C E D U R E S
//==============================================================================
//==============================================================================
// NEW 810-SPECIFIC PROCEDURES
//==============================================================================

//-------------------------------------------------------------------
// GenerateBIG - Beginning Segment for Invoice
// Format: BIG*[date8]*[inv#]*[POdate8]*[PO#]***[transtype]
//-------------------------------------------------------------------
Dcl-Proc GenerateBIG Export;
Dcl-PI *N VarChar( 300 );
  P_InvoiceDate VarChar( 8 ) Const;
  P_InvoiceNumber VarChar( 22 ) Const;
  P_PODate VarChar( 8 ) Const Options( *NoPass );
  P_PONumber VarChar( 22 ) Const Options( *NoPass );
  P_TransTypeCode VarChar( 2 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'BIG';
  Pos += 3;
  %Subst( segmentData:Pos:8 ) = %Trim( P_InvoiceDate );
  Pos += 8;
  %Subst( segmentData:Pos:22 ) = %Trim( P_InvoiceNumber );
  Pos += 22;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:8 ) = %Trim( P_PODate );
  EndIf;
  Pos += 8;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:22 ) = %Trim( P_PONumber );
  EndIf;
  Pos += 22;
  Pos += 2; // BIG05 empty
  Pos += 2; // BIG06 empty
  If %Parms( ) >= 5;
    %Subst( segmentData:Pos:2 ) = %Trim( P_TransTypeCode );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateIT1 - Baseline Item Data
// Format: IT1*[line]*[qty]*[UOM]*[price]*[basis]*[q1]*[id1]*...
//-------------------------------------------------------------------
Dcl-Proc GenerateIT1 Export;
Dcl-PI *N VarChar( 500 );
  P_LineNumber VarChar( 6 ) Const;
  P_Qty VarChar( 15 ) Const;
  P_UOM VarChar( 3 ) Const;
  P_UnitPrice VarChar( 15 ) Const;
  P_BasisCode VarChar( 2 ) Const Options( *NoPass );
  P_Qual1 VarChar( 2 ) Const Options( *NoPass );
  P_ID1 VarChar( 48 ) Const Options( *NoPass );
  P_Qual2 VarChar( 2 ) Const Options( *NoPass );
  P_ID2 VarChar( 48 ) Const Options( *NoPass );
  P_Qual3 VarChar( 2 ) Const Options( *NoPass );
  P_ID3 VarChar( 48 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'IT1';
  Pos += 3;
  %Subst( segmentData:Pos:6 ) = %Trim( P_LineNumber );
  Pos += 6;
  %Subst( segmentData:Pos:15 ) = %Trim( P_Qty );
  Pos += 15;
  %Subst( segmentData:Pos:3 ) = %Trim( P_UOM );
  Pos += 3;
  %Subst( segmentData:Pos:15 ) = %Trim( P_UnitPrice );
  Pos += 15;
  If %Parms( ) >= 5;
    %Subst( segmentData:Pos:2 ) = %Trim( P_BasisCode );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 6;
    %Subst( segmentData:Pos:2 ) = %Trim( P_Qual1 );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 7;
    %Subst( segmentData:Pos:48 ) = %Trim( P_ID1 );
  EndIf;
  Pos += 48;
  If %Parms( ) >= 8;
    %Subst( segmentData:Pos:2 ) = %Trim( P_Qual2 );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 9;
    %Subst( segmentData:Pos:48 ) = %Trim( P_ID2 );
  EndIf;
  Pos += 48;
  If %Parms( ) >= 10;
    %Subst( segmentData:Pos:2 ) = %Trim( P_Qual3 );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 11;
    %Subst( segmentData:Pos:48 ) = %Trim( P_ID3 );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateITD - Terms of Sale/Deferred Terms of Sale
// Format: ITD*[type]*[basis]*[disc%]*[discdays]***[netdays]
//-------------------------------------------------------------------
Dcl-Proc GenerateITD Export;
Dcl-PI *N VarChar( 300 );
  P_TermsType VarChar( 2 ) Const;
  P_TermsBasis VarChar( 2 ) Const Options( *NoPass );
  P_DiscPercent VarChar( 6 ) Const Options( *NoPass );
  P_DiscDays VarChar( 3 ) Const Options( *NoPass );
  P_NetDays VarChar( 3 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'ITD';
  Pos += 3;
  %Subst( segmentData:Pos:2 ) = %Trim( P_TermsType );
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:2 ) = %Trim( P_TermsBasis );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:6 ) = %Trim( P_DiscPercent );
  EndIf;
  Pos += 6;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:3 ) = %Trim( P_DiscDays );
  EndIf;
  Pos += 3;
  Pos += 8; // ITD05 - terms discount amount (skip)
  Pos += 6; // ITD06 - terms date (skip)
  If %Parms( ) >= 5;
    %Subst( segmentData:Pos:3 ) = %Trim( P_NetDays );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateTDS - Total Monetary Value Summary
// Format: TDS*[totalcents] (amount in cents, no decimal)
//-------------------------------------------------------------------
Dcl-Proc GenerateTDS Export;
Dcl-PI *N VarChar( 200 );
  P_TotalAmount VarChar( 15 ) Const;
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'TDS';
  Pos += 3;
  %Subst( segmentData:Pos:15 ) = %Trim( P_TotalAmount );

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateCAD - Carrier Detail
// Format: CAD*[method]***[carrier]**[routing]
//-------------------------------------------------------------------
Dcl-Proc GenerateCAD Export;
Dcl-PI *N VarChar( 300 );
  P_TransportMethod VarChar( 2 ) Const Options( *NoPass );
  P_EquipInit VarChar( 4 ) Const Options( *NoPass );
  P_EquipNumber VarChar( 10 ) Const Options( *NoPass );
  P_CarrierCode VarChar( 4 ) Const Options( *NoPass );
  P_RoutingSeq VarChar( 35 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'CAD';
  Pos += 3;
  If %Parms( ) >= 1;
    %Subst( segmentData:Pos:2 ) = %Trim( P_TransportMethod );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:4 ) = %Trim( P_EquipInit );
  EndIf;
  Pos += 4;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:10 ) = %Trim( P_EquipNumber );
  EndIf;
  Pos += 10;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:4 ) = %Trim( P_CarrierCode );
  EndIf;
  Pos += 4;
  Pos += 2; // CAD05 - routing sequence (skip)
  If %Parms( ) >= 5;
    %Subst( segmentData:Pos:35 ) = %Trim( P_RoutingSeq );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// DeterminePONumber - Check if invoice has multiple POs
// Sets global: Gv_MultiplePOs, Gv_SinglePO
//-------------------------------------------------------------------
Dcl-Proc DeterminePONumber;
Dcl-PI *N;
  P_PackingSlip VarChar( 50 ) Const;
End-PI;
  Dcl-S poCount Int( 10 );
  Dcl-S singlePO VarChar( 20 );

  Gv_MultiplePOs = *Off;
  Gv_SinglePO = '';

  Exec Sql
    Select Count( Distinct IVP003 ), Min( IVP003 )
    Into :poCount, :singlePO
    From WFLIB.IVCPRT
    Where IVP001 = :P_PackingSlip
      And IVP002 <> ''
      And IVP008 > 0;

  If SqlState = '00000';
    If poCount > 1;
      Gv_MultiplePOs = *On;
      Gv_SinglePO = '';
    Else;
      Gv_SinglePO = %Trim( singlePO );
    EndIf;
  EndIf;

End-Proc;

//-------------------------------------------------------------------
// GetPaymentTerms - Get aging terms from BILLTO
// Sets global: Gv_TermsDays, Gv_TermsCode
//-------------------------------------------------------------------
Dcl-Proc GetPaymentTerms;
Dcl-PI *N;
  P_CustomerNumber VarChar( 50 ) Const;
End-PI;
  Dcl-S termsDays Packed( 3: 0 );
  Dcl-S termsCode Packed( 3: 0 );

  Gv_TermsDays = '30';
  Gv_TermsCode = '';

  Exec Sql
    Select BIL028, BIL032
    Into :termsDays, :termsCode
    From WFLIB.BILLTO
    Where BIL001 = :P_CustomerNumber
    Fetch First 1 Row Only;

  If SqlState = '00000';
    If termsDays > 0;
      Gv_TermsDays = %Char( termsDays );
    EndIf;
    If termsCode > 0;
      Gv_TermsCode = %Char( termsCode );
    EndIf;
  EndIf;

End-Proc;

//-------------------------------------------------------------------
// ParsePipeDelimited - Return Nth element from pipe-delimited string
// Returns '' if index is beyond the number of elements
//-------------------------------------------------------------------
Dcl-Proc ParsePipeDelimited Export;
Dcl-PI *N VarChar( 20 );
  P_InputString VarChar( 100 ) Const;
  P_Index Int( 10 ) Const;
End-PI;
  Dcl-S workStr VarChar( 100 );
  Dcl-S token VarChar( 20 );
  Dcl-S pipePos Int( 10 );
  Dcl-S currentIndex Int( 10 );

  If %Trim( P_InputString ) = '';
    Return '';
  EndIf;

  workStr = %Trim( P_InputString );
  currentIndex = 1;

  Dow currentIndex <= P_Index;
    pipePos = %Scan( '|' : workStr );
    If pipePos > 0;
      token = %Subst( workStr : 1 : pipePos - 1 );
      If pipePos < %Len( workStr );
        workStr = %Subst( workStr : pipePos + 1 );
      Else;
        workStr = '';
      EndIf;
    Else;
      token = workStr;
      workStr = '';
    EndIf;
    If currentIndex = P_Index;
      Return %Trim( token );
    EndIf;
    If workStr = '' And currentIndex < P_Index;
      Return '';
    EndIf;
    currentIndex += 1;
  EndDo;

  Return '';
End-Proc;

//==============================================================================
// PROCEDURES COPIED FROM EDI856
//==============================================================================

//-------------------------------------------------------------------
// GenerateHDR - Generate X12 Header Segment (32 fields)
//-------------------------------------------------------------------
Dcl-Proc GenerateHDR Export;
Dcl-PI GenerateHDR VarChar( 1000 );
  P_GroupFuncCode     VarChar( 3 )  Const;
  P_SenderQual        VarChar( 4 )  Const;
  P_SenderID          VarChar( 35 ) Const;
  P_RecipQual         VarChar( 4 )  Const;
  P_RecipID           VarChar( 35 ) Const;
  P_InterchgCtrlNum   VarChar( 14 ) Const;
  P_GroupSenderID     VarChar( 35 ) Const;
  P_GroupRecipID      VarChar( 35 ) Const;
  P_GroupCtrlNum      VarChar( 9 )  Const;
  P_GroupDate         VarChar( 8 )  Const;
  P_GroupTime         VarChar( 8 )  Const;
  P_TransCtrlNum      VarChar( 9 )  Const;
  P_GroupVerRelCode   VarChar( 12 ) Const;
  P_TransType         VarChar( 6 )  Const;
  P_Agency            VarChar( 6 )  Const;
  P_InterchgVer       VarChar( 8 )  Const;
  P_InterchgDate      VarChar( 8 )  Const;
  P_InterchgTime      VarChar( 6 )  Const;
  P_TestInd           VarChar( 1 )  Const;
  P_SyntaxId          VarChar( 4 )  Const;
  P_SyntaxVerNo       VarChar( 1 )  Const;
  P_RecipPass         VarChar( 14 ) Const;
  P_RecipPassQual     VarChar( 3 )  Const;
  P_AppRef            VarChar( 14 ) Const;
  P_AckReq            VarChar( 1 )  Const;
  P_PriorCode         VarChar( 1 )  Const;
  P_CommAgrmtID       VarChar( 40 ) Const;
  P_MessageRefNum     VarChar( 14 ) Const;
  P_ControllingAgency VarChar( 3 )  Const;
  P_AccessRef         VarChar( 40 ) Const;
  P_SeqMsgTransferNo  VarChar( 2 )  Const;
  P_SeqMsgTransferInd VarChar( 1 )  Const;
End-PI;

  Dcl-S r_HDRSegment VarChar( 1000 );

  r_HDRSegment = 'HDR';
  r_HDRSegment += PadField(P_GroupFuncCode : 3 );
  r_HDRSegment += PadField(P_SenderQual : 4 );
  r_HDRSegment += PadField(P_SenderID : 35 );
  r_HDRSegment += PadField(P_RecipQual : 4 );
  r_HDRSegment += PadField(P_RecipID : 35 );
  r_HDRSegment += PadField(P_InterchgCtrlNum : 14 );
  r_HDRSegment += PadField(P_GroupSenderID : 35 );
  r_HDRSegment += PadField(P_GroupRecipID : 35 );
  r_HDRSegment += PadField(P_GroupCtrlNum : 9 );
  r_HDRSegment += PadField(P_GroupDate : 8 );
  r_HDRSegment += PadField(P_GroupTime : 8 );
  r_HDRSegment += PadField(P_TransCtrlNum : 9 );
  r_HDRSegment += PadField(P_GroupVerRelCode : 12 );
  r_HDRSegment += PadField(P_TransType : 6 );
  r_HDRSegment += PadField(P_Agency : 6 );
  r_HDRSegment += PadField(P_InterchgVer : 8 );
  r_HDRSegment += PadField(P_InterchgDate : 8 );
  r_HDRSegment += PadField(P_InterchgTime : 6 );
  r_HDRSegment += PadField(P_TestInd : 1 );
  r_HDRSegment += PadField(P_SyntaxId : 4 );
  r_HDRSegment += PadField(P_SyntaxVerNo : 1 );
  r_HDRSegment += PadField(P_RecipPass : 14 );
  r_HDRSegment += PadField(P_RecipPassQual : 3 );
  r_HDRSegment += PadField(P_AppRef : 14 );
  r_HDRSegment += PadField(P_AckReq : 1 );
  r_HDRSegment += PadField(P_PriorCode : 1 );
  r_HDRSegment += PadField(P_CommAgrmtID : 40 );
  r_HDRSegment += PadField(P_MessageRefNum : 14 );
  r_HDRSegment += PadField(P_ControllingAgency : 3 );
  r_HDRSegment += PadField(P_AccessRef : 40 );
  r_HDRSegment += PadField(P_SeqMsgTransferNo : 2 );
  r_HDRSegment += PadField(P_SeqMsgTransferInd : 1 );

  Return r_HDRSegment;
End-Proc;

//-------------------------------------------------------------------
// PadField - Left-justifies and pads a field to specified length
//-------------------------------------------------------------------
Dcl-Proc PadField Export;
Dcl-PI PadField VarChar( 512 );
  P_FieldValue VarChar( 512 ) Const;
  P_FieldLength Int( 10 ) Const;
End-PI;

Dcl-S result VarChar( 512 );
Dcl-S trimmedValue VarChar( 512 );
Dcl-S i Int( 10 );

trimmedValue = %Trim(P_FieldValue);

If %Len(trimmedValue) > P_FieldLength;
  result = %Subst(trimmedValue : 1 : P_FieldLength);
Else;
  result = trimmedValue;
  For i = %Len(trimmedValue) + 1 to P_FieldLength;
    result += ' ';
  EndFor;
EndIf;

Return result;
End-Proc;

//-------------------------------------------------------------------
// GenerateST - Transaction Set Header (810)
//-------------------------------------------------------------------
Dcl-Proc GenerateST Export;
Dcl-PI *N VarChar( 200 );
    P_ControlNum VarChar( 9 ) Const;
    P_ImplRef    VarChar( 12 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'ST ';
  Pos += 3;
  %Subst( segmentData:Pos:3 ) = '810';
  Pos += 3;
  %Subst( segmentData:Pos:9 ) = %Trim( P_ControlNum );
  Pos += 9;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:12 ) = %Trim( P_ImplRef );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateDTM - Date/Time Reference
//-------------------------------------------------------------------
Dcl-Proc GenerateDTM Export;
Dcl-PI *N VarChar( 300 );
    P_Qual VarChar( 3 ) Const;
    P_Date VarChar( 8 ) Const Options( *NoPass );
    P_Time VarChar( 8 ) Const Options( *NoPass );
    P_TimeCode VarChar( 2 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'DTM';
  Pos += 3;
  %Subst( segmentData:Pos:3 ) = %Trim( P_Qual );
  Pos += 3;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:8 ) = %Trim( P_Date );
  EndIf;
  Pos += 8;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:8 ) = %Trim( P_Time );
  EndIf;
  Pos += 8;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:2 ) = %Trim( P_TimeCode );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GeneratePID - Product/Item Description
//-------------------------------------------------------------------
Dcl-Proc GeneratePID Export;
Dcl-PI *N VarChar( 400 );
    P_Itemdesctype VarChar( 1 ) Const;
    P_Productcode  VarChar( 3 ) Const Options( *NoPass );
    P_Desc         VarChar( 256 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'PID';
  Pos += 3;
  %Subst( segmentData:Pos:1 ) = %Trim( P_Itemdesctype );
  Pos += 1;
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:3 ) = %Trim( P_Productcode );
  EndIf;
  Pos += 3;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:256 ) = %Trim( P_Desc );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateREF - Reference Identification
//-------------------------------------------------------------------
Dcl-Proc GenerateREF Export;
Dcl-PI *N VarChar( 300 );
    P_Qual VarChar( 3 ) Const;
    P_Val  VarChar( 80 ) Const;
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'REF';
  Pos += 3;
  %Subst( segmentData:Pos:3 ) = %Trim( P_Qual );
  Pos += 3;
  %Subst( segmentData:Pos:80 ) = %Trim( P_Val );
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GetRefValue - Get REF segment value based on qualifier type
//-------------------------------------------------------------------
Dcl-Proc GetRefValue Export;
Dcl-PI *N VarChar( 80 );
  P_Qualifier VarChar( 3 ) Const;
  P_PackingSlip VarChar( 50 ) Const;
  P_VehicleNumber VarChar( 20 ) Const;
  P_TrackingNumber VarChar( 20 ) Const;
  P_PlantShipFrom VarChar( 15 ) Const;
End-PI;
  Dcl-S refValue VarChar( 80 );

  refValue = '';

  Select;
    When P_Qualifier = 'BM' Or P_Qualifier = 'PK';
      refValue = %Trim( P_PackingSlip );
    When P_Qualifier = 'CN';
      refValue = %Trim( P_VehicleNumber );
    When P_Qualifier = 'FR';
      refValue = %Trim( P_VehicleNumber );
    When P_Qualifier = '2I';
      refValue = %Trim( P_TrackingNumber );
    When P_Qualifier = 'IA';
      refValue = %Trim( P_PlantShipFrom );
    // 810-specific qualifiers
    When P_Qualifier = 'SI';
      refValue = %Trim( P_PackingSlip );
    When P_Qualifier = 'VN';
      refValue = %Trim( P_PlantShipFrom );
    When P_Qualifier = 'ZZ';
      refValue = %Trim( P_PlantShipFrom );
    Other;
      refValue = '';
  EndSl;

  Return refValue;
End-Proc;

//-------------------------------------------------------------------
// GeneratePER - Administrative Communications Contact
//-------------------------------------------------------------------
Dcl-Proc GeneratePER Export;
Dcl-PI *N VarChar( 400 );
    P_ContactFunc VarChar( 2 ) Const;
    P_Name        VarChar( 35 ) Const Options( *NoPass );
    P_CommQual    VarChar( 2 ) Const Options( *NoPass );
    P_Comm        VarChar( 80 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'PER';
  Pos += 3;
  %Subst( segmentData:Pos:2 ) = %Trim( P_ContactFunc );
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:35 ) = %Trim( P_Name );
  EndIf;
  Pos += 35;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:2 ) = %Trim( P_CommQual );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:80 ) = %Trim( P_Comm );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateFOB - F.O.B. Related Instructions
//-------------------------------------------------------------------
Dcl-Proc GenerateFOB Export;
Dcl-PI *N VarChar( 300 );
    P_Paymentcode VarChar( 2 ) Const;
    P_Locationqual VarChar( 2 ) Const Options( *NoPass );
    P_Location     VarChar( 30 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'FOB';
  Pos += 3;
  %Subst( segmentData:Pos:2 ) = %Trim( P_Paymentcode );
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:2 ) = %Trim( P_Locationqual );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:30 ) = %Trim( P_Location );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateN1 - Name (Party Identification)
//-------------------------------------------------------------------
Dcl-Proc GenerateN1 Export;
Dcl-PI *N VarChar( 400 );
    P_Entitycode VarChar( 2 ) Const;
    P_Name       VarChar( 60 ) Const Options( *NoPass );
    P_IDQual     VarChar( 2 ) Const Options( *NoPass );
    P_Id         VarChar( 80 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:2 ) = 'N1';
  Pos += 2;
  %Subst( segmentData:Pos:2 ) = %Trim( P_Entitycode );
  Pos += 2;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:60 ) = %Trim( P_Name );
  EndIf;
  Pos += 60;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:2 ) = %Trim( P_IDQual );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:80 ) = %Trim( P_Id );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateN2 - Additional Name Information
//-------------------------------------------------------------------
Dcl-Proc GenerateN2 Export;
Dcl-PI *N VarChar( 400 );
    P_Name2 VarChar( 60 ) Const;
    P_Name3 VarChar( 60 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:2 ) = 'N2';
  Pos += 2;
  %Subst( segmentData:Pos:60 ) = %Trim( P_Name2 );
  Pos += 60;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:60 ) = %Trim( P_Name3 );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateN3 - Address Information
//-------------------------------------------------------------------
Dcl-Proc GenerateN3 Export;
Dcl-PI *N VarChar( 400 );
    P_Addr1 VarChar( 55 ) Const;
    P_Addr2 VarChar( 55 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:2 ) = 'N3';
  Pos += 2;
  %Subst( segmentData:Pos:55 ) = %Trim( P_Addr1 );
  Pos += 55;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:55 ) = %Trim( P_Addr2 );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateN4 - Geographic Location
//-------------------------------------------------------------------
Dcl-Proc GenerateN4 Export;
Dcl-PI *N VarChar( 400 );
  P_City    VarChar( 30 ) Const;
  P_State   VarChar( 2 ) Const Options( *NoPass );
  P_Zip     VarChar( 15 ) Const Options( *NoPass );
  P_Country VarChar( 3 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:2 ) = 'N4';
  Pos += 2;
  %Subst( segmentData:Pos:30 ) = %Trim( P_City );
  Pos += 30;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:2 ) = %Trim( P_State );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:15 ) = %Trim( P_Zip );
  EndIf;
  Pos += 15;
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:3 ) = %Trim( P_Country );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateCUR - Currency
//-------------------------------------------------------------------
Dcl-Proc GenerateCUR Export;
Dcl-PI *N VarChar( 300 );
    P_Entity VarChar( 2 ) Const;
    P_Currency VarChar( 3 ) Const;
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'CUR';
  Pos += 3;
  %Subst( segmentData:Pos:2 ) = %Trim( P_Entity );
  Pos += 2;
  %Subst( segmentData:Pos:3 ) = %Trim( P_Currency );
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateSAC - Service, Promotion, Allowance, or Charge
//-------------------------------------------------------------------
Dcl-Proc GenerateSAC Export;
Dcl-PI *N VarChar( 400 );
    p1 VarChar( 3 ) Const;
    p2 VarChar( 2 ) Const Options( *NoPass );
    p3 VarChar( 18 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'SAC';
  Pos += 3;
  %Subst( segmentData:Pos:3 ) = %Trim( p1 );
  Pos += 3;
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:2 ) = %Trim( p2 );
  EndIf;
  Pos += 2;
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:18 ) = %Trim( p3 );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateITA - Allowance, Charge or Service
// Format: ITA*A***06*PC*{unitPrice}****{qty}*PC**PACKAGING
//-------------------------------------------------------------------
Dcl-Proc GenerateITA Export;
Dcl-PI *N VarChar( 400 );
    P_Qualifier VarChar( 3 ) Const Options( *NoPass );
    P_ChargeRateCode VarChar( 3 ) Const Options( *NoPass );
    P_ChargeCode VarChar( 5 ) Const Options( *NoPass );
    P_UnitPrice VarChar( 15 ) Const Options( *NoPass );
    P_Quantity VarChar( 10 ) Const Options( *NoPass );
    P_Uom VarChar( 3 ) Const Options( *NoPass );
    P_Description VarChar( 80 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );

  %Subst( segmentData:Pos:3 ) = 'ITA';
  Pos += 3;

  // ITA01 - Qualifier
  If %Parms( ) >= 1;
    %Subst( segmentData:Pos:3 ) = %Trim( P_Qualifier );
  EndIf;
  Pos += 3;

  Pos += 3; // ITA02 - empty
  Pos += 3; // ITA03 - empty

  // ITA04 - Charge Rate Code
  If %Parms( ) >= 2;
    %Subst( segmentData:Pos:3 ) = %Trim( P_ChargeRateCode );
  EndIf;
  Pos += 3;

  // ITA05 - Charge Code
  If %Parms( ) >= 3;
    %Subst( segmentData:Pos:5 ) = %Trim( P_ChargeCode );
  EndIf;
  Pos += 5;

  // ITA06 - Unit Price
  If %Parms( ) >= 4;
    %Subst( segmentData:Pos:15 ) = %Trim( P_UnitPrice );
  EndIf;
  Pos += 15;

  Pos += 5; // ITA07 - empty
  Pos += 5; // ITA08 - empty

  // ITA09 - Quantity
  If %Parms( ) >= 5;
    %Subst( segmentData:Pos:10 ) = %Trim( P_Quantity );
  EndIf;
  Pos += 10;

  // ITA10 - UOM
  If %Parms( ) >= 6;
    %Subst( segmentData:Pos:3 ) = %Trim( P_Uom );
  EndIf;
  Pos += 3;

  Pos += 3; // ITA11 - empty

  // ITA12 - Description
  If %Parms( ) >= 7;
    %Subst( segmentData:Pos:80 ) = %Trim( P_Description );
  EndIf;

  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// FormatDecimal - Format decimal number for segment output
//-------------------------------------------------------------------
Dcl-Proc FormatDecimal Export;
Dcl-PI *N VarChar( 15 );
    P_Value Packed( 9: 2 ) Const;
End-PI;
  Dcl-S Result VarChar( 15 );
  Dcl-S TempStr VarChar( 15 );

  TempStr = %Char( P_Value );
  Result = %Trim( TempStr );

  If %Scan( '.' : Result ) > 0;
    Dow %Len( Result ) > 1 And %Subst( Result : %Len(Result) : 1 ) = '0';
      Result = %Subst( Result : 1 : %Len(Result) - 1 );
    EndDo;
    If %Subst( Result : %Len(Result) : 1 ) = '.';
      Result = %Subst( Result : 1 : %Len(Result) - 1 );
    EndIf;
  EndIf;

  Return Result;
End-Proc;

//-------------------------------------------------------------------
// GenerateCTT - Transaction Totals
//-------------------------------------------------------------------
Dcl-Proc GenerateCTT Export;
Dcl-PI *N VarChar( 200 );
    P_Linecount VarChar( 9 ) Const;
    P_HashTotal VarChar( 15 ) Const Options( *NoPass );
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:3 ) = 'CTT';
  Pos += 3;
  %Subst( segmentData:Pos:9 ) = %Trim( P_Linecount );
  Pos += 9;
  If %Parms( ) >= 2 And P_HashTotal <> '';
    %Subst( segmentData:Pos:15 ) = %Trim( P_HashTotal );
  EndIf;
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// GenerateSE - Transaction Set Trailer
//-------------------------------------------------------------------
Dcl-Proc GenerateSE Export;
Dcl-PI *N VarChar( 200 );
    P_Segcount VarChar( 9 ) Const;
    P_Control  VarChar( 9 ) Const;
End-PI;
  Dcl-S segmentData VarChar( 500 ) Inz( *Blanks );
  Dcl-S Pos Int( 10 ) Inz( 1 );
  %Subst( segmentData:Pos:2 ) = 'SE';
  Pos += 2;
  %Subst( segmentData:Pos:9 ) = %Trim( P_Segcount );
  Pos += 9;
  %Subst( segmentData:Pos:9 ) = %Trim( P_Control );
  Return segmentData;
End-Proc;

//-------------------------------------------------------------------
// WriteLineToFile - Write a line to an IFS file
//-------------------------------------------------------------------
Dcl-Proc WriteLineToFile Export;
Dcl-PI *N Ind;
    lineText VarChar( 2000 ) Const;
    fileHandle Pointer;
End-PI;
  If WriteFile( lineText : fileHandle ) < 0;
    Return *Off;
  EndIf;
  Return *On;
End-Proc;

//-------------------------------------------------------------------
// getDateTimeChar - Get current date/time as 15-char string
//-------------------------------------------------------------------
Dcl-Proc getDateTimeChar;
Dcl-PI getDateTimeChar Char( 15 );
End-PI;
  Dcl-S dateStr Char( 8 );
  Dcl-S timeStr Char( 6 );
  dateStr = %Char( %Date( ): *ISO0 );
  timeStr = %Char( %Time( ): *ISO0 );
  Return dateStr + '_' + timeStr;
End-Proc;

//-------------------------------------------------------------------
// getDateTimeChar14 - Get current date/time as 14-char string
//-------------------------------------------------------------------
Dcl-Proc getDateTimeChar14;
Dcl-PI *N Char( 14 );
End-PI;
  Dcl-S dateStr Char( 8 );
  Dcl-S timeStr Char( 6 );
  dateStr = %Char( %Date( ): *ISO0 );
  timeStr = %Char( %Time( ): *ISO0 );
  Return dateStr + timeStr;
End-Proc;

//-------------------------------------------------------------------
// ConvertDateFormat - Convert date between formats
//-------------------------------------------------------------------
Dcl-Proc ConvertDateFormat Export;
Dcl-PI *N LikeDS( Result );
    P_InputDate Char( 14 ) Const;
    P_FormatCode Int( 10 ) Const;
End-PI;
  Dcl-S w_Year Char( 4 );
  Dcl-S w_Month Char( 2 );
  Dcl-S w_Day Char( 2 );
  Dcl-S w_Hour Char( 2 );
  Dcl-S w_Minute Char( 2 );
  Dcl-S w_Second Char( 2 );
  Dcl-DS ResultDS LikeDS( Result );
  ResultDS.ReturnCode = 0;
  ResultDS.FormattedDate = '';
  If %Len( %Trim( P_InputDate ) ) <> 14 Or
     %Check( '0123456789' : P_InputDate ) > 0;
    ResultDS.ReturnCode = -2;
    Return ResultDS;
  EndIf;
  w_Year=%Subst( P_InputDate:1:4 );
  w_Month=%Subst( P_InputDate:5:2 );
  w_Day=%Subst( P_InputDate:7:2 );
  w_Hour=%Subst( P_InputDate:9:2 );
  w_Minute=%Subst( P_InputDate:11:2 );
  w_Second=%Subst( P_InputDate:13:2 );
  Select;
    When P_FormatCode=102;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day;
    When P_FormatCode=203;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day + w_Hour + w_Minute;
    When P_FormatCode=204;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day +
                               w_Hour + w_Minute + w_Second;
    Other;
      ResultDS.ReturnCode=-1;
      ResultDS.FormattedDate='';
  EndSl;
  Return ResultDS;
End-Proc;

//-------------------------------------------------------------------
// LogError - Log error to EDITEST.ERRLOG table
//-------------------------------------------------------------------
Dcl-Proc LogError;
Dcl-PI *N;
    P_ErrorMessage VarChar( 1000 ) Const;
    P_KeyField VarChar( 256 ) Const Options( *NoPass );
End-PI;

  Dcl-S keyField VarChar( 256 );
  Dcl-S programName Char( 10 ) Inz( 'EDI810' );
  Dcl-S errorMessage VarChar( 1000 );

  errorMessage = P_ErrorMessage;

  If %Parms( ) >= 2;
    keyField = P_KeyField;
  Else;
    keyField = '';
  EndIf;

  Exec Sql
    Insert Into EDITEST.ERRLOG
      (ERR_PROGRAM, ERR_KEYFIELD, ERR_MESSAGE )
    Values
      (:programName, :keyField, :errorMessage );

  If SqlState <> '00000';
    // Silently handle to prevent recursive issues
  EndIf;

End-Proc;

//-------------------------------------------------------------------
// PadWithZeros - Left-pads a numeric value with leading zeros
//-------------------------------------------------------------------
Dcl-Proc PadWithZeros Export;
Dcl-PI PadWithZeros VarChar(20);
  P_Value  Packed(15:0) Const;
  P_Length Int(10) Const;
End-PI;

Dcl-S Result VarChar(20);

Result = %Char(P_Value);

Dow %Len(Result) < P_Length;
  Result = '0' + Result;
EndDo;

Return Result;
End-Proc;

//-------------------------------------------------------------------
// FormatDbNumber - Format numeric without artificial leading zeros
//-------------------------------------------------------------------
Dcl-Proc FormatDbNumber Export;
Dcl-PI FormatDbNumber VarChar(20);
  P_Value  Packed(15:0) Const;
End-PI;

Dcl-S Result VarChar(20);

Result = %Char(P_Value);

Return Result;
End-Proc;

//-------------------------------------------------------------------
// GetBuyerPartNumber - Lookup customer's part number from IVCPARTS
//-------------------------------------------------------------------
Dcl-Proc GetBuyerPartNumber Export;
Dcl-PI *N VarChar( 15 );
  P_PartNumber VarChar( 15 ) Const;
  P_OrderNumber VarChar( 22 ) Const;
  P_CustomerNumber VarChar( 50 ) Const;
End-PI;
  Dcl-S BuyerPart VarChar( 15 );
  Dcl-S CustNum Packed( 6: 0 );

  BuyerPart = '';

  Monitor;
    CustNum = %Dec( P_CustomerNumber : 6 : 0 );
  On-Error;
    CustNum = 0;
  EndMon;

  // 1. Try Part/PO lookup (most specific match)
  If %Trim( P_OrderNumber ) <> '';
    Exec Sql
      Select Trim( IVC002 )
      Into :BuyerPart
      From IVCPARTS
      Where IVC001 = :P_PartNumber
        And IVC010 = :P_OrderNumber
        And IVC003 = 'Y'
        And ( IVC011 = :CustNum Or IVC011 = 0 )
      Fetch First 1 Row Only;
    If SqlState = '00000' And %Trim( BuyerPart ) <> '';
      Return BuyerPart;
    EndIf;
  EndIf;

  // 2. Try Part/Customer lookup via IVCPAR03
  Exec Sql
    Select Trim( IVC002 )
    Into :BuyerPart
    From IVCPAR03
    Where IVC001 = :P_PartNumber
      And IVC011 = :CustNum
      And IVC003 = 'Y'
      And ( IVC010 = :P_OrderNumber Or IVC010 = '' )
    Fetch First 1 Row Only;
  If SqlState = '00000' And %Trim( BuyerPart ) <> '';
    Return BuyerPart;
  EndIf;

  // 3. Try Part-only lookup (generic mapping)
  Exec Sql
    Select Trim( IVC002 )
    Into :BuyerPart
    From IVCPARTS
    Where IVC001 = :P_PartNumber
      And IVC003 = 'Y'
      And IVC011 = 0
      And IVC010 = ''
    Fetch First 1 Row Only;
  If SqlState = '00000' And %Trim( BuyerPart ) <> '';
    Return BuyerPart;
  EndIf;

  // 4. Check for larger part# (IVC015/IVC016 alternate mapping)
  Exec Sql
    Select Trim( IVC015 )
    Into :BuyerPart
    From IVCPARTS
    Where IVC001 = :P_PartNumber
      And IVC015 <> ''
      And IVC016 = 'Y'
      And ( ( IVC011 = :CustNum And IVC010 = :P_OrderNumber )
         Or ( IVC011 = 0 And IVC010 = '' )
         Or ( IVC011 = :CustNum And IVC010 = '' )
         Or ( IVC011 = 0 And IVC010 = :P_OrderNumber ) )
    Fetch First 1 Row Only;
  If SqlState = '00000' And %Trim( BuyerPart ) <> '';
    Return BuyerPart;
  EndIf;

  // If no mapping found, return the original part number
  Return P_PartNumber;
End-Proc;
