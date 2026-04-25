**FREE
Ctl-Opt DftActGrp( *No ) ActGrp( *Caller )
  Option( *SrcStmt:*NoDebugIo );

//********************************************************************
// Program Name: INVOICE
// Description:  Process EDI INVOIC/810 Invoice Messages
//
// Author:       Ajay Gomez
// Email:        support@belleinnovations.com
// Phone:        (262) 880-0135
// Created:      02/16/2026
//
// Purpose:      Processes EDI INVOIC/810 (Invoice) transactions
//               from the EDIINVOIC810 table and generates EDIFACT
//               format files on the IFS for transmission to
//               trading partners.
//
// Input:        EDIINVOIC810 - EDI INVOIC transaction records
//               WAREPSPL - Packing slip and pick list data
//               IVCHDR, IVCHDRH - Invoice header files
//               IVCPRT, IVCPRTH - Invoice pricing/part data
//               CUSTADRS - Customer address master
//               EDFASN - Customer EDI configuration
//               CUSMF - Customer master file
//               PARTFILE - Part number master
//               PRTDSC01 - Part description file
//               DUNNAGE - Dunnage master
//               DUNUSAGE - Dunnage usage per customer
//
// Output:       EDI INVOIC files in /edidev/OUTBOUND/INVOICE/
//               Format: WF_INV_[invoice]_[datetime].txt
//
// Updates:      EDIINVOIC810 - Updates PROCESSED_FLAG status
//               (N -> I -> Y during processing)
//
// Called By:    INVDRIVER CL program
//               EDI batch processing jobs
//
// Calls:        IFS file I/O APIs (IFSAPIS copybook)
//               LogError - Error logging procedure
//               Multiple Generate* procedures for EDI segments
//
// Parameters:   None (processes all unprocessed records)
//
//********************************************************************
//                   MODIFICATION HISTORY
//--------------------------------------------------------------------
// Date     | Init | Req/IR/SR | Description
//----------|------|-----------|------------------------------------
// 02/16/26 | AG   | New       | Initial creation
//--------------------------------------------------------------------

//==============================================================================
// D E C L A R A T I O N S
//==============================================================================

// Variables for file path, mode, and message
Dcl-S FilePath VarChar( 256 ) Inz( '/edidev/OUTBOUND/INVOICE/' );
Dcl-S CompleteFilePath VarChar( 256 );
Dcl-S TempFileName VarChar( 256 );
Dcl-S FileName VarChar( 256 );
Dcl-S Mode VarChar( 20 ) Inz( 'w+' );
Dcl-S Message VarChar( 500 ) Inz( *Blanks );

Dcl-S CmdString Char( 2500 );
Dcl-S CmdLength Packed( 15: 5 );

Dcl-C DATA_ELEM_SEP '+';
Dcl-C COMP_DATA_SEP ':';
Dcl-C SEG_TERMINATOR '''';
Dcl-C DECIMAL_NOTATION '.';
Dcl-C RELEASE_INDICATOR '?';
Dcl-C NEW_LINE x'25';

// Row level variables cleared at each iteration
Dcl-S CustomerNumber VarChar( 50 );
Dcl-S PackingSlip VarChar( 50 );
Dcl-S InvoiceNumber VarChar( 50 );
Dcl-S PickList VarChar( 50 );
Dcl-S PlantNumber VarChar( 5 );
Dcl-S FndInPrimaryInvoice Ind Inz( *Off );

Dcl-S DateTimeFormatCode VarChar( 3 );
Dcl-S ShipDateTime VarChar( 35 ) Inz( *Blanks );
Dcl-S ConstructedDate Char( 14 ) Inz( *Blanks );

Dcl-S RowsFetched Zoned( 3: 0 );
Dcl-S CurrentRow Zoned( 3: 0 );
Dcl-S CustomerCurRow Zoned( 3: 0 ) Inz( *Zeros );
Dcl-S CustomerRowsFetched Zoned( 3: 0 ) Inz( *Zeros );
Dcl-S InvoiceCurRow Zoned( 3: 0 ) Inz( *Zeros );

// ResolveInvoiceNumbers work fields
Dcl-S WkIdx Zoned( 3: 0 );
Dcl-S WkPS Packed( 6: 0 );
Dcl-S WkIVH021 Packed( 8: 0 );
Dcl-S InvoiceRowsFetched Zoned( 3: 0 ) Inz( *Zeros );

Dcl-S LineItemNumber Zoned( 5: 0 ) Inz( 0 );
Dcl-S FormattedLineNum VarChar( 10 ) Inz( *Blanks );

// Invoice totals
Dcl-S InvoiceTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S BaseTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S SurchargeTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S EnergySurTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S PaintSurTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S AmortTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S DunnageTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S DunnagePNTotal Packed( 15: 4 ) Inz( 0 );
Dcl-S DunmagePCTotal Packed( 15: 4 ) Inz( 0 );

// Start the count at 1 so that we account for the UNT segment
Dcl-S SegmentCount Zoned( 3: 0 ) Inz( 1 );

// Variables for *PSSR error handler
Dcl-S PsrErrMsg VarChar( 1000 );
Dcl-S PsrKeyInfo VarChar( 256 );

// EDITPCX configuration values (loaded per customer)
Dcl-S Pcx_MsgVersion VarChar( 3 ) Inz( 'D' );
Dcl-S Pcx_MsgRelease VarChar( 3 ) Inz( '07A' );
Dcl-S Pcx_CtlAgency VarChar( 2 ) Inz( 'UN' );
Dcl-S Pcx_AssocCode VarChar( 6 ) Inz( 'GAVF24' );

// Customer type for INVOIC-specific logic
Dcl-S CustomerType VarChar( 10 ) Inz( 'STANDARD' );
Dcl-S TpName VarChar( 50 ) Inz( '' );

// Supplier number from CUSMF (plant-based DUNS)
Dcl-S SupplierNumber VarChar( 10 ) Inz( '' );

// Part description from PARTFILE/PRTDSC01
Dcl-S PartDescription VarChar( 40 ) Inz( '' );

// Buyer part number from IVCPARTS cross-reference
Dcl-S BuyerPartNumber VarChar( 35 ) Inz( '' );

// Amortization per piece from PARTFILE
Dcl-S AmortPerPiece Packed( 9: 2 ) Inz( 0 );

// Dunnage accumulation variables (used in AccumulateDunnage subroutine)
Dcl-S dngPrice Packed( 5: 2 ) Inz( 0 );
Dcl-S dngDesc Char( 9 );
Dcl-S dngQty Packed( 5: 0 );
Dcl-S dngSkip Char( 1 );
Dcl-S dngReturnable Char( 1 );
Dcl-S dngIdx Int( 10 );

// Flag for which detail cursor is active (IVCPRT vs IVCPRTH)
Dcl-S UsingHistoryDetail Ind Inz( *Off );

// End row level variables

//==============================================================================
// D A T A  S T R U C T U R E S
//==============================================================================

Dcl-DS Result Qualified Template;
  FormattedDate VarChar( 14 );
  ReturnCode Int( 10 );
End-DS;

Dcl-DS CustomerNumbers Qualified Dim(50 );
  number Packed( 6: 0 );
End-DS;

Dcl-DS DateResult LikeDS(Result);

// Driver data - invoice requests from EDIINVOIC810
Dcl-DS driverData Qualified Dim(50 );
  packingSlip Packed( 6: 0 );
  invoiceNumber Packed( 8: 0 );
  pickList Packed( 6: 0 );
End-DS;

// Invoice header data from IVCHDR/IVCHDRH
Dcl-DS invoiceHeaderDS Qualified;
  IVH001 Packed( 6: 0 );     // Packing slip
  IVH002 Packed( 4: 0 );     // Customer number
  IVH003 Char( 40 );         // Ship-to name override
  IVH004 Char( 40 );         // Ship-to addr 1
  IVH005 Char( 40 );         // Ship-to addr 2
  IVH006 Char( 40 );         // Ship-to addr 3
  IVH007 Packed( 5: 0 );     // Ship-to ZIP 1
  IVH008 Packed( 4: 0 );     // Ship-to ZIP 2
  IVH017 Packed( 8: 0 );     // Ship date
  IVH018 Packed( 1: 0 );     // Invoice origin plant
  IVH021 Packed( 8: 0 );     // Invoice number
  IVH022 Packed( 8: 0 );     // Invoice date YYYYMMDD
  IVH027 Packed( 6: 0 );     // Invoice time HHMMSS
End-DS;

// Invoice detail data from IVCPRT/IVCPRTH
Dcl-DS invoiceDetailDS Qualified;
  IVP001 Packed( 6: 0 );     // Packing slip
  IVP002 Char( 15 );         // Part number
  IVP003 Char( 20 );         // Purchase order number
  IVP008 Packed( 5: 0 );     // Quantity shipped
  IVP009 Packed( 7: 2 );     // Price per piece
  IVP010 Packed( 5: 2 );     // Surcharge per piece
  IVP012 Packed( 7: 4 );     // Paint price per piece
  IVP017 Packed( 7: 3 );     // Part weight
  IVP019 Char( 9 );          // Dunnage #1 desc
  IVP020 Packed( 5: 0 );     // Dunnage #1 qty
  IVP021 Char( 9 );          // Dunnage #2 desc
  IVP022 Packed( 5: 0 );     // Dunnage #2 qty
  IVP023 Char( 9 );          // Dunnage #3 desc
  IVP024 Packed( 5: 0 );     // Dunnage #3 qty
  IVP025 Char( 9 );          // Dunnage #4 desc
  IVP026 Packed( 5: 0 );     // Dunnage #4 qty
  IVP027 Packed( 8: 0 );     // Invoice number
  IVP031 Packed( 3: 0 );     // PO release number
  IVP033 Packed( 5: 2 );     // Eng surcharge per piece
  IVP035 Packed( 7: 3 );     // Final shipping weight
  LINE_NUM Packed( 5: 0 );   // Row number from cursor
End-DS;

// Packing slip data from WAREPSPL
Dcl-DS packingSlipDS Qualified;
  WPS001 Packed( 6: 0 );     // Packing slip number
  WPS002 Packed( 6: 0 );     // Pick list number
  WPS006 Packed( 8: 0 );     // Released date YYYYMMDD
  WPS007 Packed( 6: 0 );     // Released time HHMMSS
End-DS;

// EDFASN customer EDI configuration
Dcl-DS EDFASN_DS Qualified;
  TradingPartner    VarChar( 35 ) Inz( '' );
  BY_Qualifier      VarChar( 3 ) Inz( '' );
  BY_Code           VarChar( 35 ) Inz( '' );
  BY_CodeQual       VarChar( 3 ) Inz( '' );
  BY_Name           VarChar( 35 ) Inz( '' );
  SU_Qualifier      VarChar( 3 ) Inz( '' );
  SU_Code           VarChar( 35 ) Inz( '' );
  SU_CodeQual       VarChar( 3 ) Inz( '' );
  SU_Name           VarChar( 35 ) Inz( '' );
  SF_Qualifier      VarChar( 3 ) Inz( '' );
  SF_Code           VarChar( 35 ) Inz( '' );
  SF_CodeQual       VarChar( 3 ) Inz( '' );
  SF_Name           VarChar( 35 ) Inz( '' );
  ST_Qualifier      VarChar( 3 ) Inz( '' );
  ST_Code           VarChar( 35 ) Inz( '' );
  ST_CodeQual       VarChar( 3 ) Inz( '' );
  CountryCode       VarChar( 3 ) Inz( '' );
End-DS;

Dcl-DS UNB_DS Qualified;
  SyntaxId     VarChar( 4 ) Inz( 'UNOC' );
  SyntaxVer    VarChar( 1 ) Inz( '3' );
  SenderID     VarChar( 35 );
  SenderQual   VarChar( 4 );
  RecipID      VarChar( 35 );
  RecipQual    VarChar( 4 );
  PrepDate     VarChar( 8 );
  PrepTime     VarChar( 8 );
  ControlRef   VarChar( 14 );
  RecipPass    VarChar( 14 );
  AppRef       VarChar( 14 ) Inz( '' );
  PriorCode    VarChar( 1 ) Inz( '' );
  AckReq       VarChar( 1 ) Inz( '1' );
  CommAgrmtID  VarChar( 40 );
  TestInd      VarChar( 1 ) Inz( '1' );
End-DS;

Dcl-DS HDR_DS Qualified;
  GroupFuncCode       VarChar( 3 ) Inz( *Blanks );
  SenderQual          VarChar( 4 ) Inz( *Blanks );
  SenderID            VarChar( 35 ) Inz( *Blanks );
  RecipQual           VarChar( 4 ) Inz( *Blanks );
  RecipID             VarChar( 35 ) Inz( *Blanks );
  InterchgCtrlNum     VarChar( 14 ) Inz( *Blanks );
  GroupSenderID       VarChar( 35 ) Inz( *Blanks );
  GroupRecipID        VarChar( 35 ) Inz( *Blanks );
  GroupCtrlNum        VarChar( 9 ) Inz( *Blanks );
  GroupDate           VarChar( 8 ) Inz( *Blanks );
  GroupTime           VarChar( 8 ) Inz( *Blanks );
  TransCtrlNum        VarChar( 9 ) Inz( *Blanks );
  GroupVerRel         VarChar( 12 ) Inz( *Blanks );
  TransType           VarChar( 6 ) Inz( *Blanks );
  Agency              VarChar( 6 ) Inz( *Blanks );
  InterchgVer         VarChar( 8 ) Inz( *Blanks );
  InterchgDate        VarChar( 8 ) Inz( *Blanks );
  InterchgTime        VarChar( 6 ) Inz( *Blanks );
  TestInd             VarChar( 1 ) Inz( *Blanks );
  SyntaxId            VarChar( 4 ) Inz( *Blanks );
  SyntaxVerNo         VarChar( 1 ) Inz( *Blanks );
  RecipPass           VarChar( 14 ) Inz( *Blanks );
  RecipPassQual       VarChar( 3 ) Inz( *Blanks );
  AppRef              VarChar( 14 ) Inz( *Blanks );
  AckReq              VarChar( 1 ) Inz( *Blanks );
  PriorCode           VarChar( 1 ) Inz( *Blanks );
  CommAgrmtID         VarChar( 40 ) Inz( *Blanks );
  MessageRefNum       VarChar( 14 ) Inz( *Blanks );
  ControllingAgency   VarChar( 3 ) Inz( *Blanks );
  AccessRef           VarChar( 40 ) Inz( *Blanks );
  SeqMsgTransferNo    VarChar( 2 ) Inz( *Blanks );
  SeqMsgTransferInd   VarChar( 1 ) Inz( *Blanks );
End-DS;

Dcl-DS UNH_DS Qualified;
  MessageRefNum   VarChar( 14 );
  MessageType     VarChar( 6 );
  MessageVersion  VarChar( 3 );
  MessageRelease  VarChar( 3 );
  ControllingAgency VarChar( 2 );
  AssocCode       VarChar( 6 );
  AccessRef       VarChar( 35 );
  StatusIndCode   VarChar( 1 );
End-DS;

Dcl-DS BGM_DS Qualified;
  DocMsgName     VarChar( 3 );
  DocMsgNumber   VarChar( 35 );
  DocMsgFunction VarChar( 3 );
End-DS;

Dcl-DS DTM_DS Qualified;
  DateTimeFunctionCode VarChar( 3 );
  DateTimeValue VarChar( 35 );
  DateTimeFormatCode VarChar( 3 );
End-DS;

Dcl-DS NAD_DS Qualified;
  // Invoicee (IV) party data - from EDFASN
  IV_PartyCode      VarChar( 35 ) Inz( '' );
  IV_CodeQualifier  VarChar( 3 ) Inz( '92' );
  IV_Name           VarChar( 35 ) Inz( '' );

  // Buyer (BY) party data - from EDFASN/CUSTADRS
  BY_PartyCode      VarChar( 35 ) Inz( '' );
  BY_CodeQualifier  VarChar( 3 ) Inz( '92' );
  BY_Name           VarChar( 35 ) Inz( '' );
  BY_Street         VarChar( 35 ) Inz( '' );
  BY_City           VarChar( 35 ) Inz( '' );
  BY_State          VarChar( 9 ) Inz( '' );
  BY_PostalCode     VarChar( 9 ) Inz( '' );
  BY_CountryCode    VarChar( 3 ) Inz( '' );

  // Seller (SE) party data - plant DUNS from CUSMF
  SE_PartyCode      VarChar( 35 ) Inz( '' );
  SE_CodeQualifier  VarChar( 3 ) Inz( '92' );
  SE_Name           VarChar( 35 ) Inz( 'WAUPACA FOUNDRY, INC.' );
  SE_Street         VarChar( 35 ) Inz( '' );
  SE_City           VarChar( 35 ) Inz( '' );
  SE_State          VarChar( 9 ) Inz( '' );
  SE_PostalCode     VarChar( 9 ) Inz( '' );
  SE_CountryCode    VarChar( 3 ) Inz( 'US' );

  // Ship-From (SF) party data - from EDFASN
  SF_PartyCode      VarChar( 35 ) Inz( '' );
  SF_CodeQualifier  VarChar( 3 ) Inz( '92' );
  SF_Name           VarChar( 35 ) Inz( '' );

  // Payee (PE) party data - plant DUNS
  PE_PartyCode      VarChar( 35 ) Inz( '' );
  PE_CodeQualifier  VarChar( 3 ) Inz( '92' );
  PE_Name           VarChar( 35 ) Inz( 'WAUPACA FOUNDRY, INC.' );

  // Ship-To (ST) party data - from EDFASN/CUSTADRS
  ST_PartyCode      VarChar( 35 ) Inz( '' );
  ST_CodeQualifier  VarChar( 3 ) Inz( '92' );
  ST_Name           VarChar( 35 ) Inz( '' );
  ST_Street         VarChar( 35 ) Inz( '' );
  ST_City           VarChar( 35 ) Inz( '' );
  ST_State          VarChar( 9 ) Inz( '' );
  ST_PostalCode     VarChar( 9 ) Inz( '' );
  ST_CountryCode    VarChar( 3 ) Inz( '' );
End-DS;

// Program Status Data Structure for error handling
Dcl-DS PgmStat PSDS;
  PgmName *Proc;
  PgmStatus *Status;
  PgmLib Char( 10 ) Pos(81 );
  ExcpMsgId Char( 7 ) Pos(40 );
  ExcpData Char( 80 ) Pos(91 );
  ExcpType Char( 3 ) Pos(171 );
  ExcpNumber Char( 4 ) Pos(174 );
  ExcpMsgText Char( 132 ) Pos(91 );
  CurrentUser Char( 10 ) Pos(254 );
  ExcpLineNumber Char( 8 ) Pos(21 );
End-DS;

//==============================================================================
// P R O T O T Y P E S
//==============================================================================

Dcl-PR CallCmd ExtPgm('QCMDEXC');
  Cmd Like (CmdString);
  CmdLen Like (CmdLength);
End-PR;

Dcl-PR GenerateUNA VarChar( 9 );
  P_CompDataSep      VarChar( 1 ) Const Options( *NoPass );
  P_DataElemSep      VarChar( 1 ) Const Options( *NoPass );
  P_DecimalNotation  VarChar( 1 ) Const Options( *NoPass );
  P_ReleaseIndicator VarChar( 1 ) Const Options( *NoPass );
  P_Reserved         VarChar( 1 ) Const Options( *NoPass );
  P_SegTerminator    VarChar( 1 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateUNB VarChar( 500 );
  P_SyntaxId     VarChar( 10 ) Const;
  P_SyntaxVer    VarChar( 10 ) Const;
  P_SenderID     VarChar( 35 ) Const;
  P_SenderQual   VarChar( 10 ) Const;
  P_RecipID      VarChar( 35 ) Const;
  P_RecipQual    VarChar( 10 ) Const;
  P_PrepDate     VarChar( 6 ) Const;
  P_PrepTime     VarChar( 4 ) Const;
  P_ControlRef   VarChar( 35 ) Const;
  P_RecipPass    VarChar( 35 ) Const Options( *NoPass );
  P_AppRef       VarChar( 35 ) Const Options( *NoPass );
  P_PriorCode    VarChar( 1 ) Const Options( *NoPass );
  P_AckReq       VarChar( 1 ) Const Options( *NoPass );
  P_CommAgrmtID  VarChar( 35 ) Const Options( *NoPass );
  P_TestInd      VarChar( 1 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateUNH VarChar( 500 );
  P_MessageRefNum   VarChar( 14 ) Const;
  P_MessageType     VarChar( 6 ) Const;
  P_MessageVersion  VarChar( 3 ) Const;
  P_MessageRelease  VarChar( 3 ) Const;
  P_ControllingAgency VarChar( 2 ) Const;
  P_AssocCode       VarChar( 6 ) Const Options( *NoPass );
  P_AccessRef       VarChar( 35 ) Const Options( *NoPass );
  P_StatusIndCode   VarChar( 1 ) Const Options( *NoPass );
  P_MessageSubsetId VarChar( 6 ) Const Options( *NoPass );
  P_MessageSubsetVer VarChar( 3 ) Const Options( *NoPass );
  P_MessageSubsetRel VarChar( 3 ) Const Options( *NoPass );
  P_MessageSubsetCA VarChar( 2 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateBGM VarChar( 500 );
  P_DocMsgName     VarChar( 3 ) Const;
  P_DocMsgNumber   VarChar( 35 ) Const;
  P_DocMsgFunction VarChar( 3 ) Const;
  P_DocMsgNameText VarChar( 35 ) Const Options( *NoPass );
  P_ResponseType   VarChar( 3 ) Const Options( *NoPass );
  P_DocMsgStatus   VarChar( 3 ) Const Options( *NoPass );
  P_MsgLangCode    VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateDTM VarChar( 500 );
  P_DateTimeFunctionCode VarChar( 3 ) Const;
  P_DateTimeValue VarChar( 35 ) Const;
  P_DateTimeFormatCode VarChar( 3 ) Const;
  P_DateTimePeriodCode VarChar( 3 ) Const Options( *NoPass );
  P_TimeZoneCode VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateRFF VarChar( 500 );
  P_ReferenceCodeQual  VarChar( 3 ) Const;
  P_ReferenceNumber    VarChar( 70 ) Const;
  P_LineNumber         VarChar( 6 ) Const Options( *NoPass );
  P_ReferenceVersionId VarChar( 35 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateNAD VarChar( 500 );
  P_PartyQualifier       VarChar( 3 ) Const;
  P_PartyIdCode          VarChar( 35 ) Const Options( *NoPass );
  P_PartyIdCodeQualifier VarChar( 3 ) Const Options( *NoPass );
  P_PartyName            VarChar( 35 ) Const Options( *NoPass );
  P_Street               VarChar( 35 ) Const Options( *NoPass );
  P_City                 VarChar( 35 ) Const Options( *NoPass );
  P_CountrySubdivision   VarChar( 9 ) Const Options( *NoPass );
  P_PostalCode           VarChar( 9 ) Const Options( *NoPass );
  P_CountryCode          VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateLIN VarChar( 500 );
  P_LineItemNumber       VarChar( 6 ) Const;
  P_ItemIdType1          VarChar( 3 ) Const;
  P_ItemId1              VarChar( 35 ) Const;
  P_ItemIdType2          VarChar( 3 ) Const Options( *NoPass );
  P_ItemId2              VarChar( 35 ) Const Options( *NoPass );
  P_ItemIdType3          VarChar( 3 ) Const Options( *NoPass );
  P_ItemId3              VarChar( 35 ) Const Options( *NoPass );
  P_SubLineIndicator     VarChar( 1 ) Const Options( *NoPass );
  P_ConfigurationLevel   VarChar( 2 ) Const Options( *NoPass );
  P_ConfigurationCode    VarChar( 2 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateIMD VarChar( 500 );
  P_ItemDescTypeCode      VarChar( 3 ) Const Options( *NoPass );
  P_ItemCharCode          VarChar( 3 ) Const Options( *NoPass );
  P_ItemDescCode          VarChar( 17 ) Const Options( *NoPass );
  P_ItemDescCodeTypeCode  VarChar( 3 ) Const Options( *NoPass );
  P_ItemDesc              VarChar( 256 ) Const Options( *NoPass );
  P_SurfaceLayerCode      VarChar( 3 ) Const Options( *NoPass );
  P_SourceLanguageCode    VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateQTY VarChar( 500 );
  P_QuantityTypeCode    VarChar( 3 ) Const;
  P_Quantity            VarChar( 15 ) Const;
  P_MeasureUnitCode     VarChar( 3 ) Const Options( *NoPass );
  P_QuantityQualifier   VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateLOC VarChar( 500 );
  P_3227_LocationFunctionCodeQualifier VarChar( 3 ) Const;
  P_C517_1_LocationNameCode VarChar( 35 ) Const Options( *NoPass );
  P_C517_2_CodeListResponsibleAgencyCode VarChar( 3 ) Const Options( *NoPass );
  P_C517_3_LocationName VarChar( 256 ) Const Options( *NoPass );
  P_3225_LocationIdentifier VarChar( 35 ) Const Options( *NoPass );
  P_C519_1_RelatedLocationOneID VarChar( 35 ) Const Options( *NoPass );
  P_C519_2_RelatedLocationOneCodeListCode VarChar( 3 ) Const Options( *NoPass );
  P_C553_1_RelatedLocationTwoID VarChar( 35 ) Const Options( *NoPass );
  P_C553_2_RelatedLocationTwoCodeListCode VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateMOA VarChar( 500 );
  P_TypeQualifier     VarChar( 3 ) Const;
  P_Amount            VarChar( 35 ) Const;
  P_CurrencyCode      VarChar( 3 ) Const Options( *NoPass );
  P_CurrencyQualifier VarChar( 3 ) Const Options( *NoPass );
  P_StatusCode        VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateUNT VarChar( 500 );
  P_SegmentCount       VarChar( 6 ) Const;
  P_MessageRefNumber   VarChar( 14 ) Const;
End-PR;

Dcl-PR GenerateUNZ VarChar( 500 );
  P_InterchangeControlCount VarChar( 6 ) Const;
  P_InterchangeControlRef   VarChar( 14 ) Const;
End-PR;

Dcl-PR GenerateHDR VarChar( 1000 );
  P_GroupFuncCode       VarChar( 3 )  Const;
  P_SenderQual          VarChar( 4 )  Const;
  P_SenderID            VarChar( 35 ) Const;
  P_RecipQual           VarChar( 4 )  Const;
  P_RecipID             VarChar( 35 ) Const;
  P_InterchgCtrlNum     VarChar( 14 ) Const;
  P_GroupSenderID       VarChar( 35 ) Const;
  P_GroupRecipID        VarChar( 35 ) Const;
  P_GroupCtrlNum        VarChar( 9 )  Const;
  P_GroupDate           VarChar( 8 )  Const;
  P_GroupTime           VarChar( 8 )  Const;
  P_TransCtrlNum        VarChar( 9 )  Const;
  P_GroupVerRelCode     VarChar( 12 ) Const;
  P_TransType           VarChar( 6 )  Const;
  P_Agency              VarChar( 6 )  Const;
  P_InterchgVer         VarChar( 8 )  Const;
  P_InterchgDate        VarChar( 8 )  Const;
  P_InterchgTime        VarChar( 6 )  Const;
  P_TestInd             VarChar( 1 )  Const;
  P_SyntaxId            VarChar( 4 )  Const;
  P_SyntaxVerNo         VarChar( 1 )  Const;
  P_RecipPass           VarChar( 14 ) Const;
  P_RecipPassQual       VarChar( 3 )  Const;
  P_AppRef              VarChar( 14 ) Const;
  P_AckReq              VarChar( 1 )  Const;
  P_PriorCode           VarChar( 1 )  Const;
  P_CommAgrmtID         VarChar( 40 ) Const;
  P_MessageRefNum       VarChar( 14 ) Const;
  P_ControllingAgency   VarChar( 3 )  Const;
  P_AccessRef           VarChar( 40 ) Const;
  P_SeqMsgTransferNo    VarChar( 2 )  Const;
  P_SeqMsgTransferInd   VarChar( 1 )  Const;
End-PR;

// New INVOIC-specific segment prototypes
Dcl-PR GenerateALC VarChar( 500 );
  P_AllowChargeCode    VarChar( 3 ) Const;
  P_AllowChargeType    VarChar( 3 ) Const;
  P_SettlementCode     VarChar( 3 ) Const Options( *NoPass );
  P_CalcSequence       VarChar( 3 ) Const Options( *NoPass );
  P_SpecServiceCode    VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GeneratePRI VarChar( 500 );
  P_PriceCode          VarChar( 3 ) Const;
  P_PriceAmount        VarChar( 15 ) Const;
  P_PriceType          VarChar( 3 ) Const Options( *NoPass );
  P_PriceBasis         VarChar( 9 ) Const Options( *NoPass );
  P_MeasureUnit        VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateCUX VarChar( 500 );
  P_CurrencyUsageCode  VarChar( 3 ) Const;
  P_CurrencyCode       VarChar( 3 ) Const;
  P_CurrencyQualifier  VarChar( 3 ) Const;
  P_RateOfExchange     VarChar( 12 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateTAX VarChar( 500 );
  P_FunctionQualifier  VarChar( 3 ) Const;
  P_TaxType            VarChar( 3 ) Const;
  P_TaxRate            VarChar( 17 ) Const Options( *NoPass );
  P_TaxCategory        VarChar( 3 ) Const Options( *NoPass );
End-PR;

Dcl-PR GenerateUNS VarChar( 500 );
  P_SectionId          VarChar( 1 ) Const;
End-PR;

// Utility procedure prototypes
Dcl-PR ConvertDateFormat LikeDS(Result);
  P_InputDate Char( 14 ) Const;
  P_FormatCode Int( 10 ) Const;
End-PR;

Dcl-PR getDateTimeChar Char( 15 );
End-PR;

Dcl-PR getDateTimeChar14 Char( 14 );
End-PR;

Dcl-PR getDateTimeCharMicro Char( 22 );
End-PR;

Dcl-PR WriteLineToFile Ind;
  lineText VarChar( 500 ) Const;
  fileHandler Pointer Value;
End-PR;

Dcl-PR LogError;
  P_ErrorMessage VarChar( 1000 ) Const;
  P_KeyField VarChar( 256 ) Const Options( *NoPass );
End-PR;

Dcl-PR JobLogPrint Int( 10 ) ExtProc('Qp0zLprintf');
  String Pointer Value Options(*String);
  p1 Pointer Value Options(*String : *NoPass);
  p2 Pointer Value Options(*String : *NoPass);
  p3 Pointer Value Options(*String : *NoPass);
  p4 Pointer Value Options(*String : *NoPass);
End-PR;

Dcl-PR LoadHDRFromECSVAL_INVOIC Ind;
  P_CustomerNumber VarChar( 50 ) Const;
End-PR;

Dcl-PR FormatDecimal VarChar( 20 );
  P_Value Packed( 15: 4 ) Const;
  P_DecPlaces Int( 10 ) Const;
End-PR;

Dcl-PR FormatLineNumber VarChar( 10 );
  P_LineNum Int( 10 ) Const;
  P_Length Int( 10 ) Const Options( *NoPass );
End-PR;

// File handle Pointer
Dcl-S fHandle Pointer;

Dcl-DS APIERRC_T Qualified Template;
  bytesProvided Int( 10: 0 );
  bytesAvailable Int( 10: 0 );
  exceptionID Char( 7 );
  reserved Char( 1 );
  exceptionData Char( 3000 );
End-DS;

// Include the copy book with IFS API definitions
/copy AGLIB/QCPY,IFSAPIS

//==============================================================================
// M A I N L I N E
//==============================================================================

Exec Sql Set Option Commit = *None, CloSqlCsr = *EndMod;

// Find distinct customers with pending INVOIC records
Exec Sql
  Declare CUSTOMERCUR Scroll Cursor For
  Select Distinct CUSTOMER_NUMBER
  From EDIINVOIC810
  Where PROCESSED_FLAG = 'N'
    And X12EDIFACT = 'EDI';

Exec Sql Open CUSTOMERCUR;

If SqlState <> '00000';
  LogError('Error opening customer cursor. SqlState: ' + SqlState);
  ExSr EndProgram;
EndIf;

Exec Sql Fetch First From CUSTOMERCUR For 50 Rows Into :CustomerNumbers;

Exec Sql Get Diagnostics :CustomerRowsFetched = Row_Count;

If CustomerRowsFetched <= 0;
  LogError('No customers found with pending INVOIC records');
  ExSr EndProgram;
EndIf;

// Loop through each customer
For CustomerCurRow = 1 to CustomerRowsFetched;

  CustomerNumber = %Char(CustomerNumbers(CustomerCurRow).number);

  // Load HDR configuration from ECSVAL/EDITPCX for this customer
  LoadHDRFromECSVAL_INVOIC(CustomerNumber);

  // Load EDFASN data for NAD segments
  Exec Sql
    Select
      EDA003, EDA013, EDA014, EDA015, EDA016,
      EDA017, EDA018, EDA019, EDA020,
      EDA021, EDA022, EDA023, EDA024,
      EDA029, EDA030, EDA031, EDA023
    Into
      :EDFASN_DS.TradingPartner,
      :EDFASN_DS.BY_Qualifier, :EDFASN_DS.BY_Code,
      :EDFASN_DS.BY_CodeQual, :EDFASN_DS.BY_Name,
      :EDFASN_DS.SU_Qualifier, :EDFASN_DS.SU_Code,
      :EDFASN_DS.SU_CodeQual, :EDFASN_DS.SU_Name,
      :EDFASN_DS.SF_Qualifier, :EDFASN_DS.SF_Code,
      :EDFASN_DS.SF_CodeQual, :EDFASN_DS.SF_Name,
      :EDFASN_DS.ST_Qualifier, :EDFASN_DS.ST_Code,
      :EDFASN_DS.ST_CodeQual, :EDFASN_DS.CountryCode
    From EDFASN
    Where EDA001 = :CustomerNumber
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    LogError('No EDFASN record for customer ' + %Trim(CustomerNumber));
  EndIf;

  // Determine customer type for INVOIC-specific logic
  // Derived from ECSVALV1_XREF trading partner name:
  //   ZF-xxx  -> 'ZF'     (all ZF ship-to customers)
  //   VOLVO-x -> 'VOLVO'  (all Volvo ship-to customers)
  //   Others  -> 'STANDARD' (Cummins, etc.)
  TpName = '';
  Exec Sql
    Select e.PREFERREDDISPLAYNAME Into :TpName
    From EDITEST.EDITPCUSTXRREF p
    Join EDITEST.ECSVALV1_XREF e
      On e.ECSVAL_ID = p.ECSVALKEY
    Where p.SHIPTOCUST = :CustomerNumber
      And p.SEND810INVOICE = 'Y'
    Fetch First 1 Row Only;

  Select;
    When %Scan('ZF' : TpName) = 1;
      CustomerType = 'ZF';
    When %Scan('VOLVO' : TpName) = 1;
      CustomerType = 'VOLVO';
    Other;
      CustomerType = 'STANDARD';
  EndSl;

  // Override EDIFACT version/release per customer type (matching EDI031)
  Select;
    When CustomerType = 'STANDARD';
      Pcx_MsgVersion = 'D';
      Pcx_MsgRelease = '97B';
      Pcx_CtlAgency = 'UN';
      Pcx_AssocCode = '';
    When CustomerType = 'ZF';
      Pcx_MsgVersion = 'D';
      Pcx_MsgRelease = '07A';
      Pcx_CtlAgency = 'UN';
      Pcx_AssocCode = 'GAVA11';
    When CustomerType = 'VOLVO';
      Pcx_MsgVersion = 'D';
      Pcx_MsgRelease = '03A';
      Pcx_CtlAgency = 'UN';
      Pcx_AssocCode = '';
  EndSl;

  // Get supplier number from CUSMF based on plant
  // (will be set per invoice in SetPlantNumber/LoadSupplierNumber)

  // Loop through invoices for this customer
  Exec Sql
    Declare INVOICECUR Scroll Cursor For
    Select d.PACKING_SLIP, d.INVOICE_NUMBER,
           w.WPS002 as PICK_LIST
    From EDIINVOIC810 d
    Join WAREPSPL w On d.PACKING_SLIP = w.WPS001
    Where d.CUSTOMER_NUMBER = :CustomerNumber
      And d.PROCESSED_FLAG = 'N'
      And d.X12EDIFACT = 'EDI';

  Exec Sql Open INVOICECUR;

  If SqlState <> '00000';
    LogError('Error opening invoice cursor for customer ' +
             %Trim(CustomerNumber) + '. SqlState: ' + SqlState);
    ExSr EndProgram;
  EndIf;

  Exec Sql Fetch First From INVOICECUR For 50 Rows Into :driverData;

  Exec Sql Get Diagnostics :InvoiceRowsFetched = Row_Count;

  // Mark records as in-process
  Exec Sql
    Update EDIINVOIC810
    Set PROCESSED_FLAG = 'I'
    Where CUSTOMER_NUMBER = :CustomerNumber
      And PROCESSED_FLAG = 'N'
      And X12EDIFACT = 'EDI';

  // Derive missing invoice numbers from IVH021 (IVCHDR/IVCHDRH).
  // A row with INVOICE_NUMBER=0 means the caller passed blank
  // and wants the real number looked up by packing slip.
  ExSr ResolveInvoiceNumbers;

  // Create output file
  InvoiceNumber = %Char(driverData(1).invoiceNumber);

  TempFileName = 'RAW_INV_' + %Trim(InvoiceNumber) +
    '_' + getDateTimeCharMicro() + '.txt';
  FileName = 'WF_INV_' + %Trim(InvoiceNumber) +
    '_' + getDateTimeCharMicro() + '.txt';
  CompleteFilePath = FilePath + TempFileName;
  fHandle = OpenFile(%Trim(CompleteFilePath) : %Trim(Mode));

  If fHandle = *Null;
    LogError('Error opening IFS file: ' + %Trim(CompleteFilePath) :
      InvoiceNumber);
    ExSr EndProgram;
  EndIf;

  For InvoiceCurRow = 1 to InvoiceRowsFetched;
    PackingSlip = %Char(driverData(InvoiceCurRow).packingSlip);
    InvoiceNumber = %Char(driverData(InvoiceCurRow).invoiceNumber);
    PickList = %Char(driverData(InvoiceCurRow).pickList);

    ExSr SetPlantNumber;
    ExSr ProcessInvoice;
  EndFor;

  Exec Sql Close INVOICECUR;

  CloseFile(fHandle);

  // Convert file to UTF-8
  CmdString = 'CALL QP2SHELL PARM(''/QOpenSys/usr/bin/sh'' ''-c'' ' +
      '''/QOpenSys/usr/bin/iconv -f IBM-037 -t UTF-8 < ' +
      %Trim(FilePath) + %Trim(TempFileName) + ' > ' +
      %Trim(FilePath) + %Trim(FileName) + ''')';
  CmdLength = %Len(%Trimr(CmdString));
  CallCmd(CmdString : CmdLength);

  // Remove the temporary file
  CmdString = 'CALL QP2SHELL PARM(''/QOpenSys/usr/bin/sh'' ''-c'' ' +
      '''/QOpenSys/usr/bin/rm -f ' + %Trim(FilePath) +
      %Trim(TempFileName) + ''')';
  CmdLength = %Len(%Trimr(CmdString));
  CallCmd(CmdString : CmdLength);

  CompleteFilePath = FilePath + FileName;

  Exec Sql
    Update EDIINVOIC810
    Set PROCESSED_FLAG = 'Y',
        FILE_PATH = :CompleteFilePath
    Where CUSTOMER_NUMBER = :CustomerNumber
      And PROCESSED_FLAG = 'I'
      And X12EDIFACT = 'EDI';

EndFor;

Exec Sql Close CUSTOMERCUR;

ExSr EndProgram;

//==============================================================================
// E N D  M A I N L I N E
//==============================================================================

//==============================================================================
// ProcessInvoice - Generate EDIFACT INVOIC message for one invoice
//==============================================================================
BegSr ProcessInvoice;

  // Reset segment count for new message
  SegmentCount = 1;

  // Reset totals
  InvoiceTotal = 0;
  BaseTotal = 0;
  SurchargeTotal = 0;
  EnergySurTotal = 0;
  PaintSurTotal = 0;
  AmortTotal = 0;
  DunnageTotal = 0;
  DunnagePNTotal = 0;
  DunmagePCTotal = 0;
  LineItemNumber = 0;

  // Load packing slip data from WAREPSPL
  Exec Sql
    Select WPS001, WPS002, WPS006, WPS007
    Into :packingSlipDS
    From WAREPSPL
    Where WPS001 = :PackingSlip
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    LogError('WAREPSPL not found for PS ' + %Trim(PackingSlip));
    LeaveSr;
  EndIf;

  // Load invoice header from IVCHDR (current) or IVCHDRH (history)
  Exec Sql
    Select IVH001, IVH002, IVH003, IVH004, IVH005, IVH006,
           IVH007, IVH008, IVH017, IVH018, IVH021, IVH022, IVH027
    Into :invoiceHeaderDS
    From IVCHDR
    Where IVH001 = :PackingSlip
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    Exec Sql
      Select IVH001, IVH002, IVH003, IVH004, IVH005, IVH006,
             IVH007, IVH008, IVH017, IVH018, IVH021, IVH022, IVH027
      Into :invoiceHeaderDS
      From IVCHDRH
      Where IVH001 = :PackingSlip
      Fetch First 1 Row Only;

    If SqlState <> '00000';
      LogError('Invoice header not found for PS ' + %Trim(PackingSlip));
      LeaveSr;
    EndIf;
  EndIf;

  // Validate - skip if CMF066 (EDI invoicing flag) is not Y
  Exec Sql
    Select CMF066 Into :Message
    From CUSMF
    Where CMF001 = :CustomerNumber
    Fetch First 1 Row Only;

  If SqlState <> '00000' Or %Trim(Message) <> 'Y';
    LeaveSr;
  EndIf;

  // Load supplier number based on plant
  ExSr LoadSupplierNumber;

  // Build the document date from WAREPSPL or IVCHDR
  If packingSlipDS.WPS006 > 0;
    ConstructedDate = %Char(packingSlipDS.WPS006) +
                      %EditC(packingSlipDS.WPS007 : 'X');
  ElseIf invoiceHeaderDS.IVH022 > 0;
    ConstructedDate = %Char(invoiceHeaderDS.IVH022) +
                      %EditC(invoiceHeaderDS.IVH027 : 'X');
  Else;
    ConstructedDate = getDateTimeChar14();
  EndIf;

  // Format the date according to customer date format
  DateResult = ConvertDateFormat(ConstructedDate : 102);

  //------------------------------------------------------------
  // UNA - Service String Advice
  //------------------------------------------------------------
  Message = GenerateUNA();
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // HDR - Interchange/Group header
  //------------------------------------------------------------
  Message = GenerateHDR(
    HDR_DS.GroupFuncCode : HDR_DS.SenderQual :
    HDR_DS.SenderID : HDR_DS.RecipQual :
    HDR_DS.RecipID : HDR_DS.InterchgCtrlNum :
    HDR_DS.GroupSenderID : HDR_DS.GroupRecipID :
    HDR_DS.GroupCtrlNum : HDR_DS.GroupDate :
    HDR_DS.GroupTime : HDR_DS.TransCtrlNum :
    HDR_DS.GroupVerRel : HDR_DS.TransType :
    HDR_DS.Agency : HDR_DS.InterchgVer :
    HDR_DS.InterchgDate : HDR_DS.InterchgTime :
    HDR_DS.TestInd : HDR_DS.SyntaxId :
    HDR_DS.SyntaxVerNo : HDR_DS.RecipPass :
    HDR_DS.RecipPassQual : HDR_DS.AppRef :
    HDR_DS.AckReq : HDR_DS.PriorCode :
    HDR_DS.CommAgrmtID : HDR_DS.MessageRefNum :
    HDR_DS.ControllingAgency : HDR_DS.AccessRef :
    HDR_DS.SeqMsgTransferNo : HDR_DS.SeqMsgTransferInd);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // UNH - Message Header (INVOIC)
  //------------------------------------------------------------
  Message = GenerateUNH(
    HDR_DS.MessageRefNum :
    'INVOIC' :
    Pcx_MsgVersion :
    Pcx_MsgRelease :
    Pcx_CtlAgency :
    Pcx_AssocCode);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // BGM - Beginning of Message (380 = Commercial Invoice)
  //------------------------------------------------------------
  Message = GenerateBGM(
    '380' :
    %Trim(%Char(invoiceHeaderDS.IVH021)) :
    '9');
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // DTM - Date/Time segments
  //------------------------------------------------------------
  // Customer-specific DTM segments
  Select;
    When CustomerType = 'STANDARD';
      // DTM+3 - Invoice date only (Cummins/Standard - no DTM+137)
      Message = GenerateDTM('3' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

    When CustomerType = 'ZF';
      // DTM+137 - Document/message date
      Message = GenerateDTM('137' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      // DTM+1 - Processing date
      Message = GenerateDTM('1' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

    When CustomerType = 'VOLVO';
      // DTM+158 - Tax point date
      Message = GenerateDTM('158' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      // DTM+159 - Payment due date
      Message = GenerateDTM('159' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
  EndSl;

  //------------------------------------------------------------
  // RFF - Reference segments
  //------------------------------------------------------------
  // RFF+ON - Purchase order (read first PO from IVCPRT)
  Exec Sql
    Select IVP003 Into :Message
    From IVCPRT
    Where IVP001 = :PackingSlip
      And Trim(IVP003) <> ''
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    Exec Sql
      Select IVP003 Into :Message
      From IVCPRTH
      Where IVP001 = :PackingSlip
        And Trim(IVP003) <> ''
      Fetch First 1 Row Only;
  EndIf;

  If SqlState = '00000' And %Trim(Message) <> '';
    WriteLineToFile(GenerateRFF('ON' : %Trim(Message)) +
      NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  // RFF+PK - Packing slip reference (Cummins/Standard)
  If CustomerType = 'STANDARD';
    Message = GenerateRFF('PK' : %Trim(PackingSlip));
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  // RFF+IV - Invoice reference (ZF)
  If CustomerType = 'ZF';
    Message = GenerateRFF('IV' :
      %Trim(%Char(invoiceHeaderDS.IVH021)));
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  //------------------------------------------------------------
  // NAD - Name and Address segments
  //------------------------------------------------------------
  // NAD+IV - Invoicee (from EDFASN)
  Message = GenerateNAD('IV' :
    EDFASN_DS.SF_Code : EDFASN_DS.SF_CodeQual :
    EDFASN_DS.SF_Name);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  // NAD+BY - Buyer (from EDFASN)
  Message = GenerateNAD('BY' :
    EDFASN_DS.ST_Code : EDFASN_DS.ST_CodeQual);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  // NAD+SE - Seller (plant DUNS from CUSMF)
  Message = GenerateNAD('SE' :
    SupplierNumber : '92' :
    'WAUPACA FOUNDRY, INC.');
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  // Customer-specific NAD segments
  If CustomerType = 'STANDARD';
    // NAD+SF - Ship From (supplier code + name)
    Message = GenerateNAD('SF' :
      SupplierNumber : '92' :
      'WAUPACA FOUNDRY, INC.');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // NAD+ST - Ship To (from EDFASN + ship-to name)
    // Load ship-to name from invoice header or CUSTADRS
    NAD_DS.ST_Name = '';
    Exec Sql
      Select Trim(CAD003)
      Into :NAD_DS.ST_Name
      From CUSTADRS
      Where CAD001 = :CustomerNumber And CAD002 = 2
      Fetch First 1 Row Only;
    If SqlState <> '00000' Or NAD_DS.ST_Name = '';
      NAD_DS.ST_Name = %Trim(invoiceHeaderDS.IVH003);
    EndIf;

    Message = GenerateNAD('ST' :
      EDFASN_DS.ST_Code : EDFASN_DS.ST_CodeQual :
      '' : NAD_DS.ST_Name);
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  If CustomerType = 'ZF';
    // NAD+SF - Ship From
    Message = GenerateNAD('SF' :
      EDFASN_DS.SF_Code : EDFASN_DS.SF_CodeQual :
      EDFASN_DS.SF_Name);
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // NAD+PE - Payee
    Message = GenerateNAD('PE' :
      SupplierNumber : '92' :
      'WAUPACA FOUNDRY, INC.');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // RFF+VA - VAT registration (empty - not maintained in system)
    Message = GenerateRFF('VA' : '');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // NAD+ST - Ship To (from EDFASN + CUSTADRS)
    Message = GenerateNAD('ST' :
      EDFASN_DS.ST_Code : EDFASN_DS.ST_CodeQual);
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  If CustomerType = 'VOLVO';
    // NAD+PE - Payee
    Message = GenerateNAD('PE' :
      SupplierNumber : '92' :
      'WAUPACA FOUNDRY, INC.');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  //------------------------------------------------------------
  // CUX - Currency segment
  //------------------------------------------------------------
  If CustomerType = 'VOLVO';
    Message = GenerateCUX('2' : 'USD' : '4');
  Else;
    Message = GenerateCUX('1' : 'USD' : '4');
  EndIf;
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // DETAIL LOOP - Invoice line items from IVCPRT/IVCPRTH
  //------------------------------------------------------------
  Exec Sql
    Declare DETAILCUR Scroll Cursor For
    Select IVP001, IVP002, IVP003, IVP008, IVP009, IVP010,
           IVP012, IVP017, IVP019, IVP020, IVP021, IVP022,
           IVP023, IVP024, IVP025, IVP026, IVP027, IVP031,
           IVP033, IVP035,
           ROW_NUMBER() OVER () as LINE_NUM
    From IVCPRT
    Where IVP001 = :PackingSlip
    Order By IVP002;

  UsingHistoryDetail = *Off;
  Exec Sql Open DETAILCUR;
  Exec Sql Fetch Next From DETAILCUR Into :invoiceDetailDS;

  // If no rows in IVCPRT, fallback to IVCPRTH (history)
  If SqlState <> '00000';
    Exec Sql Close DETAILCUR;

    Exec Sql
      Declare DETAILCURH Scroll Cursor For
      Select IVP001, IVP002, IVP003, IVP008, IVP009, IVP010,
             IVP012, IVP017, IVP019, IVP020, IVP021, IVP022,
             IVP023, IVP024, IVP025, IVP026, IVP027, IVP031,
             IVP033, IVP035,
             ROW_NUMBER() OVER () as LINE_NUM
      From IVCPRTH
      Where IVP001 = :PackingSlip
      Order By IVP002;

    Exec Sql Open DETAILCURH;
    Exec Sql Fetch Next From DETAILCURH Into :invoiceDetailDS;
    UsingHistoryDetail = *On;
  EndIf;

  Dow SqlState = '00000';

    // Skip blank parts or zero qty/price
    If %Trim(invoiceDetailDS.IVP002) = '' Or
       invoiceDetailDS.IVP008 = 0 Or
       invoiceDetailDS.IVP009 = 0;
      If UsingHistoryDetail;
        Exec Sql Fetch Next From DETAILCURH Into :invoiceDetailDS;
      Else;
        Exec Sql Fetch Next From DETAILCUR Into :invoiceDetailDS;
      EndIf;
      Iter;
    EndIf;

    LineItemNumber += 1;
    FormattedLineNum = FormatLineNumber(LineItemNumber);

    // Get part description from PARTFILE/PRTDSC01
    Exec Sql
      Select Trim(PDS003)
      Into :PartDescription
      From PARTFILE
      Join PRTDSC01 On PTF016 = PDS002
      Where PTF001 = :invoiceDetailDS.IVP002
      Fetch First 1 Row Only;

    If SqlState <> '00000';
      PartDescription = %Trim(invoiceDetailDS.IVP002);
    EndIf;

    // Get amortization per piece from PARTFILE
    Exec Sql
      Select COALESCE(PTF022, 0)
      Into :AmortPerPiece
      From PARTFILE
      Where PTF001 = :invoiceDetailDS.IVP002
      Fetch First 1 Row Only;

    If SqlState <> '00000';
      AmortPerPiece = 0;
    EndIf;

    // IVCPARTS cross-reference: use customer preferred part if exists
    BuyerPartNumber = GetBuyerPartNumber(
      %Trim(invoiceDetailDS.IVP002) :
      %Trim(invoiceDetailDS.IVP003) :
      CustomerNumber);

    // LIN - Line item (use cross-referenced part if found)
    Message = GenerateLIN(FormattedLineNum : 'IN' :
      %Trim(BuyerPartNumber));
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // LOC+US - Country of origin (Volvo only)
    If CustomerType = 'VOLVO';
      Message = GenerateLOC('US');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // IMD - Item description
    Message = GenerateIMD('F' : '' : '' : '' : PartDescription);
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // QTY - Quantity (47=Cummins/ZF invoiced, 12=Volvo despatch)
    If CustomerType = 'VOLVO';
      Message = GenerateQTY('12' :
        %Trim(%Char(invoiceDetailDS.IVP008)) : 'EA');
    Else;
      Message = GenerateQTY('47' :
        %Trim(%Char(invoiceDetailDS.IVP008)) : 'EA');
    EndIf;
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // ALI+US - Country of origin (Standard/Cummins)
    If CustomerType = 'STANDARD';
      Message = GenerateALI('US');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // MOA+203 - Line item amount
    If CustomerType = 'STANDARD';
      // STANDARD/Cummins: combined price (base+sur+eng) * qty
      Message = GenerateMOA('203' :
        FormatDecimal((invoiceDetailDS.IVP009 +
          invoiceDetailDS.IVP010 +
          invoiceDetailDS.IVP033) *
          invoiceDetailDS.IVP008 : 2));
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    ElseIf CustomerType = 'ZF';
      // ZF: base price * qty
      Message = GenerateMOA('203' :
        FormatDecimal(invoiceDetailDS.IVP009 *
          invoiceDetailDS.IVP008 : 2) : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // MOA+38 - Extended price (ZF/Volvo: (price+sur+eng) * qty)
    If CustomerType = 'ZF' Or CustomerType = 'VOLVO';
      Message = GenerateMOA('38' :
        FormatDecimal((invoiceDetailDS.IVP009 +
          invoiceDetailDS.IVP010 +
          invoiceDetailDS.IVP033) *
          invoiceDetailDS.IVP008 : 2) : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // PRI - Price details (customer-specific)
    Select;
      When CustomerType = 'STANDARD';
        // PRI+INV - Invoice price (combined: base+sur+eng)
        Message = GeneratePRI('INV' :
          FormatDecimal(invoiceDetailDS.IVP009 +
            invoiceDetailDS.IVP010 +
            invoiceDetailDS.IVP033 : 2));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;

      When CustomerType = 'ZF';
        // PRI+CON - Contract price
        Message = GeneratePRI('CON' :
          FormatDecimal(invoiceDetailDS.IVP009 : 2));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;

        // PRI+AAA - Total price (price + surcharge + eng)
        Message = GeneratePRI('AAA' :
          FormatDecimal(invoiceDetailDS.IVP009 +
            invoiceDetailDS.IVP010 +
            invoiceDetailDS.IVP033 : 2));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;

      When CustomerType = 'VOLVO';
        // PRI+AAB - Net price
        Message = GeneratePRI('AAB' :
          FormatDecimal(invoiceDetailDS.IVP009 : 2));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;
    EndSl;

    // RFF at detail level
    If CustomerType = 'ZF';
      // RFF+AAU - Dispatch note reference
      Message = GenerateRFF('AAU' : %Trim(PackingSlip));
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      // RFF+ON - Order number with release
      If %Trim(invoiceDetailDS.IVP003) <> '';
        Message = GenerateRFF('ON' :
          %Trim(invoiceDetailDS.IVP003));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;
      EndIf;

      // DTM+1 - Service completion date (per line item)
      Message = GenerateDTM('1' : DateResult.FormattedDate : '102');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    If CustomerType = 'VOLVO';
      // RFF+AAK - Delivery note reference
      Message = GenerateRFF('AAK' : %Trim(PackingSlip));
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      // RFF+ON - Order number
      If %Trim(invoiceDetailDS.IVP003) <> '';
        Message = GenerateRFF('ON' :
          %Trim(invoiceDetailDS.IVP003));
        WriteLineToFile(Message + NEW_LINE : fHandle);
        ExSr ClearMessage;
      EndIf;

      // TAX+7 - VAT at detail level
      Message = GenerateTAX('7' : 'VAT' : '0.0');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      // MOA+124 - Tax amount
      Message = GenerateMOA('124' : '0.00' : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // Accumulate totals
    BaseTotal += invoiceDetailDS.IVP009 * invoiceDetailDS.IVP008;
    SurchargeTotal += invoiceDetailDS.IVP010 * invoiceDetailDS.IVP008;
    EnergySurTotal += invoiceDetailDS.IVP033 * invoiceDetailDS.IVP008;
    PaintSurTotal += invoiceDetailDS.IVP012 * invoiceDetailDS.IVP008;
    AmortTotal += AmortPerPiece * invoiceDetailDS.IVP008;

    // Accumulate dunnage totals per line
    ExSr AccumulateDunnage;

    If UsingHistoryDetail;
      Exec Sql Fetch Next From DETAILCURH Into :invoiceDetailDS;
    Else;
      Exec Sql Fetch Next From DETAILCUR Into :invoiceDetailDS;
    EndIf;
  EndDo;

  If UsingHistoryDetail;
    Exec Sql Close DETAILCURH;
  Else;
    Exec Sql Close DETAILCUR;
  EndIf;

  // Calculate invoice total
  // ZF: exclude dunnage (matches mailbox EDI031 - EDI021 = base+sur+eng)
  If CustomerType = 'ZF';
    InvoiceTotal = BaseTotal + SurchargeTotal + EnergySurTotal;
  Else;
    InvoiceTotal = BaseTotal + SurchargeTotal + EnergySurTotal +
                   DunnageTotal;
  EndIf;

  //------------------------------------------------------------
  // UNS - Section separator
  //------------------------------------------------------------
  Message = GenerateUNS('S');
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // Summary MOA segments
  //------------------------------------------------------------
  If CustomerType = 'VOLVO';
    // MOA+128 - Total amount (including dunnage)
    Message = GenerateMOA('128' :
      FormatDecimal(InvoiceTotal + DunnageTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+79 - Total line items amount (base price only)
    Message = GenerateMOA('79' :
      FormatDecimal(BaseTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+77 - Invoice total
    Message = GenerateMOA('77' :
      FormatDecimal(InvoiceTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+176 - Message total duty/tax (0 for US domestic)
    Message = GenerateMOA('176' : '0.00' : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+403 - Total charges/allowances
    Message = GenerateMOA('403' :
      FormatDecimal(SurchargeTotal + EnergySurTotal +
        DunnageTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+125 - Total taxable amount
    Message = GenerateMOA('125' : '0.00' : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // TAX+7 - Summary tax
    Message = GenerateTAX('7' : 'VAT' : '0.0');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+124 after TAX
    Message = GenerateMOA('124' : '0.00' : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

  ElseIf CustomerType = 'ZF';
    // MOA+77 - Invoice total
    Message = GenerateMOA('77' :
      FormatDecimal(InvoiceTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+125 - Total taxable
    Message = GenerateMOA('125' : '0.00' : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+176 - Total duty/tax
    Message = GenerateMOA('176' : '0.00' : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // MOA+79 - Total line items (same as MOA+77 for ZF per EDI031)
    Message = GenerateMOA('79' :
      FormatDecimal(InvoiceTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

  Else;
    // Standard/Cummins: MOA+77 - Invoice total
    Message = GenerateMOA('77' :
      FormatDecimal(InvoiceTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    // Standard/Cummins: MOA+39 - Invoice total
    Message = GenerateMOA('39' :
      FormatDecimal(InvoiceTotal : 2) : 'USD');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  //------------------------------------------------------------
  // ALC - Allowance/Charge segments (if nonzero)
  //------------------------------------------------------------
  // For STANDARD: surcharges are embedded in MOA+203/PRI, so skip
  // ALC+SC, ALC+ABG, ALC+ABK. Only dunnage (PN/PC) is separate.
  If CustomerType <> 'STANDARD';
    // ALC+SC - Surcharge (if surcharge + energy total > 0)
    If SurchargeTotal + EnergySurTotal > 0;
      Message = GenerateALC('C' : 'SC');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      Message = GenerateMOA('8' :
        FormatDecimal(SurchargeTotal + EnergySurTotal : 2) : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // ALC+ABG - Amortization (if nonzero)
    If AmortTotal > 0;
      Message = GenerateALC('C' : 'ABG');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      Message = GenerateMOA('8' :
        FormatDecimal(AmortTotal : 2) : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;

    // ALC+ABK - Paint/oil (if nonzero)
    If PaintSurTotal > 0;
      Message = GenerateALC('C' : 'ABK');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;

      Message = GenerateMOA('8' :
        FormatDecimal(PaintSurTotal : 2) : 'USD');
      WriteLineToFile(Message + NEW_LINE : fHandle);
      ExSr ClearMessage;
    EndIf;
  EndIf;

  // ALC+PN - Packing/returnable dunnage
  // ZF: skip dunnage ALC (EDIDUNN has $0 prices; mailbox has none)
  If DunnagePNTotal > 0 And CustomerType <> 'ZF';
    Message = GenerateALC('C' : 'PN');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    If CustomerType = 'STANDARD';
      Message = GenerateMOA('23' :
        FormatDecimal(DunnagePNTotal : 2));
    Else;
      Message = GenerateMOA('23' :
        FormatDecimal(DunnagePNTotal : 2) : 'USD');
    EndIf;
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  // ALC+PC - Packing costs/non-returnable dunnage
  // ZF: skip dunnage ALC (EDIDUNN has $0 prices; mailbox has none)
  If DunmagePCTotal > 0 And CustomerType <> 'ZF';
    Message = GenerateALC('C' : 'PC');
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;

    If CustomerType = 'STANDARD';
      Message = GenerateMOA('23' :
        FormatDecimal(DunmagePCTotal : 2));
    Else;
      Message = GenerateMOA('23' :
        FormatDecimal(DunmagePCTotal : 2) : 'USD');
    EndIf;
    WriteLineToFile(Message + NEW_LINE : fHandle);
    ExSr ClearMessage;
  EndIf;

  //------------------------------------------------------------
  // UNT - Message trailer
  //------------------------------------------------------------
  Message = GenerateUNT(
    %Trim(%Char(SegmentCount)) :
    HDR_DS.MessageRefNum);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

  //------------------------------------------------------------
  // UNZ - Interchange trailer
  //------------------------------------------------------------
  Message = GenerateUNZ('1' : HDR_DS.InterchgCtrlNum);
  WriteLineToFile(Message + NEW_LINE : fHandle);
  ExSr ClearMessage;

EndSr;

//==============================================================================
// SetPlantNumber - Get plant number from IVCHDR/IVCHDRH
//==============================================================================
BegSr SetPlantNumber;
  Exec Sql
    Select IVH018
    Into :PlantNumber
    From IVCHDR
    Where IVH001 = :PackingSlip
    Fetch First 1 ROW ONLY;

  If SqlState = '00000';
    FndInPrimaryInvoice = *On;
  Else;
    FndInPrimaryInvoice = *Off;

    Exec Sql
      Select IVH018
      Into :PlantNumber
      From IVCHDRH
      Where IVH001 = :PackingSlip
      Fetch First 1 ROW ONLY;

    If SqlState <> '00000';
      JobLogPrint('Set Plant Number: PS %s not found in IVCHDR/IVCHDRH'
          + X'25' : PackingSlip);
      LogError('Set Plant Number: PS ' + %Trim(PackingSlip) +
               ' not found. SqlState: ' + SqlState : PickList);
      ExSr EndProgram;
    EndIf;
  EndIf;
EndSr;

//==============================================================================
// LoadSupplierNumber - Get plant DUNS from CUSMF based on plant
//==============================================================================
BegSr LoadSupplierNumber;
  Exec Sql
    Select
      CASE
        WHEN :PlantNumber = '1' THEN Trim(CMF074)
        WHEN :PlantNumber = '2' THEN Trim(CMF075)
        WHEN :PlantNumber = '3' THEN Trim(CMF076)
        WHEN :PlantNumber = '4' THEN Trim(CMF077)
        WHEN :PlantNumber = '5' THEN Trim(CMF092)
        WHEN :PlantNumber = '6' THEN Trim(CMF093)
        WHEN :PlantNumber = '7' THEN Trim(CMF094)
        WHEN :PlantNumber = '8' THEN Trim(CMF095)
        ELSE ''
      END
    Into :SupplierNumber
    From CUSMF
    Where CMF001 = :CustomerNumber
    Fetch First 1 Row Only;

  If SqlState <> '00000';
    SupplierNumber = '';
    LogError('CUSMF not found for customer ' + %Trim(CustomerNumber));
  EndIf;
EndSr;

//==============================================================================
// AccumulateDunnage - Process dunnage charges for current detail line
//==============================================================================
BegSr AccumulateDunnage;

  // Process up to 4 dunnage slots per detail line
  For dngIdx = 1 to 4;
    dngDesc = *Blanks;
    dngQty = 0;
    dngPrice = 0;

    Select;
      When dngIdx = 1;
        dngDesc = invoiceDetailDS.IVP019;
        dngQty = invoiceDetailDS.IVP020;
      When dngIdx = 2;
        dngDesc = invoiceDetailDS.IVP021;
        dngQty = invoiceDetailDS.IVP022;
      When dngIdx = 3;
        dngDesc = invoiceDetailDS.IVP023;
        dngQty = invoiceDetailDS.IVP024;
      When dngIdx = 4;
        dngDesc = invoiceDetailDS.IVP025;
        dngQty = invoiceDetailDS.IVP026;
    EndSl;

    If %Trim(dngDesc) = '' Or dngQty <= 0;
      Iter;
    EndIf;

    // Check DUNUSAGE - skip if DNU014 = 'Y'
    dngSkip = 'N';
    Exec Sql
      Select DNU014 Into :dngSkip
      From DUNUSAGE
      Where DNU001 = :CustomerNumber
        And DNU002 = :dngDesc
      Fetch First 1 Row Only;

    If SqlState = '00000' And dngSkip = 'Y';
      Iter;
    EndIf;

    // Get selling price and returnable flag from DUNNAGE
    dngReturnable = 'N';
    Exec Sql
      Select DNG004, DNG007 Into :dngPrice, :dngReturnable
      From DUNNAGE
      Where DNG001 = :dngDesc
      Fetch First 1 Row Only;

    If SqlState = '00000' And dngPrice > 0;
      DunnageTotal += dngPrice * dngQty;
      // Split by returnable: Y=PN (packing), N=PC (packing costs)
      If dngReturnable = 'Y';
        DunnagePNTotal += dngPrice * dngQty;
      Else;
        DunmagePCTotal += dngPrice * dngQty;
      EndIf;
    EndIf;
  EndFor;
EndSr;

BegSr ClearMessage;
  Message = *Blanks;
EndSr;

//==============================================================================
// ResolveInvoiceNumbers - For any driverData row with invoiceNumber = 0,
// look up IVH021 from IVCHDR/IVCHDRH by packing slip and back-fill the
// EDIINVOIC810 tracking table. A zero value means the caller (INVTEST,
// INVDRIVER, or manual) passed blank and asked us to derive.
//==============================================================================
BegSr ResolveInvoiceNumbers;
  For WkIdx = 1 to InvoiceRowsFetched;
    If driverData(WkIdx).invoiceNumber <> 0;
      Iter;
    EndIf;

    WkPS = driverData(WkIdx).packingSlip;
    WkIVH021 = 0;

    Exec Sql
      Select IVH021 Into :WkIVH021
      From IVCHDR
      Where IVH001 = :WkPS
      Fetch First 1 Row Only;

    If SqlState <> '00000';
      Exec Sql
        Select IVH021 Into :WkIVH021
        From IVCHDRH
        Where IVH001 = :WkPS
        Fetch First 1 Row Only;
    EndIf;

    If WkIVH021 = 0;
      LogError('Cannot derive invoice number - no IVH021 for PS ' +
               %Char(WkPS));
      Iter;
    EndIf;

    driverData(WkIdx).invoiceNumber = WkIVH021;

    Exec Sql
      Update EDIINVOIC810
      Set INVOICE_NUMBER = :WkIVH021
      Where PACKING_SLIP = :WkPS
        And CUSTOMER_NUMBER = :CustomerNumber
        And INVOICE_NUMBER = 0
        And X12EDIFACT = 'EDI'
        And PROCESSED_FLAG = 'I';
  EndFor;
EndSr;

BegSr EndProgram;
  *InLr = *On;
  Return;
EndSr;

//==============================================================================
// *PSSR - Program Status Subroutine (Error Handler)
//==============================================================================
BegSr *PSSR;
  PsrErrMsg = 'Runtime error ' + %Trim(ExcpMsgId) +
              ' at line ' + %Trim(ExcpLineNumber) +
              ': ' + %Trim(ExcpData);

  If PackingSlip <> *Blanks;
    PsrKeyInfo = 'PS:' + %Trim(PackingSlip);
    If InvoiceNumber <> *Blanks;
      PsrKeyInfo += ' INV:' + %Trim(InvoiceNumber);
    EndIf;
  Else;
    PsrKeyInfo = 'Unknown context';
  EndIf;

  LogError(PsrErrMsg : PsrKeyInfo);
  Return;
EndSr;

//==============================================================================
// S U B P R O C E D U R E S
//==============================================================================

//-------------------------------------------------------------------
// LogError - Logs error messages to ERRLOG table
//-------------------------------------------------------------------
Dcl-Proc LogError;
  Dcl-Pi LogError;
    P_ErrorMessage VarChar( 1000 ) Const;
    P_KeyField VarChar( 256 ) Const Options( *NoPass );
  End-Pi;

  Dcl-S keyField VarChar( 256 );
  Dcl-S programName Char( 10 ) Inz( 'INVOICE');
  Dcl-S errorMessage VarChar( 1000 );

  errorMessage = P_ErrorMessage;

  If %Parms() >= 2;
    keyField = P_KeyField;
  Else;
    keyField = '';
  EndIf;

  Exec Sql
    Insert Into EDITEST.ERRLOG
      (ERR_PROGRAM, ERR_KEYFIELD, ERR_MESSAGE)
    VALUES
      (:programName, :keyField, :errorMessage);

  If SqlState <> '00000';
    // Silently handle to prevent recursive issues
  EndIf;

End-Proc;

//-------------------------------------------------------------------
// PadField - Pads a field to a specific length for fixed-width format
//-------------------------------------------------------------------
Dcl-Proc PadField Export;
Dcl-Pi PadField VarChar( 512 );
  P_FieldValue VarChar( 512 ) Const;
  P_FieldLength Int( 10 ) Const;
End-Pi;

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
// PadWithZeros - Left-pads a numeric value with leading zeros
//-------------------------------------------------------------------
Dcl-Proc PadWithZeros Export;
Dcl-Pi PadWithZeros VarChar(20);
  P_Value  Packed(15:0) Const;
  P_Length Int(10) Const;
End-Pi;

Dcl-S Result VarChar(20);

Result = %Char(P_Value);

Dow %Len(Result) < P_Length;
  Result = '0' + Result;
EndDo;

Return Result;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNA - Service String Advice segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNA Export;
Dcl-Pi GenerateUNA VarChar( 9 );
  P_CompDataSep      VarChar( 1 ) Const Options( *NoPass );
  P_DataElemSep      VarChar( 1 ) Const Options( *NoPass );
  P_DecimalNotation  VarChar( 1 ) Const Options( *NoPass );
  P_ReleaseIndicator VarChar( 1 ) Const Options( *NoPass );
  P_Reserved         VarChar( 1 ) Const Options( *NoPass );
  P_SegTerminator    VarChar( 1 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_UNASegment VarChar( 9 );
Dcl-S compDataSep      VarChar( 1 );
Dcl-S dataElemSep      VarChar( 1 );
Dcl-S decimalNotation  VarChar( 1 );
Dcl-S releaseIndicator VarChar( 1 );
Dcl-S reserved         VarChar( 1 );
Dcl-S segTerminator    VarChar( 1 );

compDataSep      = ':';
dataElemSep      = '+';
decimalNotation  = '.';
releaseIndicator = '?';
reserved         = ' ';
segTerminator    = '''';

If %Parms() >= 1 and P_CompDataSep <> '';
  compDataSep = P_CompDataSep;
EndIf;
If %Parms() >= 2 and P_DataElemSep <> '';
  dataElemSep = P_DataElemSep;
EndIf;
If %Parms() >= 3 and P_DecimalNotation <> '';
  decimalNotation = P_DecimalNotation;
EndIf;
If %Parms() >= 4 and P_ReleaseIndicator <> '';
  releaseIndicator = P_ReleaseIndicator;
EndIf;
If %Parms() >= 5 and P_Reserved <> '';
  reserved = P_Reserved;
EndIf;
If %Parms() >= 6 and P_SegTerminator <> '';
  segTerminator = P_SegTerminator;
EndIf;

r_UNASegment = 'UNA' +
                 PadField(compDataSep : 1 ) +
                 PadField(dataElemSep : 1 ) +
                 PadField(decimalNotation : 1 ) +
                 PadField(releaseIndicator : 1 ) +
                 PadField(reserved : 1 ) +
                 PadField(segTerminator : 1 );

Return r_UNASegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNB - Interchange header segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNB Export;
Dcl-Pi GenerateUNB VarChar( 500 );
  P_SyntaxId     VarChar( 10 ) Const;
  P_SyntaxVer    VarChar( 10 ) Const;
  P_SenderID     VarChar( 35 ) Const;
  P_SenderQual   VarChar( 10 ) Const;
  P_RecipID      VarChar( 35 ) Const;
  P_RecipQual    VarChar( 10 ) Const;
  P_PrepDate     VarChar( 6 ) Const;
  P_PrepTime     VarChar( 4 ) Const;
  P_ControlRef   VarChar( 35 ) Const;
  P_RecipPass    VarChar( 35 ) Const Options( *NoPass );
  P_AppRef       VarChar( 35 ) Const Options( *NoPass );
  P_PriorCode    VarChar( 1 ) Const Options( *NoPass );
  P_AckReq       VarChar( 1 ) Const Options( *NoPass );
  P_CommAgrmtID  VarChar( 35 ) Const Options( *NoPass );
  P_TestInd      VarChar( 1 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_UNBSegment VarChar( 500 );
Dcl-S tempRecipPass VarChar( 35 );
Dcl-S tempAppRef VarChar( 35 );
Dcl-S tempPriorCode VarChar( 1 );
Dcl-S tempAckReq VarChar( 1 );
Dcl-S tempCommAgrmtID VarChar( 35 );
Dcl-S tempTestInd VarChar( 1 );

tempRecipPass = '';
tempAppRef = '';
tempPriorCode = '';
tempAckReq = '';
tempCommAgrmtID = '';
tempTestInd = '';

If %Parms() >= 10;
  tempRecipPass = P_RecipPass;
EndIf;
If %Parms() >= 11;
  tempAppRef = P_AppRef;
EndIf;
If %Parms() >= 12;
  tempPriorCode = P_PriorCode;
EndIf;
If %Parms() >= 13;
  tempAckReq = P_AckReq;
EndIf;
If %Parms() >= 14;
  tempCommAgrmtID = P_CommAgrmtID;
EndIf;
If %Parms() >= 15;
  tempTestInd = P_TestInd;
EndIf;

r_UNBSegment = 'UNB';
r_UNBSegment += PadField(P_SyntaxId : 10 );
r_UNBSegment += PadField(P_SyntaxVer : 10 );
r_UNBSegment += PadField(P_SenderID : 35 );
r_UNBSegment += PadField(P_SenderQual : 10 );
r_UNBSegment += PadField(P_RecipID : 35 );
r_UNBSegment += PadField(P_RecipQual : 10 );
r_UNBSegment += PadField(P_PrepDate : 6 );
r_UNBSegment += PadField(P_PrepTime : 4 );
r_UNBSegment += PadField(P_ControlRef : 35 );
r_UNBSegment += PadField(tempRecipPass : 35 );
r_UNBSegment += PadField(tempAppRef : 35 );
r_UNBSegment += PadField(tempPriorCode : 1 );
r_UNBSegment += PadField(tempAckReq : 1 );
r_UNBSegment += PadField(tempCommAgrmtID : 35 );
r_UNBSegment += PadField(tempTestInd : 1 );

Return r_UNBSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNH - Message header segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNH Export;
Dcl-Pi GenerateUNH VarChar( 500 );
  P_MessageRefNum   VarChar( 14 ) Const;
  P_MessageType     VarChar( 6 ) Const;
  P_MessageVersion  VarChar( 3 ) Const;
  P_MessageRelease  VarChar( 3 ) Const;
  P_ControllingAgency VarChar( 2 ) Const;
  P_AssocCode       VarChar( 6 ) Const Options( *NoPass );
  P_AccessRef       VarChar( 35 ) Const Options( *NoPass );
  P_StatusIndCode   VarChar( 1 ) Const Options( *NoPass );
  P_MessageSubsetId VarChar( 6 ) Const Options( *NoPass );
  P_MessageSubsetVer VarChar( 3 ) Const Options( *NoPass );
  P_MessageSubsetRel VarChar( 3 ) Const Options( *NoPass );
  P_MessageSubsetCA VarChar( 2 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_UNHSegment VarChar( 500 );
Dcl-S tempAssocCode VarChar( 6 );
Dcl-S tempAccessRef VarChar( 35 );
Dcl-S tempStatusIndCode VarChar( 1 );
Dcl-S tempMessageSubsetId VarChar( 6 );
Dcl-S tempMessageSubsetVer VarChar( 3 );
Dcl-S tempMessageSubsetRel VarChar( 3 );
Dcl-S tempMessageSubsetCA VarChar( 2 );

tempAssocCode = '';
tempAccessRef = '';
tempStatusIndCode = '';
tempMessageSubsetId = '';
tempMessageSubsetVer = '';
tempMessageSubsetRel = '';
tempMessageSubsetCA = '';

If %Parms() >= 6;
  tempAssocCode = P_AssocCode;
EndIf;
If %Parms() >= 7;
  tempAccessRef = P_AccessRef;
EndIf;
If %Parms() >= 8;
  tempStatusIndCode = P_StatusIndCode;
EndIf;
If %Parms() >= 9;
  tempMessageSubsetId = P_MessageSubsetId;
EndIf;
If %Parms() >= 10;
  tempMessageSubsetVer = P_MessageSubsetVer;
EndIf;
If %Parms() >= 11;
  tempMessageSubsetRel = P_MessageSubsetRel;
EndIf;
If %Parms() >= 12;
  tempMessageSubsetCA = P_MessageSubsetCA;
EndIf;

r_UNHSegment = 'UNH';
r_UNHSegment += PadField(P_MessageRefNum : 14 );
r_UNHSegment += PadField(P_MessageType : 6 );
r_UNHSegment += PadField(P_MessageVersion : 3 );
r_UNHSegment += PadField(P_MessageRelease : 3 );
r_UNHSegment += PadField(P_ControllingAgency : 2 );
r_UNHSegment += PadField(tempAssocCode : 6 );
r_UNHSegment += PadField(tempAccessRef : 35 );
r_UNHSegment += PadField(tempStatusIndCode : 1 );
r_UNHSegment += PadField(tempMessageSubsetId : 6 );
r_UNHSegment += PadField(tempMessageSubsetVer : 3 );
r_UNHSegment += PadField(tempMessageSubsetRel : 3 );
r_UNHSegment += PadField(tempMessageSubsetCA : 2 );

Return r_UNHSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateBGM - Beginning of message segment
//-------------------------------------------------------------------
Dcl-Proc GenerateBGM Export;
Dcl-Pi GenerateBGM VarChar( 500 );
  P_DocMsgName     VarChar( 3 ) Const;
  P_DocMsgNumber   VarChar( 35 ) Const;
  P_DocMsgFunction VarChar( 3 ) Const;
  P_DocMsgNameText VarChar( 35 ) Const Options( *NoPass );
  P_ResponseType   VarChar( 3 ) Const Options( *NoPass );
  P_DocMsgStatus   VarChar( 3 ) Const Options( *NoPass );
  P_MsgLangCode    VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_BGMSegment VarChar( 500 );
Dcl-S tempDocMsgNameText VarChar( 35 );
Dcl-S tempResponseType VarChar( 3 );
Dcl-S tempDocMsgStatus VarChar( 3 );
Dcl-S tempMsgLangCode VarChar( 3 );

tempDocMsgNameText = '';
tempResponseType = '';
tempDocMsgStatus = '';
tempMsgLangCode = '';

If %Parms() >= 4;
  tempDocMsgNameText = P_DocMsgNameText;
EndIf;
If %Parms() >= 5;
  tempResponseType = P_ResponseType;
EndIf;
If %Parms() >= 6;
  tempDocMsgStatus = P_DocMsgStatus;
EndIf;
If %Parms() >= 7;
  tempMsgLangCode = P_MsgLangCode;
EndIf;

r_BGMSegment = 'BGM';
r_BGMSegment += PadField(P_DocMsgName : 3 );
r_BGMSegment += PadField(tempDocMsgNameText : 35 );
r_BGMSegment += PadField(P_DocMsgNumber : 35 );
r_BGMSegment += PadField(P_DocMsgFunction : 3 );
r_BGMSegment += PadField(tempResponseType : 3 );
r_BGMSegment += PadField(tempDocMsgStatus : 3 );
r_BGMSegment += PadField(tempMsgLangCode : 3 );

Return r_BGMSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateDTM - Date/time/period segment
//-------------------------------------------------------------------
Dcl-Proc GenerateDTM Export;
Dcl-Pi GenerateDTM VarChar( 500 );
  P_DateTimeFunctionCode VarChar( 3 ) Const;
  P_DateTimeValue VarChar( 35 ) Const;
  P_DateTimeFormatCode VarChar( 3 ) Const;
  P_DateTimePeriodCode VarChar( 3 ) Const Options( *NoPass );
  P_TimeZoneCode VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_DTMSegment VarChar( 500 );
Dcl-S tempDateTimePeriodCode VarChar( 3 );
Dcl-S tempTimeZoneCode VarChar( 3 );

tempDateTimePeriodCode = '';
tempTimeZoneCode = '';

If %Parms() >= 4;
  tempDateTimePeriodCode = P_DateTimePeriodCode;
EndIf;
If %Parms() >= 5;
  tempTimeZoneCode = P_TimeZoneCode;
EndIf;

r_DTMSegment = 'DTM';
r_DTMSegment += PadField(P_DateTimeFunctionCode : 3 );
r_DTMSegment += PadField(P_DateTimeValue : 35 );
r_DTMSegment += PadField(P_DateTimeFormatCode : 3 );
r_DTMSegment += PadField(tempDateTimePeriodCode : 3 );
r_DTMSegment += PadField(tempTimeZoneCode : 3 );

Return r_DTMSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateRFF - Reference segment
//-------------------------------------------------------------------
Dcl-Proc GenerateRFF Export;
Dcl-Pi GenerateRFF VarChar( 500 );
  P_ReferenceCodeQual  VarChar( 3 ) Const;
  P_ReferenceNumber    VarChar( 70 ) Const;
  P_LineNumber         VarChar( 6 ) Const Options( *NoPass );
  P_ReferenceVersionId VarChar( 35 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_RFFSegment VarChar( 500 );
Dcl-S tempLineNumber VarChar( 6 );
Dcl-S tempReferenceVersionId VarChar( 35 );

tempLineNumber = '';
tempReferenceVersionId = '';

If %Parms() >= 3;
  tempLineNumber = P_LineNumber;
EndIf;
If %Parms() >= 4;
  tempReferenceVersionId = P_ReferenceVersionId;
EndIf;

r_RFFSegment = 'RFF';
r_RFFSegment += PadField(P_ReferenceCodeQual : 3 );
r_RFFSegment += PadField(P_ReferenceNumber : 70 );
r_RFFSegment += PadField(tempLineNumber : 6 );
r_RFFSegment += PadField(tempReferenceVersionId : 35 );

Return r_RFFSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateNAD - Name and address segment
//-------------------------------------------------------------------
Dcl-Proc GenerateNAD Export;
Dcl-Pi GenerateNAD VarChar( 500 );
  P_PartyQualifier       VarChar( 3 ) Const;
  P_PartyIdCode          VarChar( 35 ) Const Options( *NoPass );
  P_PartyIdCodeQualifier VarChar( 3 ) Const Options( *NoPass );
  P_PartyName            VarChar( 35 ) Const Options( *NoPass );
  P_Street               VarChar( 35 ) Const Options( *NoPass );
  P_City                 VarChar( 35 ) Const Options( *NoPass );
  P_CountrySubdivision   VarChar( 9 ) Const Options( *NoPass );
  P_PostalCode           VarChar( 9 ) Const Options( *NoPass );
  P_CountryCode          VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_NADSegment VarChar( 500 );
Dcl-S tempPartyIdCode VarChar( 35 );
Dcl-S tempPartyIdCodeQualifier VarChar( 3 );
Dcl-S tempPartyName VarChar( 35 );
Dcl-S tempStreet VarChar( 35 );
Dcl-S tempCity VarChar( 35 );
Dcl-S tempCountrySubdivision VarChar( 9 );
Dcl-S tempPostalCode VarChar( 9 );
Dcl-S tempCountryCode VarChar( 3 );

tempPartyIdCode = '';
tempPartyIdCodeQualifier = '';
tempPartyName = '';
tempStreet = '';
tempCity = '';
tempCountrySubdivision = '';
tempPostalCode = '';
tempCountryCode = '';

If %Parms() >= 2;
  tempPartyIdCode = P_PartyIdCode;
EndIf;
If %Parms() >= 3;
  tempPartyIdCodeQualifier = P_PartyIdCodeQualifier;
EndIf;
If %Parms() >= 4;
  tempPartyName = P_PartyName;
EndIf;
If %Parms() >= 5;
  tempStreet = P_Street;
EndIf;
If %Parms() >= 6;
  tempCity = P_City;
EndIf;
If %Parms() >= 7;
  tempCountrySubdivision = P_CountrySubdivision;
EndIf;
If %Parms() >= 8;
  tempPostalCode = P_PostalCode;
EndIf;
If %Parms() >= 9;
  tempCountryCode = P_CountryCode;
EndIf;

r_NADSegment = 'NAD';
r_NADSegment += PadField(P_PartyQualifier : 3 );
r_NADSegment += PadField(tempPartyIdCode : 35 );
r_NADSegment += PadField(tempPartyIdCodeQualifier : 3 );
r_NADSegment += PadField(tempPartyName : 35 );
r_NADSegment += PadField(tempStreet : 35 );
r_NADSegment += PadField(tempCity : 35 );
r_NADSegment += PadField(tempCountrySubdivision : 9 );
r_NADSegment += PadField(tempPostalCode : 9 );
r_NADSegment += PadField(tempCountryCode : 3 );

Return r_NADSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateLIN - Line item segment
//-------------------------------------------------------------------
Dcl-Proc GenerateLIN Export;
Dcl-Pi GenerateLIN VarChar( 500 );
  P_LineItemNumber       VarChar( 6 ) Const;
  P_ItemIdType1          VarChar( 3 ) Const;
  P_ItemId1              VarChar( 35 ) Const;
  P_ItemIdType2          VarChar( 3 ) Const Options( *NoPass );
  P_ItemId2              VarChar( 35 ) Const Options( *NoPass );
  P_ItemIdType3          VarChar( 3 ) Const Options( *NoPass );
  P_ItemId3              VarChar( 35 ) Const Options( *NoPass );
  P_SubLineIndicator     VarChar( 1 ) Const Options( *NoPass );
  P_ConfigurationLevel   VarChar( 2 ) Const Options( *NoPass );
  P_ConfigurationCode    VarChar( 2 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_LINSegment VarChar( 500 );
Dcl-S tempItemIdType2 VarChar( 3 );
Dcl-S tempItemId2 VarChar( 35 );
Dcl-S tempItemIdType3 VarChar( 3 );
Dcl-S tempItemId3 VarChar( 35 );
Dcl-S tempSubLineIndicator VarChar( 1 );
Dcl-S tempConfigurationLevel VarChar( 2 );
Dcl-S tempConfigurationCode VarChar( 2 );

tempItemIdType2 = '';
tempItemId2 = '';
tempItemIdType3 = '';
tempItemId3 = '';
tempSubLineIndicator = '';
tempConfigurationLevel = '';
tempConfigurationCode = '';

If %Parms() >= 4;
  tempItemIdType2 = P_ItemIdType2;
EndIf;
If %Parms() >= 5;
  tempItemId2 = P_ItemId2;
EndIf;
If %Parms() >= 6;
  tempItemIdType3 = P_ItemIdType3;
EndIf;
If %Parms() >= 7;
  tempItemId3 = P_ItemId3;
EndIf;
If %Parms() >= 8;
  tempSubLineIndicator = P_SubLineIndicator;
EndIf;
If %Parms() >= 9;
  tempConfigurationLevel = P_ConfigurationLevel;
EndIf;
If %Parms() >= 10;
  tempConfigurationCode = P_ConfigurationCode;
EndIf;

r_LINSegment = 'LIN';
r_LINSegment += P_LineItemNumber;
r_LINSegment += PadField(P_ItemIdType1 : 3 );
r_LINSegment += PadField(P_ItemId1 : 35 );
r_LINSegment += PadField(tempItemIdType2 : 3 );
r_LINSegment += PadField(tempItemId2 : 35 );
r_LINSegment += PadField(tempItemIdType3 : 3 );
r_LINSegment += PadField(tempItemId3 : 35 );
r_LINSegment += PadField(tempSubLineIndicator : 1 );
r_LINSegment += PadField(tempConfigurationLevel : 2 );
r_LINSegment += PadField(tempConfigurationCode : 2 );

Return r_LINSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateIMD - Item description segment
//-------------------------------------------------------------------
Dcl-Proc GenerateIMD Export;
Dcl-Pi GenerateIMD VarChar( 500 );
  P_ItemDescTypeCode      VarChar( 3 ) Const Options( *NoPass );
  P_ItemCharCode          VarChar( 3 ) Const Options( *NoPass );
  P_ItemDescCode          VarChar( 17 ) Const Options( *NoPass );
  P_ItemDescCodeTypeCode  VarChar( 3 ) Const Options( *NoPass );
  P_ItemDesc              VarChar( 256 ) Const Options( *NoPass );
  P_SurfaceLayerCode      VarChar( 3 ) Const Options( *NoPass );
  P_SourceLanguageCode    VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_IMDSegment VarChar( 500 );
Dcl-S tempItemDescTypeCode VarChar( 3 );
Dcl-S tempItemCharCode VarChar( 3 );
Dcl-S tempItemDescCode VarChar( 17 );
Dcl-S tempItemDescCodeTypeCode VarChar( 3 );
Dcl-S tempItemDesc VarChar( 256 );
Dcl-S tempSurfaceLayerCode VarChar( 3 );
Dcl-S tempSourceLanguageCode VarChar( 3 );

tempItemDescTypeCode = '';
tempItemCharCode = '';
tempItemDescCode = '';
tempItemDescCodeTypeCode = '';
tempItemDesc = '';
tempSurfaceLayerCode = '';
tempSourceLanguageCode = '';

If %Parms() >= 1;
  tempItemDescTypeCode = P_ItemDescTypeCode;
EndIf;
If %Parms() >= 2;
  tempItemCharCode = P_ItemCharCode;
EndIf;
If %Parms() >= 3;
  tempItemDescCode = P_ItemDescCode;
EndIf;
If %Parms() >= 4;
  tempItemDescCodeTypeCode = P_ItemDescCodeTypeCode;
EndIf;
If %Parms() >= 5;
  tempItemDesc = P_ItemDesc;
EndIf;
If %Parms() >= 6;
  tempSurfaceLayerCode = P_SurfaceLayerCode;
EndIf;
If %Parms() >= 7;
  tempSourceLanguageCode = P_SourceLanguageCode;
EndIf;

r_IMDSegment = 'IMD';
r_IMDSegment += PadField(tempItemDescTypeCode : 3 );
r_IMDSegment += PadField(tempItemCharCode : 3 );
r_IMDSegment += PadField(tempItemDescCode : 17 );
r_IMDSegment += PadField(tempItemDescCodeTypeCode : 3 );
r_IMDSegment += PadField(tempItemDesc : 256 );
r_IMDSegment += PadField(tempSurfaceLayerCode : 3 );
r_IMDSegment += PadField(tempSourceLanguageCode : 3 );

Return r_IMDSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateQTY - Quantity segment
//-------------------------------------------------------------------
Dcl-Proc GenerateQTY Export;
Dcl-Pi GenerateQTY VarChar( 500 );
  P_QuantityTypeCode    VarChar( 3 ) Const;
  P_Quantity            VarChar( 15 ) Const;
  P_MeasureUnitCode     VarChar( 3 ) Const Options( *NoPass );
  P_QuantityQualifier   VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_QTYSegment VarChar( 500 );
Dcl-S tempMeasureUnitCode VarChar( 3 );
Dcl-S tempQuantityQualifier VarChar( 3 );

tempMeasureUnitCode = '';
tempQuantityQualifier = '';

If %Parms() >= 3;
  tempMeasureUnitCode = P_MeasureUnitCode;
EndIf;
If %Parms() >= 4;
  tempQuantityQualifier = P_QuantityQualifier;
EndIf;

r_QTYSegment = 'QTY';
r_QTYSegment += PadField(P_QuantityTypeCode : 3 );
r_QTYSegment += PadField(P_Quantity : 15 );
r_QTYSegment += PadField(tempMeasureUnitCode : 3 );
r_QTYSegment += PadField(tempQuantityQualifier : 3 );

Return r_QTYSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateLOC - Location segment
//-------------------------------------------------------------------
Dcl-Proc GenerateLOC Export;
Dcl-Pi GenerateLOC VarChar( 500 );
  P_3227_LocationFunctionCodeQualifier VarChar( 3 ) Const;
  P_C517_1_LocationNameCode VarChar( 35 ) Const Options( *NoPass );
  P_C517_2_CodeListResponsibleAgencyCode VarChar( 3 ) Const Options( *NoPass );
  P_C517_3_LocationName VarChar( 256 ) Const Options( *NoPass );
  P_3225_LocationIdentifier VarChar( 35 ) Const Options( *NoPass );
  P_C519_1_RelatedLocationOneID VarChar( 35 ) Const Options( *NoPass );
  P_C519_2_RelatedLocationOneCodeListCode VarChar( 3 ) Const Options( *NoPass );
  P_C553_1_RelatedLocationTwoID VarChar( 35 ) Const Options( *NoPass );
  P_C553_2_RelatedLocationTwoCodeListCode VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_LOCSegment VarChar( 500 );
Dcl-S tempLocNameCode VarChar( 35 );
Dcl-S tempAgencyCode VarChar( 3 );
Dcl-S tempLocName VarChar( 256 );
Dcl-S tempLocId VarChar( 35 );

tempLocNameCode = '';
tempAgencyCode = '';
tempLocName = '';
tempLocId = '';

If %Parms() >= 2;
  tempLocNameCode = P_C517_1_LocationNameCode;
EndIf;
If %Parms() >= 3;
  tempAgencyCode = P_C517_2_CodeListResponsibleAgencyCode;
EndIf;
If %Parms() >= 4;
  tempLocName = P_C517_3_LocationName;
EndIf;
If %Parms() >= 5;
  tempLocId = P_3225_LocationIdentifier;
EndIf;

r_LOCSegment = 'LOC';
r_LOCSegment += PadField(P_3227_LocationFunctionCodeQualifier : 3 );
r_LOCSegment += PadField(tempLocNameCode : 35 );
r_LOCSegment += PadField(tempAgencyCode : 3 );
r_LOCSegment += PadField(tempLocName : 256 );
r_LOCSegment += PadField(tempLocId : 35 );

Return r_LOCSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateALI - Additional location information (country of origin)
//-------------------------------------------------------------------
Dcl-Proc GenerateALI Export;
Dcl-Pi GenerateALI VarChar( 500 );
  P_CountryOfOrigin VarChar( 3 ) Const;
End-Pi;

Dcl-S r_ALISegment VarChar( 500 );

r_ALISegment = 'ALI';
r_ALISegment += PadField(P_CountryOfOrigin : 3);

Return r_ALISegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateMOA - Monetary amount segment
//-------------------------------------------------------------------
Dcl-Proc GenerateMOA Export;
Dcl-Pi GenerateMOA VarChar( 500 );
  P_TypeQualifier     VarChar( 3 ) Const;
  P_Amount            VarChar( 35 ) Const;
  P_CurrencyCode      VarChar( 3 ) Const Options( *NoPass );
  P_CurrencyQualifier VarChar( 3 ) Const Options( *NoPass );
  P_StatusCode        VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_MOASegment VarChar( 500 );
Dcl-S currencyCode VarChar( 3 );
Dcl-S currencyQualifier VarChar( 3 );
Dcl-S statusCode VarChar( 3 );

If P_TypeQualifier = '' Or P_Amount = '';
  Return '';
EndIf;

currencyCode = '';
If %Parms() >= 3 and P_CurrencyCode <> '';
  currencyCode = P_CurrencyCode;
EndIf;

currencyQualifier = '';
If %Parms() >= 4 and P_CurrencyQualifier <> '';
  currencyQualifier = P_CurrencyQualifier;
EndIf;

statusCode = '';
If %Parms() >= 5 and P_StatusCode <> '';
  statusCode = P_StatusCode;
EndIf;

r_MOASegment = 'MOA';
r_MOASegment += PadField(P_TypeQualifier : 3 );
r_MOASegment += PadField(P_Amount : 35 );
r_MOASegment += PadField(currencyCode : 3 );
r_MOASegment += PadField(currencyQualifier : 3 );
r_MOASegment += PadField(statusCode : 3 );

Return r_MOASegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNT - Message trailer segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNT Export;
Dcl-Pi GenerateUNT VarChar( 500 );
  P_SegmentCount       VarChar( 6 ) Const;
  P_MessageRefNumber   VarChar( 14 ) Const;
End-Pi;

Dcl-S r_UNTSegment VarChar( 500 );

r_UNTSegment = 'UNT';
r_UNTSegment += PadField(P_SegmentCount : 6 );
r_UNTSegment += PadField(P_MessageRefNumber : 14 );

Return r_UNTSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNZ - Interchange trailer segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNZ Export;
Dcl-Pi GenerateUNZ VarChar( 500 );
  P_InterchangeControlCount VarChar( 6 ) Const;
  P_InterchangeControlRef   VarChar( 14 ) Const;
End-Pi;

Dcl-S r_UNZSegment VarChar( 500 );

r_UNZSegment = 'UNZ';
r_UNZSegment += PadField(P_InterchangeControlCount : 6 );
r_UNZSegment += PadField(P_InterchangeControlRef : 14 );

Return r_UNZSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateHDR - Custom HDR header consolidation segment
//-------------------------------------------------------------------
Dcl-Proc GenerateHDR Export;
  Dcl-Pi GenerateHDR VarChar( 1000 );
    P_GroupFuncCode       VarChar( 3 )  Const;
    P_SenderQual          VarChar( 4 )  Const;
    P_SenderID            VarChar( 35 ) Const;
    P_RecipQual           VarChar( 4 )  Const;
    P_RecipID             VarChar( 35 ) Const;
    P_InterchgCtrlNum     VarChar( 14 ) Const;
    P_GroupSenderID       VarChar( 35 ) Const;
    P_GroupRecipID        VarChar( 35 ) Const;
    P_GroupCtrlNum        VarChar( 9 )  Const;
    P_GroupDate           VarChar( 8 )  Const;
    P_GroupTime           VarChar( 8 )  Const;
    P_TransCtrlNum        VarChar( 9 )  Const;
    P_GroupVerRelCode     VarChar( 12 ) Const;
    P_TransType           VarChar( 6 )  Const;
    P_Agency              VarChar( 6 )  Const;
    P_InterchgVer         VarChar( 8 )  Const;
    P_InterchgDate        VarChar( 8 )  Const;
    P_InterchgTime        VarChar( 6 )  Const;
    P_TestInd             VarChar( 1 )  Const;
    P_SyntaxId            VarChar( 4 )  Const;
    P_SyntaxVerNo         VarChar( 1 )  Const;
    P_RecipPass           VarChar( 14 ) Const;
    P_RecipPassQual       VarChar( 3 )  Const;
    P_AppRef              VarChar( 14 ) Const;
    P_AckReq              VarChar( 1 )  Const;
    P_PriorCode           VarChar( 1 )  Const;
    P_CommAgrmtID         VarChar( 40 ) Const;
    P_MessageRefNum       VarChar( 14 ) Const;
    P_ControllingAgency   VarChar( 3 )  Const;
    P_AccessRef           VarChar( 40 ) Const;
    P_SeqMsgTransferNo    VarChar( 2 )  Const;
    P_SeqMsgTransferInd   VarChar( 1 )  Const;
  End-Pi;

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

//==============================================================================
// N E W  I N V O I C - S P E C I F I C  S E G M E N T S
//==============================================================================

//-------------------------------------------------------------------
// GenerateALC - Allowance/Charge segment
//-------------------------------------------------------------------
Dcl-Proc GenerateALC Export;
Dcl-Pi GenerateALC VarChar( 500 );
  P_AllowChargeCode    VarChar( 3 ) Const;
  P_AllowChargeType    VarChar( 3 ) Const;
  P_SettlementCode     VarChar( 3 ) Const Options( *NoPass );
  P_CalcSequence       VarChar( 3 ) Const Options( *NoPass );
  P_SpecServiceCode    VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_ALCSegment VarChar( 500 );
Dcl-S tempSettlement VarChar( 3 );
Dcl-S tempCalcSeq VarChar( 3 );
Dcl-S tempSpecService VarChar( 3 );

tempSettlement = '';
tempCalcSeq = '';
tempSpecService = '';

If %Parms() >= 3;
  tempSettlement = P_SettlementCode;
EndIf;
If %Parms() >= 4;
  tempCalcSeq = P_CalcSequence;
EndIf;
If %Parms() >= 5;
  tempSpecService = P_SpecServiceCode;
EndIf;

r_ALCSegment = 'ALC';
r_ALCSegment += PadField(P_AllowChargeCode : 3 );
r_ALCSegment += PadField(P_AllowChargeType : 3 );
r_ALCSegment += PadField(tempSettlement : 3 );
r_ALCSegment += PadField(tempCalcSeq : 3 );
r_ALCSegment += PadField(tempSpecService : 3 );

Return r_ALCSegment;
End-Proc;

//-------------------------------------------------------------------
// GeneratePRI - Price details segment
//-------------------------------------------------------------------
Dcl-Proc GeneratePRI Export;
Dcl-Pi GeneratePRI VarChar( 500 );
  P_PriceCode          VarChar( 3 ) Const;
  P_PriceAmount        VarChar( 15 ) Const;
  P_PriceType          VarChar( 3 ) Const Options( *NoPass );
  P_PriceBasis         VarChar( 9 ) Const Options( *NoPass );
  P_MeasureUnit        VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_PRISegment VarChar( 500 );
Dcl-S tempPriceType VarChar( 3 );
Dcl-S tempPriceBasis VarChar( 9 );
Dcl-S tempMeasureUnit VarChar( 3 );

tempPriceType = '';
tempPriceBasis = '';
tempMeasureUnit = '';

If %Parms() >= 3;
  tempPriceType = P_PriceType;
EndIf;
If %Parms() >= 4;
  tempPriceBasis = P_PriceBasis;
EndIf;
If %Parms() >= 5;
  tempMeasureUnit = P_MeasureUnit;
EndIf;

r_PRISegment = 'PRI';
r_PRISegment += PadField(P_PriceCode : 3 );
r_PRISegment += PadField(P_PriceAmount : 15 );
r_PRISegment += PadField(tempPriceType : 3 );
r_PRISegment += PadField(tempPriceBasis : 9 );
r_PRISegment += PadField(tempMeasureUnit : 3 );

Return r_PRISegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateCUX - Currency segment
//-------------------------------------------------------------------
Dcl-Proc GenerateCUX Export;
Dcl-Pi GenerateCUX VarChar( 500 );
  P_CurrencyUsageCode  VarChar( 3 ) Const;
  P_CurrencyCode       VarChar( 3 ) Const;
  P_CurrencyQualifier  VarChar( 3 ) Const;
  P_RateOfExchange     VarChar( 12 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_CUXSegment VarChar( 500 );
Dcl-S tempRate VarChar( 12 );

tempRate = '';
If %Parms() >= 4;
  tempRate = P_RateOfExchange;
EndIf;

r_CUXSegment = 'CUX';
r_CUXSegment += PadField(P_CurrencyUsageCode : 3 );
r_CUXSegment += PadField(P_CurrencyCode : 3 );
r_CUXSegment += PadField(P_CurrencyQualifier : 3 );
r_CUXSegment += PadField(tempRate : 12 );

Return r_CUXSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateTAX - Duty/tax/fee segment
//-------------------------------------------------------------------
Dcl-Proc GenerateTAX Export;
Dcl-Pi GenerateTAX VarChar( 500 );
  P_FunctionQualifier  VarChar( 3 ) Const;
  P_TaxType            VarChar( 3 ) Const;
  P_TaxRate            VarChar( 17 ) Const Options( *NoPass );
  P_TaxCategory        VarChar( 3 ) Const Options( *NoPass );
End-Pi;

Dcl-S r_TAXSegment VarChar( 500 );
Dcl-S tempRate VarChar( 17 );
Dcl-S tempCategory VarChar( 3 );

tempRate = '';
tempCategory = '';

If %Parms() >= 3;
  tempRate = P_TaxRate;
EndIf;
If %Parms() >= 4;
  tempCategory = P_TaxCategory;
EndIf;

r_TAXSegment = 'TAX';
r_TAXSegment += PadField(P_FunctionQualifier : 3 );
r_TAXSegment += PadField(P_TaxType : 3 );
r_TAXSegment += PadField(tempRate : 17 );
r_TAXSegment += PadField(tempCategory : 3 );

Return r_TAXSegment;
End-Proc;

//-------------------------------------------------------------------
// GenerateUNS - Section control segment
//-------------------------------------------------------------------
Dcl-Proc GenerateUNS Export;
Dcl-Pi GenerateUNS VarChar( 500 );
  P_SectionId          VarChar( 1 ) Const;
End-Pi;

Dcl-S r_UNSSegment VarChar( 500 );

r_UNSSegment = 'UNS';
r_UNSSegment += PadField(P_SectionId : 1 );

Return r_UNSSegment;
End-Proc;

//==============================================================================
// U T I L I T Y  P R O C E D U R E S
//==============================================================================

//-------------------------------------------------------------------
// ConvertDateFormat - Converts 14-char date to various formats
//-------------------------------------------------------------------
Dcl-Proc ConvertDateFormat Export;
  Dcl-Pi ConvertDateFormat LikeDS(Result);
    P_InputDate Char( 14 ) Const;
    P_FormatCode Int( 10 ) Const;
  End-Pi;

  Dcl-S w_Year Char( 4 );
  Dcl-S w_Month Char( 2 );
  Dcl-S w_Day Char( 2 );
  Dcl-S w_Hour Char( 2 );
  Dcl-S w_Minute Char( 2 );
  Dcl-S w_Second Char( 2 );
  Dcl-DS ResultDS LikeDS(Result);

  ResultDS.ReturnCode = 0;
  ResultDS.FormattedDate = '';

  If %Len(%Trim(P_InputDate)) <> 14 or
     %Check('0123456789' : P_InputDate) > 0;
    ResultDS.ReturnCode = -2;
    Return ResultDS;
  EndIf;

  w_Year = %Subst(P_InputDate: 1: 4 );
  w_Month = %Subst(P_InputDate: 5: 2 );
  w_Day = %Subst(P_InputDate: 7: 2 );
  w_Hour = %Subst(P_InputDate: 9: 2 );
  w_Minute = %Subst(P_InputDate: 11: 2 );
  w_Second = %Subst(P_InputDate: 13: 2 );

  Select;
    When P_FormatCode = 6;
      ResultDS.FormattedDate = w_Month + w_Day + %Subst(w_Year: 3: 2 );
    When P_FormatCode = 102;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day;
    When P_FormatCode = 203;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day +
        w_Hour + w_Minute;
    When P_FormatCode = 204;
      ResultDS.FormattedDate = w_Year + w_Month + w_Day +
        w_Hour + w_Minute + w_Second;
    Other;
      ResultDS.ReturnCode = -1;
      ResultDS.FormattedDate = '';
  EndSl;

  Return ResultDS;
End-Proc;

//-------------------------------------------------------------------
// WriteLineToFile - Writes a line to IFS file, tracks segment count
//-------------------------------------------------------------------
Dcl-Proc WriteLineToFile Export;
  Dcl-Pi WriteLineToFile Ind;
    lineText VarChar( 500 ) Const;
    fileHandle Pointer Value;
  End-Pi;

  Dcl-S success Ind Inz( *Off );
  Dcl-S segment Char( 3 ) Inz( '' );

  If WriteFile(lineText : fileHandle) < 0;
    Return *Off;
  EndIf;

  segment = %Subst(lineText: 1: 3 );

  Select;
    When segment = 'UNZ';
    When segment = 'UNB';
    When segment = 'UNA';
    Other;
      SegmentCount += 1;
  EndSl;

  Return *On;
End-Proc;

//-------------------------------------------------------------------
// getDateTimeChar - Returns current datetime as YYYYMMDD_HHMMSS
//-------------------------------------------------------------------
Dcl-Proc getDateTimeChar;
  Dcl-Pi getDateTimeChar Char( 15 );
  End-Pi;

  Dcl-S dateStr Char( 8 );
  Dcl-S timeStr Char( 6 );

  dateStr = %Char(%Date(): *ISO0 );
  timeStr = %Char(%Time(): *ISO0 );

  Return dateStr + '_' + timeStr;
End-Proc;

//-------------------------------------------------------------------
// getDateTimeChar14 - Returns current datetime as YYYYMMDDHHMMSS
//-------------------------------------------------------------------
Dcl-Proc getDateTimeChar14;
  Dcl-Pi getDateTimeChar14 Char( 14 );
  End-Pi;

  Dcl-S dateStr Char( 8 );
  Dcl-S timeStr Char( 6 );

  dateStr = %Char(%Date(): *ISO0 );
  timeStr = %Char(%Time(): *ISO0 );

  Return dateStr + timeStr;
End-Proc;

//-------------------------------------------------------------------
// getDateTimeCharMicro - Get date/time with microseconds
//   Returns: YYYYMMDD_HHMMSS_UUUUUU (22 chars)
//-------------------------------------------------------------------
Dcl-Proc getDateTimeCharMicro;
  Dcl-Pi getDateTimeCharMicro Char( 22 );
  End-Pi;

  Dcl-S tsNow Timestamp;
  Dcl-S dateStr Char( 8 );
  Dcl-S timeStr Char( 6 );
  Dcl-S microStr Char( 6 );

  tsNow = %Timestamp( *SYS );
  dateStr = %Char( %Date( tsNow ) : *ISO0 );
  timeStr = %Char( %Time( tsNow ) : *ISO0 );
  microStr = %Subst( %Char( tsNow ) : 21 : 6 );

  Return dateStr + '_' + timeStr + '_' + microStr;
End-Proc;

//-------------------------------------------------------------------
// FormatDecimal - Formats a packed decimal for EDI output
//-------------------------------------------------------------------
Dcl-Proc FormatDecimal Export;
Dcl-Pi FormatDecimal VarChar( 20 );
  P_Value Packed( 15: 4 ) Const;
  P_DecPlaces Int( 10 ) Const;
End-Pi;

Dcl-S result VarChar( 20 );
Dcl-S intPart Packed( 15: 0 );
Dcl-S decPart Packed( 15: 0 );
Dcl-S multiplier Packed( 15: 0 );
Dcl-S decStr VarChar( 10 );

// Handle zero
If P_Value = 0;
  result = '0';
  If P_DecPlaces > 0;
    result += '.';
    decStr = '';
    multiplier = P_DecPlaces;
    Dow multiplier > 0;
      decStr += '0';
      multiplier -= 1;
    EndDo;
    result += decStr;
  EndIf;
  Return result;
EndIf;

// Calculate integer and decimal parts
Select;
  When P_DecPlaces = 0;
    intPart = %Int(P_Value);
    result = %Char(intPart);
  When P_DecPlaces = 2;
    intPart = %Int(P_Value);
    decPart = %Abs(%Int((P_Value - intPart) * 100));
    result = %Char(intPart) + '.';
    If decPart < 10;
      result += '0' + %Char(decPart);
    Else;
      result += %Char(decPart);
    EndIf;
  When P_DecPlaces = 4;
    intPart = %Int(P_Value);
    decPart = %Abs(%Int((P_Value - intPart) * 10000));
    result = %Char(intPart) + '.';
    If decPart < 10;
      result += '000' + %Char(decPart);
    ElseIf decPart < 100;
      result += '00' + %Char(decPart);
    ElseIf decPart < 1000;
      result += '0' + %Char(decPart);
    Else;
      result += %Char(decPart);
    EndIf;
  Other;
    result = %Char(P_Value);
EndSl;

Return result;
End-Proc;

//-------------------------------------------------------------------
// FormatLineNumber - Formats line number with leading zeros
//-------------------------------------------------------------------
Dcl-Proc FormatLineNumber;
Dcl-Pi FormatLineNumber VarChar(10);
  P_LineNum Int(10) Const;
  P_Length  Int(10) Const Options(*NoPass);
End-Pi;

Dcl-S Length Int(10);
Dcl-S Result VarChar(10);

If %Parms() >= 2;
  Length = P_Length;
Else;
  Length = 6;
EndIf;

Result = %Char(P_LineNum);

Dow %Len(Result) < Length;
  Result = '0' + Result;
EndDo;

Return Result;
End-Proc;

//-------------------------------------------------------------------
// LoadHDRFromECSVAL_INVOIC - Loads HDR_DS for INVOIC processing
//-------------------------------------------------------------------
Dcl-Proc LoadHDRFromECSVAL_INVOIC Export;
  Dcl-Pi LoadHDRFromECSVAL_INVOIC Ind;
    P_CustomerNumber VarChar( 50 ) Const;
  End-Pi;

  Dcl-S l_SenderID VarChar( 35 );
  Dcl-S l_SenderQual VarChar( 4 );
  Dcl-S l_RecipID VarChar( 35 );
  Dcl-S l_RecipQual VarChar( 4 );
  Dcl-S l_TransType VarChar( 10 );
  Dcl-S l_MsgVersion VarChar( 3 );
  Dcl-S l_MsgRelease VarChar( 3 );
  Dcl-S l_CtlAgency VarChar( 2 );
  Dcl-S l_AssocCode VarChar( 6 );
  Dcl-S l_CustNum Packed( 4: 0 );
  Dcl-S l_Success Ind Inz( *Off );

  Monitor;
    l_CustNum = %Dec(P_CustomerNumber : 4 : 0);
  On-Error;
    JobLogPrint('LoadHDRFromECSVAL_INVOIC: Invalid customer: %s' +
                X'25' : P_CustomerNumber);
    Return *Off;
  EndMon;

  // Join EDITPCX + EDICUSTOMERVALUES for this customer
  Exec Sql
    Select
      Coalesce( Nullif( p.INV810SENDERID, '' ), e.WFTRADINGPARTNERID ),
      Coalesce( Nullif( p.INV810SENDERQUAL, '' ), e.WFQUALIFIER ),
      Coalesce( Nullif( p.INV810RECIPID, '' ), e.TRADINGPARTNERID ),
      Coalesce( Nullif( p.INV810RECIPQUAL, '' ), e.PARTNERQUALIFIERID ),
      p.SEND810TYPE,
      p.EDIFACTMSGVERSION,
      p.EDIFACTMSGRELEASE,
      p.EDIFACTCTLAGENCY,
      p.EDIFACTASSOCCODE
    Into
      :l_SenderID,
      :l_SenderQual,
      :l_RecipID,
      :l_RecipQual,
      :l_TransType,
      :l_MsgVersion,
      :l_MsgRelease,
      :l_CtlAgency,
      :l_AssocCode
    From EDITEST.EDITPCUSTXRREF p
    Join EDITEST.EDICUSTOMERVALUES e
      On p.ECSVALKEY = e.EDICUSTOMERVALUES_ID
    Where p.SHIPTOCUST = :l_CustNum
    Fetch First 1 Row Only;

  If SqlState = '00000';
    l_Success = *On;

    If l_SenderID <> '';
      HDR_DS.SenderID = l_SenderID;
    EndIf;
    If l_SenderQual <> '';
      HDR_DS.SenderQual = l_SenderQual;
    EndIf;
    If l_RecipID <> '';
      HDR_DS.RecipID = l_RecipID;
    EndIf;
    If l_RecipQual <> '';
      HDR_DS.RecipQual = l_RecipQual;
    EndIf;
    If l_TransType <> '';
      HDR_DS.TransType = l_TransType;
    EndIf;

    If HDR_DS.GroupSenderID = '';
      HDR_DS.GroupSenderID = HDR_DS.SenderID;
    EndIf;
    If HDR_DS.GroupRecipID = '';
      HDR_DS.GroupRecipID = HDR_DS.RecipID;
    EndIf;

    // Populate dynamic interchange fields
    HDR_DS.SyntaxId = 'UNOC';
    HDR_DS.SyntaxVerNo = '3';
    HDR_DS.InterchgDate = %Char(%Dec(
      %Subst(getDateTimeChar14() : 3 : 6) : 6 : 0));
    HDR_DS.InterchgTime = %Subst(getDateTimeChar14() : 9 : 4);
    HDR_DS.InterchgCtrlNum = %Trim(getDateTimeChar14());
    HDR_DS.GroupDate = HDR_DS.InterchgDate;
    HDR_DS.GroupTime = HDR_DS.InterchgTime;
    HDR_DS.GroupCtrlNum = '1';
    HDR_DS.TransCtrlNum = '1';
    HDR_DS.MessageRefNum = '0001';
    HDR_DS.AckReq = '1';
    HDR_DS.TestInd = '1';

    If l_MsgVersion <> '';
      Pcx_MsgVersion = l_MsgVersion;
    Else;
      Pcx_MsgVersion = 'D';
    EndIf;

    If l_MsgRelease <> '';
      Pcx_MsgRelease = l_MsgRelease;
    Else;
      Pcx_MsgRelease = '07A';
    EndIf;

    If l_CtlAgency <> '';
      Pcx_CtlAgency = l_CtlAgency;
    Else;
      Pcx_CtlAgency = 'UN';
    EndIf;

    If l_AssocCode <> '';
      Pcx_AssocCode = l_AssocCode;
    Else;
      Pcx_AssocCode = 'GAVF24';
    EndIf;

    JobLogPrint('LoadHDR_INVOIC: Loaded for customer %s' +
                X'25' : P_CustomerNumber);

  ElseIf SqlState = '02000';
    JobLogPrint('LoadHDR_INVOIC: No config for customer %s' +
                X'25' : P_CustomerNumber);
    Pcx_MsgVersion = 'D';
    Pcx_MsgRelease = '07A';
    Pcx_CtlAgency = 'UN';
    Pcx_AssocCode = 'GAVF24';

    // Populate dynamic fields even without config
    HDR_DS.SyntaxId = 'UNOC';
    HDR_DS.SyntaxVerNo = '3';
    HDR_DS.InterchgDate = %Char(%Dec(
      %Subst(getDateTimeChar14() : 3 : 6) : 6 : 0));
    HDR_DS.InterchgTime = %Subst(getDateTimeChar14() : 9 : 4);
    HDR_DS.InterchgCtrlNum = %Trim(getDateTimeChar14());
    HDR_DS.GroupDate = HDR_DS.InterchgDate;
    HDR_DS.GroupTime = HDR_DS.InterchgTime;
    HDR_DS.GroupCtrlNum = '1';
    HDR_DS.TransCtrlNum = '1';
    HDR_DS.MessageRefNum = '0001';
    HDR_DS.AckReq = '1';
    HDR_DS.TestInd = '1';

    l_Success = *Off;

  Else;
    JobLogPrint('LoadHDR_INVOIC: SQL error for customer %s. ' +
                'SqlState=%s' + X'25' : P_CustomerNumber : SqlState);
    l_Success = *Off;
  EndIf;

  Return l_Success;
End-Proc;

//-------------------------------------------------------------------
// GetBuyerPartNumber - Lookup customer's part number from IVCPARTS
//-------------------------------------------------------------------
Dcl-Proc GetBuyerPartNumber;
Dcl-PI *N VarChar( 35 );
  P_PartNumber VarChar( 15 ) Const;
  P_OrderNumber VarChar( 22 ) Const;
  P_CustomerNumber VarChar( 50 ) Const;
End-PI;
  Dcl-S BuyerPart VarChar( 35 );
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
