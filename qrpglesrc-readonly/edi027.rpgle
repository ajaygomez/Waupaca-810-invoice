      *==============================================================*
      * AUTHOR ------ STEVE SLABY                                    *
      * DATE -------- MARCH 1999                                     *
      * TITLE/DESC -- EDI027, CONVERTS DATA FILES INTO X12           *
      *               810 FILES FOR USE BY THE PREMENOS SOFTWARE     *
      *                                                              *
      *               v/r 004010                                     *
      *                                                              *
      * CL PROGRAM -- EDI027C01 WHICH IS CALLED BY EDI027C02         *
      *                                                              *
      *==============================================================*
      ****************************************************************
      **REQ BY  | DATE |WHO|JOB|CHANGE DESCRIPTION       **
      **J.D.Des M|4-27-99 | SS  | 3942| Invoice 810 @ 004010       .*
      **J.D.WTRL0|  ''    | ''  | 4081| Invoice 810 @ 004010      **
      **J.D.Eng W|4-27-99 | SS  | 4070| Invoice 810 @ 004010      **
      **J.D.Dubuq|7-06-99 | SS  | 3943| Invoice 810 @ 004010      **
      **---------|--------|-----|-----|---------------------------**
      **J.D.Dubuq| 9-10-99| SS  | NP  | Move container info to seg**
      **         |        |     |     | IT1 elements 6 & 7        **
      **---------|--------|-----|-----|---------------------------**
     c**J.D.Ottom|12-1-99 | SS  | 4072| Invoice 810 @ 004010      **
      **J.D.Mexic|12-14-99| JF  |     | Invoice 810 @ 004010      **
      **---------|--------|-----|-----|----------------------------**
      **J.D.Engin|03-13-00| JF  |  NP | Remove J.D. Engine will    **
      **         |        |     |     | pay off of ASN            **
      **---------|--------|-----|-----|----------------------------**
      **J.D.Ottum|12-08-00| JF  |  NP | Remove J.D. Ottumwa will   **
      **         |        |     |     | pay off of ASN            **
      **---------|--------|-----|-----|---------------------------**
      **J.D.MEX  |01-09-01| JF  |  NP | CHGS TO ADJUST PNO TO J.D.**
      **         |        |     |     | 12 CHARICTER PART NUMBER  **
      **---------|--------|-----|-----|----------------------------**
      **J.D.Engin|05-01-02| cv  |  NP | Remove J.D. Des Moines will**
      **         |        |     |     | pay off of ASN            **
      **J.D.water|04-28-03| bh  |  NP | remove waterloo 810        **
      **AXLE TECH|06-04-03| bh  |  -- | ADDED AXLE TECH as they had**
      **         |        |     |     |  similar requirements.    **
      **J.D.harv |09-23-03| bh  |  NP | added harvester 810        **
      **J.D.water|09-30-03| bh  |  NP | added waterloo 810         **
      **J.D.WWL  |11-17-03| bh  | --- | added jd world wide log.   **
      **J.D.water|01-20-04| bh  |5158 | going paperless for proto  **
      **         |        |     |     | type invoices             **
      **J.D.engin| 7-28-04| bh  | --- | CHG dunn's number          **
      **J.D.seed | 7-28-04| bh  | --- | CHG ARRAY CODE(comment out)**
      **internal | 4-25-05| bh  | --- | add cross reference part#  **
      **J.D.World| 8/25/05| MM  | --- | Add Inv Dunnage# (DUNIVC). **
      **Ford Mtr.|02/15/06| MM  | 5821| Ability to output 18 char. **
      **         |        |     |     | part number.               **
      **J.d.water|04/13/06| BH  | 5863| on item line, need PL if   **
      **         |        |     |     | sample/4500 series         **
      **internal |04/28/06| BH  | ----| correct dunnage line       **
      **JD horico|11/16/06| BH  | ----| added JD as invoice        **
      **JD commer|08/07/07| BH  | 6268| added JD comm. for invoice **
      **JD otumwa|10/26/07| BH  | ----| chg id as per JD going to  **
      **         |        |     |     | sap                        **
      **CNH      |11/26/07| BH  |  107| new customer requirements  **
      **JD       |09/29/08| BH  |  -- | ADDED ENERGY SURCHARGE TO  **
      **         |        |     |     | INVOICE PIECE PRICE        **
      **JD       |10/28/08| BH  |  -- | correction to invoice      **
      **JD horico|04/09/09| BH  | ----| added JD as invoice        **
      **JD consum|10/09/09| BH  | ----| added JD as invoice        **
      **world wid|12/10/09| BH  | ----| added world class ind as   **
      **         |        |     |     | invoice                    **
      **Internal |01/15/10| BH  | ----| added world class restrict **
      **add Cat b|04/15/10| BH  | ----| added cat belgium          **
      **Oligney  |03/22/11| BH  | 1481| Added bosch rexroth        **
      **internal |06/11/11| BH  | ----| correct id on jd location  **
      **Caterpil |06/24/11| BH  | ----| chg cat UJ code to 2V      **
      **Caterpil |07/11/11| BH  | ----| chg cat ITA CODE           **
      **Caterpil |08/29/11| BH  | ----| add cat se code to 2V      **
      **Caterpil |08/29/11| BH  | ----| add cat WK code to 2V      **
      **Caterpil |08/29/11| BH  | ----| add cat VF code to 2V      **
      **caterpil |10/04/11| BH  | ----| chg CAD segment field to   **
      **         |        |     |     |  different field.          **
      **caterpil |10/20/11| BH  | 1984| correct CAD segment field  **
      **         |        |     |     |  data had one extra field  **
      **         |        |     |     |  removed that field        **
      **J.d      |10/22/11| BH  | 1923| add customer 1463          **
      **internal |12/23/11| BH  |     | correct clearing of field  **
      **         |        |     |     |  to removed retained data  **
      **Kohler   |03/29/12| BH  | 2009| Add Kohler to get 810s     **
      **REXROTH  |05/08/12| BH  | 1558| BOSCH CORRECTION           **
      **Internal |06/19/12| BH  | 2377| Chg company name in table  **
      **CNH 810  |11/14/13| BH  | 2559| 810 segments/cust requirement **
      **         |        |     |     | reduce code                **
      **CAT      |02/12/13| BH  | 2181| all Caterpillar using new     **
      **         |        |     |     | version based on PO lookup **
      **d.oligney|09/16/13| BJH |2747 | ivcparts cross ref and code
      **         |        |     |     |  clean up
      **Internal |12/31/14| KMH |2892 | IVCPARTS lookup needs to be
      **         |        |     |     | tightened to include customer
      **         |        |     |     | and change sequence of look-
      **         |        |     |     | ups            SCAN for 2892
      **---------|--------|----|------|----------------------------**
      **Internal |02/03/15| KMH|  IR  | When PO# comes in blank the
      **         |        |    |245314| X-Ref needs to check for this.
      **---------|--------|----|------|----------------------------**
      **Barb. O. |02/11/15| BJH|  IR  | Bosch EDI invoice ref/SAc in the
      **         |        |    |244817| ITA segment loop not summary loop
      **---------|--------|----|------|----------------------------**
      **Darrell O|12/20/15| BJH|  SR  | HMA EDI invoice setup for cust
      **         |        |    |335992|   2728   Scan for 335992
      **Darrell O|12/22/15| BJH|  SR  | issue on field not cleared
      **         |        |    |335992|   Scan for 335992
      **---------|--------|----|------|----------------------------**
      **D.Oligney|01/18/15| KMH|  SR  | All NACCO added to Invoicing
      **         |        |    |319862| program with changes
      **---------|--------|----|------|----------------------------**
      **A Roland |02/05/16| BJH|  SR  | Added field for BOL to carry
      **         |        |    |335992| thru edi 810
      **---------|--------|----|------|----------------------------**
      **D.Oligney|03/08/16| KMH|  SR  | Change program to pass the GS
      **         |        |    |319862| Segment to TrustedLink
      **---------|--------|----|------|----------------------------**
      **D.Oligney|03/15/16| KMH|  SR  | Previous change didn't work
      **         |        |    |319862| Sending GS Segment because this
      **         |        |    |      | can't be used for 856 & 810s
      **---------|--------|----|------|----------------------------**
      **D.Oligney|04/18/16| KMH|  SR  | Change Calculation on total
      **         |        |    |319862| Invoice amount
      **---------|--------|----|------|----------------------------**
      **D.Oligney|05/02/16| KMH|  SR  | Add Baldor to EDI Invoicing,
      **         |        |    |379129| Array 1205
      **---------|--------|----|------|----------------------------**
      **D.Oligney|05/10/16| KMH|  SR  | Chg Bosch Rexroth to new VAN
      **         |        |    |375854| ISA name change only
      **---------|--------|----|------|----------------------------**
      **D.Oligney|05/18/16| KMH|  SR  | Add Danfoss to EDI Invoicing,
      **         |        |    |356610| Array 5617 only
      **---------|--------|----|------|----------------------------**
      **B.Olson  |05/19/16| BJH|  SR  | Add eng surcharge fields to
      **         |        |    |323577| ivcprt and edidetl
      **---------|--------|----|------|----------------------------**
      **D.Oligney|06/29/16| KMH|  SR  | Chg Baldor to add SAC Code to
      **         |        |    |379129| collect Dunnage dollars
      **---------|--------|----|------|----------------------------**
      **D.Oligney|07/15/16| KMH|  SR  | Changed program to perform the
      **         |        |    |409703| PID segment before reading next
      **         |        |    |      | record, for DANFOSS only
      **---------|--------|----|------|----------------------------**
      **A.Weis   |07/18/16| KMH|  IR  | Add Energy Surchg to unit price
      **         |        |    |410859| for cust 6740 only
      **---------|--------|----|------|----------------------------**
      **B.Olson  |08/31/16| KMH|  IR  | Add SAC Segment to Danfoss #5617
      **         |        |    |421351| to denote Energy Surcharge
      **---------|--------|----|------|----------------------------**
      **D.Oligney|09/15/16| KMH|  IR  | Add SF to N1 segment for CAT and
      **         |        |    |424568| change ST 04 to Translation code
      **---------|--------|----|------|----------------------------**
      **D.Oligney|10/05/16| KMH|  IR  | Added Energy Surcharge to line
      **         |        |    |428556| price for Baldor 1205
      **---------|--------|----|------|----------------------------**
      **D.Oligney|10/18/16| KMH|  SR  | Clear UINV field to remove garbage
      **         |        |    |431230| before filling PS field ALSO,
      **         |        |    |      | remove Hardcoding of SE and ST.
      **---------|--------|----|------|----------------------------**
      **Darrell O|10/25/16| BJH|  SR  | HMA EDI invoice setup for cust
      **         |        |    |431872|   2728
      **---------|--------|----|------|----------------------------**
      **B.Olson  |11/01/16| KMH|  IR  | Remove SAC Segment to Danfoss
      **         |        |    |433680| #5617 to denote Energy Surcharge
      **         |        |    |      | and instead add cost to line %T1
      **---------|--------|----|------|----------------------------**
      **D.Oligney|03/02/17| KMH|  IR  | Chg Baldor to remove SAC coding
      **         |        |    |428556| that collected Dunnage per cust
      **---------|--------|----|------|----------------------------**
      **D.Oligney|03/07/17| KMH|  IR  | Chg Baldor - Fix line number on
      **         |        |    |428556| Invoice, should always be '001'
      **---------|--------|----|------|----------------------------**
      **B.Olson  |04/10/17| KMH|  SR  | Change Remittance Address for
      **         |        |    |439638| Accounting (IR480698)
      **---------|--------|----|------|----------------------------**
      **oligney  |06/28/17| BJH|  IR  | change hitachi pd address
      **         |        |    |486948|
      **---------|--------|----|------|----------------------------**
      **oligney  |08/09/17| BJH|  IR  | change hitachi pd address
      **         |        |    |486948|
      **---------|--------|----|------|----------------------------**
      **D.Oligney|05/16/17| KH |  IR  | Changed Hitachi code to pro-
      **         |        |    |579424| cess Invoices for Cust# 2872
      **         |        |    |      | PD82730020 Code = Ford & Honda
      **         |        |    |      | and is processed through SAP
      **         |        |    |      | PD86852601 Code = Subaru and
      **         |        |    |      | and is processed on iBMI
      **---------|--------|----|------|----------------------------**
      **D.Oligney|07/20/18| KMH|  IR  | Added a clear to fields that
      **         |        |    |598601| were not being cleared on next
      **         |        |    |      | record when processing
      **---------|--------|----|------|----------------------------**
      **D.Oligney|08/23/18| KMH|  IR  | Remove Trading Partner ID
      **         |        |    |609634| 623346764 per John Deere and
      **         |        |    |      | tranfer current customers to
      **         |        |    |      | 149825353
      **---------|--------|----|------|----------------------------**
      **D.Oligney|08/23/18| KMH|  IR  | Bosch Rexroth Germany requested
      **         |        |    |609698| to be removed from EDi process
      **---------|--------|----|------|----------------------------**
      **D.Oligney|12/10/18| KMH|  IR  | Add CAT Array 1583 to EDI
      **         |        |    |640088|
      **---------|--------|----|------|----------------------------**
      **D.Oligney|12/26/18| KMH|  IR  | Replace Cust# 1604 to be 1727
      **         |        |    |637372| Change Trading Partner# to
      **         |        |    |      | 812912349
      **---------|--------|----|------|----------------------------**
      **D.Oligney| 3/08/19| KMH|  IR  | Add additional TP version for
      **         |        |    |667535| Customer 1994
      **---------|--------|----|------|----------------------------**
jc01a **D.Oligney| 4/08/19| JC |  sr  | Remove Bosch for cust 8101.
jc01a **         |        |    |379169|
      **---------|--------|----|------|----------------------------**
jc02a **D.Oligney| 4/10/19| JC |  sr  | Add release to Kohler (6325)
jc02a **         |        |    |605063| if not already present.
      **---------|--------|----|------|----------------------------**
jc03a **Internal | 8/12/19| JC |      | Fix missing code for moly
jc03a **         |        |    |      | charge (if present) for catepillar
      **---------|--------|----|------|----------------------------**
jc04 ** D.Oligney|08/28/19| JC |  SR  | Add Bobcat - array number  **
jc04 **          |        |    |356344| 1271, 2094, 3740.          **
      **---------|--------|----|------|----------------------------**
jc06 ** D.Oligney|10/16/19| JC |  SR  | Add Bobcat - REF*IA value  **
jc06 **          |        |    |356344| from EDPMSTL1.             **
      **---------|--------|----|------|----------------------------**
jc07 ** A.Weis   |12/12/19| JC |  IR  | Add Cat cust 2107 to EDI   **
jc07 **          |        |    |743802| processing.                **
      **---------|--------|----|------|----------------------------**
jc08 ** Doosan   |01/03/20| JC |  SR  | Do not send IT1 PL*line#.  **
jc08 **          |        |    |356344| Clear value so leftover    **
jc08 **          |        |    |      | data not sent.             **
      **---------|--------|----|------|----------------------------**
jc09 ** Doosan   |01/16/20| JC |  IR  | Do not send EDI invoice to **
jc09 **          |        |    |749352| Bobcat if PO is < 378779   **
jc09 **          |        |    |      | or > 500000.               **
      **---------|--------|----|------|----------------------------**
kh01a** A.Weis   |01/24/20| KH |  IR  | Change CAT MX Dunnage code **
kh01a**          |        |    |754660| since different then US    **
      **---------|--------|----|------|----------------------------**
      **D.Oligney|02/06/20| KH |  SR  | Adding hitachi invoicing for
      **         |        |    |735946| GM - Cust# 2868 Production
      **         |        |    |      | GM - Cust# 3076 Service
      **---------|--------|----|------|----------------------------**
jc10 ** Cat MX   |06/11/20| JC |  IR  | Changed to send dunnage    **
jc10 **          |        |    |795698| amount on invoice.  Was    **
jc10 **          |        |    |      | originally commented out.  **
      **---------|--------|----|------|----------------------------**
jc11 ** Cat MX   |06/15/20| JC |  IR  | Emergency fix to EDI027 to **
jc11 **          |        |    |796777| limit change for IR795698  **
jc11 **          |        |    |      | to only cust 2107.         **
      **---------|--------|----|------|----------------------------**
      **Dawn D.  |07/13/20| KH |  IR  | Adding additional GM customers
      **         |        |    |805092| for GM/Hitachi processing
      **---------|--------|----|------|----------------------------**
      **Dawn D.  |07/27/20| KH |  IR  | Adding additional GM customers
      **         |        |    |809323| for GM/Hitachi processing again
      **---------|--------|----|------|----------------------------**
jc12  **B.Haase  |10/13/20| JC |  SR  | Setup DTNA array 2175, 2179,
jc12  **         |        |    |736888| and 2211 for EDI invoices
jc12  **         |        |    |      | As part of this mod the SAC
jc12  **         |        |    |      | normally written out at
jc12  **         |        |    |      | summary time is now written
jc12  **         |        |    |      | at the line detail level.
jc13  **         |        |    |      | Changes made to account for
jc13  **         |        |    |      | PO# concatenated with PO line
jc13  **         |        |    |      | number.
      ****************************************************************
     FEDIMSTR   UP   E             DISK
     FEDIDETL   IF   E           K DISK
     FEDIDUNN   IF   E           K DISK
     Fcustadrs  IF   E           K DISK
     Fpartfile  IF   E           K DISK
     FPRTDSC01  IF   E           K DISK
     Fivcprth   IF   E           K DISK
     FBTCAGE    IF   E           K DISK
     FBILLTO    IF   E           K DISK
     FMOLDOR10  IF   E           K DISK
     Fordmvmnt  IF   E           K DISK
     FUINV4101  O    E             DISK
     FUINV4103  O    E             DISK
     FUINV4104  O    E             DISK
     FUINV4107  O    E             DISK
     FUINV4108  O    E             DISK
     FUINV4111  O    E             DISK
     FUINV4112  O    E             DISK
     FUINV4131  O    E             DISK
     FUINV4134  O    E             DISK
     Fuinv4136  O    E             DISK
     Fuinv4138  O    E             DISK
     FUINV4144  O    E             DISK
     FUINV4152  O    E             DISK
     FUINV4171  O    E             DISK
     FUINV4172  O    E             DISK
     FUINV4175  O    E             DISK
     FUINV4177  O    E             DISK
     FUINV4178  O    E             DISK
     FEDIDATE   UF   E             DISK
     FCUSMF     IF   E           K DISK
     FDUNNAGE   IF   E           K DISK
     FDUNUSAGE  IF   E           K DISK
     FDUNIVC    IF   E           K DISK
     FIVCPARTS  IF   E           K DISK
     Fivcpar01  IF   E           K DISK
     F                                     rename(flivcpar:FLivcpa2)
     Fivcpar03  IF   E           K DISK
     F                                     rename(flivcpar:FLivcpa3)
     FASNCUST   IF   E           K DISK
     FEDM4123   IF   E           K DISK
     FEDM412301 IF   E           K DISK
     F                                     rename(flem#23:FLem#23b)
     FEDM4124   IF   E           K DISK
     FLFWPC202  IF   E           K DISK
      * Begin - SR319862
     FEDP07004  IF   E           K DISK
     FEDP04002  IF   E           K DISK
jc06 FEDPMSTL1  IF   E           K DISK
      * End   - SR319862
jc12 FIVCPAR05  IF   E           K DISK    PREFIX(L_) RENAME(FLIVCPAR:IVCLONG)
jc12 FPRTPLT03  IF   E           K DISK
jc12 FSUPLOL01  IF   E           K DISK
      *
     D Unitpc          DS
     D  UPRI                   1      3
     D  ucnt                   4      5
      *
     D Huprc           DS
     D  HPRC                   1      3
     D  HDec                   4      4
     D  Hcnt                   4      6
      *
     D                SDS
     D  pyear                  1      4  0
     D  pmo                    5      6  0
     D  pday                   7      8  0
     D  podate                 1      8  0
      *
      * Begin - SR335992
     D***** TXT             S             35    DIM(35) CTDATA PERRCD(1)
     D TXT             S             35    DIM(50) CTDATA PERRCD(1)
      * End   - SR335992
     D hldprt          s             40a
     D hldpo           s             22a
     D ARRNUM          S              1    DIM(20)
     D DIGITS          C                   CONST('0123456789 ')
     D POS             S             20U 0
     D X               S              4  0
      *
2892AD PARTNO          S             30
2892AD FOUND           S              1

jc02aD c_KohlerAry#    C                   CONST(+6325)
jc04 D c_BobcatAry#01  C                   CONST(+1271)
jc04 D c_BobcatAry#02  C                   CONST(+2094)
jc04 D c_BobcatAry#03  C                   CONST(+3740)
jc12 D c_DTNAFtlMfg01  C                   CONST(+2175)
jc12 D c_DTNAFtlMfg02  C                   CONST(+2179)
jc12 D c_DTNAFtlMfg03  C                   CONST(+2211)
      *
     C     ABC           TAG
      /EJECT
      ****************************************************************
      * 'FIRST PASS' ROUTINE TO PRELOAD ALL PREMENOS FILE IDENTIFIERS
      * AND ALL HARD CODED ITEMS - AND UPDATE THE EDIDATE FILE WITH
      * TODAYS DATE.
      ****************************************************************
     C     *IN90         IFEQ      '0'
     C                   MOVE      '1'           *IN90
      *
     C     *ENTRY        PLIST
     C                   PARM                    INREC             3
     C                   Z-ADD     0             REC#              3 0
      *-------------------------------------------------------------
      * 12-9-94: BECAUSE OF A CHANGE IN INVOICING POLICY THE DISCOUNT
      * OF .5%/10 DAYS HAS BEEN DROPPED.  ALL INVOICES ARE NOW "NET
      * 30 DAYS".  THEREFORE, ELEMENTS 'ITD03', 'ITD04' & 'ITD08' ARE
      * NO LONGER USED.  THE CODE IN 'ITD01' WAS CHANGED FROM '08'
      * (BASIC DISCOUNT OFFERED) TO '05' (DISCOUNT NOT APPLICABLE).
      * ELEMENT 'ITD07' (TERMS NET DAYS) WAS ADDED AND IS SET TO "30".
      *-------------------------------------------------------------
      /SPACE
     C                   MOVE      'PC'          V31003
     C                   MOVE      'BP'          V31006
     C                   MOVE      'PO'          V31008
      **============================================================**
      ** UPDATE EDIDATE FILE WITH TODAYS DATE
      **============================================================**
     C                   READ      FLEDIDAT                               20
     C                   MOVE      UMONTH        EDT001
     C                   MOVE      UDAY          EDT002
     C                   MOVE      UYEAR         EDT003
     C                   UPDATE    FLEDIDAT
     C                   END
      *-------------------------------------------------------------
      ** UPDATE EDIDATE FILE WITH TODAYS DATE
      *-------------------------------------------------------------
     C     UYEAR         IFGT      75
     C                   Z-ADD     19000000      DATE8             8 0
     C                   ELSE
     C                   Z-ADD     20000000      DATE8
     C                   END
      **============================================================**
      ** BYPASS ROUTINE - THE FOLLOWING SITUATIONS WILL BE BYPASSED **
      **     1 - THIS IS NOT A JOHN DEERE CUSTOMER (USE ARRAY NO.)  **
      **         or specified customer selected                     **
      **     2 - INVOICE ALREADY TRANSFERED (EDI019 IS NE 0)        **
      **     3 - PACKING SLIP IS IN ONE OF THE FOLLOWING RANGES     **
      **                    A.      1 -  9999 MATINETTE MISC INV.   **
      **                    B.  10000 - 19999 WAUPACA MISC INV.     **
      **                    C.  50000 - 59999 PATTERN BILLING       **
      **                    D.  60000 - 69999 WAUPACA PRICE LATER   **
      **                    E.  70000 - 79999 MARINETTE PRICE LATER **
      **     4 - THIS IS NOT AN EDI CUSTOMER (CMF066 = BLANK)       **
      **     5 - NO DETAIL LINE ITEMS                               **
      **============================================================**
      /EJECT
jc04 C                   EVAL      ASN001 = EDI001
jc04 C     ASN001        CHAIN     ASNCUST
jc04 C                   IF        not %Found(ASNCUST)
jc04 C                   CLEAR                   FLASNCUS
jc04 C                   ENDIF
     *==============================================================*
     * Customer Number      ========================================*
     *==============================================================*
     C                   Z-ADD     EDI001        CUST4             4 0
     C                   MOVEL     *blanks       V01000
     *==============================================================*
     * J.D. Waterloo Tractor Works =================================*
     * J.D. consumer products      =================================*
     * J.D. Desmoines         ======================================*
     * j.d. Seeding/SAP and Harvestor ==============================*
     * J.D. Ottumwa           ======================================*
     * J.D. AG                ======================================*
     *==============================================================*
     C                   IF        EDI026 = 1725 or EDI026 = 1923 or
     C                             EDI026 = 1730 or EDI026 = 1846 or
     C                             EDI026 = 1736 or EDI026 = 1737 or
     C                             EDI026 = 2005 or EDI026 = 1928
     C                   MOVEL     '149825353'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D. power products         =================================*
     *==============================================================*
     C     EDI026        IFEQ      1990
     C                   MOVEL     '602873499'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D. comercial         ======================================*
     *==============================================================*
     C*****              IF        EDI026 = 1928 or EDI026 = 2005
     C*****              MOVEL     '623346764'   V01000
     C*****              GOTO      CHECK2
     C*****              END
     *==============================================================*
     * J.D. Horicon/SAP            =================================*
     *==============================================================*
     C     EDI026        IFEQ      1731
     C                   MOVEL     '006102545'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D. engine works (sap)     =================================*
     *==============================================================*
     C     EDI026        IFEQ      1726
     C                   MOVEL     '021688858'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D Mexico             ======================================*
     *==============================================================*
     C     EDI026        IFEQ      1727
     C                   MOVEL     '812912349'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D. worldwide logistics    =================================*
     *==============================================================*
     C     EDI026        IFEQ      1811
     C                   MOVEL     '156471773'   V01000
     C     EDI001        IFEQ      1994
     C                   MOVEL     '156471773P4' V01000
     C                   END
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * world class industries      =================================*
     *==============================================================*
     C     EDI026        IFEQ      6740
     C                   MOVEL     '6308206622'  V01000
     C                   GOTO      CHECK2
     C                   END
jc12 *==============================================================*
jc12 * DTNA                        =================================*
jc12 * Partner id is DTNA + space + Supplier id (from SUPLOVR by   =*
jc12 *                              part, plant, cust).            =*
jc12 *==============================================================*
jc12 C                   IF        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C     EDI002        CHAIN     EDIDETL
jc12 C                   EXSR      GetPlant
jc12 C                   EXSR      sr_GetPartner
jc12 C                   EVAL      V01000 = w_PartnerId
jc12 C                   EVAL      ASN014 = SUPL01
jc12 C                   GOTO      CHECK2
jc12 C                   Endif
jc07 *==============================================================*
jc07 * Cat Mexico                  =================================*
jc07 *==============================================================*
jc07 C     EDI026        IFEQ      2107
jc07 C                   MOVEL     '005070479XE' V01000
jc07 C                   GOTO      CHECK2
jc07 C                   END
     *==============================================================*
     * CAT                       =================================*
     *==============================================================*
     C                   IF        EDI026 = 1500
     C                             or EDI026 = 1583
jc07 C                             or EDI026 = 2107
     C                   MOVE      *blanks       Qual              2
     C     EDI002        Chain     FLEDIDET                           25
     C                   IF        %found
     C                   CLEAR                   ARRNUM
     C                   MOVEA     EDD003        ARRNUM
     C                   CLEAR                   LENGTH            3 0
     C                   EVAL      LENGTH=20
     C                   EXSR      CKNUMERIC
     C                   IF        NUMERIC='Y'
     C                   MOVEL     '0050704792V' V01000
     C*** TEST ***       MOVEL     '00507047990' V01000
     C                   MOVE      '2V'          Qual              2
     C                   GOTO      CHECK2
     C                   Else
     C                   MOVEL     '00507047919' V01000
     C*** TEST ***       MOVEL     '00507047990' V01000
     C                   MOVE      '19'          Qual              2
     C                   GOTO      CHECK2
     C                   ENDIF
     c                   else
     C                   MOVEL     '00507047919' V01000
     C                   GOTO      CHECK2
     C                   ENDIF
     C                   ENDIF
     *==============================================================*
     * Bosch/Rexroth             =================================*
     *==============================================================*
     C*****              IF        EDI026 = 8101 or EDI026 = 8104
jc01dC****               IF        EDI026 = 8101
jc01dC****               MOVEL     '608599270LIF'V01000
jc01dC****               GOTO      CHECK2
jc01dC****               END
     *==============================================================*
     * Hypro                     =================================*
     *==============================================================*
     C     EDI026        IFEQ      2703
     C                   MOVEL     'HYPROINC'    V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * CNH 810                     =================================*
     *==============================================================*
     C                   IF        EDI001 = 1458 or EDI001 = 1475 or
     C                             EDI001 = 1476 or EDI001 = 1488 or
     C                             EDI001 = 1467 or EDI001 = 1962 or
     C                             EDI026 = 1472 or EDI026 = 1551 or
     C                             EDI026 = 1489
     C                   MOVEL     'CNHNCMMFG'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * CNH 810 test                =================================*
     *==============================================================*
     C***  EDI001        IFEQ      1402
     C***                MOVEL     '601943181T'  V01000
     C***                GOTO      CHECK2
     C***                END
     *==============================================================*
     C                   IF        EDI001 = 1490 or EDI001 = 1959
     C                   MOVEL     'CNHNCMSP'    V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * Cat Belgium                 =================================*
     *==============================================================*
     C     EDI026        IFEQ      1594
     C                   MOVEL     '00507047925' V01000
      *test id is 91
     C*                  MOVEL     '00507047991' V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * J.D. consumer products      =================================*
     *==============================================================*
     C     EDI026        IFEQ      1463
     C                   MOVEL     '008473506'   V01000
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * NACCO                       =================================*
     *==============================================================*
      * Begin - SR319862
      *
     C                   IF        EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802
      *
      * Process Hyster-Yale using the Supplier Code in the GS Segment
      *
     C     PSKEY         KLIST
     C                   KFLD                    PS#               6 0
      *
     C                   EVAL      PS# = *ZEROS
     C                   MOVEL     EDI002        PS#
      *
     C     PSKEY         CHAIN     IVCPRTH
     C                   Z-ADD     EDI001        CUST#
      *
     C     CUST#         CHAIN     CUSMF
     C                   IF        IVP004 = '1'
     C                   EVAL      V01000 = 'HUBSPANINVP1   '
     C*****              EVAL      V01000 = 'HUBSPANINVP1T  '
     C                   ELSEIF    IVP004 = '2' OR IVP004 = '3'
     C                   EVAL      V01000 = 'HUBSPANINVP23  '
     C*****              EVAL      V01000 = 'HUBSPANINVP23T '
     C                   ELSEIF    IVP004 = '4'
     C                   EVAL      V01000 = 'HUBSPANINVP4   '
     C*****              EVAL      V01000 = 'HUBSPANINVP4T  '
     C                   ELSEIF    IVP004 = '5'
     C                   EVAL      V01000 = 'HUBSPANINVP5   '
     C*****              EVAL      V01000 = 'HUBSPANINVP5T  '
     C                   ELSEIF    IVP004 = '6'
     C                   EVAL      V01000 = *BLANKS
     C                   ENDIF
      *
      * End   - SR319862
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * Kohler                    =================================*
     *==============================================================*
     C     EDI026        IFEQ      6325
     C                   MOVEL     'ENGVNDRP'    V01000
     C                   GOTO      CHECK2
     C                   END
      * Begin - SR335992
     *==============================================================*
     * hitachi metals america      =================================*
     *==============================================================*
     C     EDI026        IFEQ      2728
     C                   MOVEL     '9146949200'  V01000
     C                   GOTO      CHECK2
     C                   END
      * End   - SR335992
      * Begin - SR379129
     *==============================================================*
     * Baldor                      =================================*
     *==============================================================*
     C     EDI026        IFEQ      1205
     C***TEST***         MOVEL     '5016485633-T'V01000
     C                   MOVEL     '5016485633  'V01000
     C                   GOTO      CHECK2
     C                   END
      * End   - SR379129
      * Begin - SR356610
     *==============================================================*
     * Danfoss/Doosan              =================================*
     *==============================================================*
     C                   IF        EDI026 = 5617
     C***TEST***         MOVEL     'WAUDANTAUT'  V01000
     C                   MOVEL     'WAUDANTAU '  V01000
     C                   GOTO      CHECK2
     C                   END
      * End   - SR356610
jc04 *==============================================================*
jc04 * Bobcat/Doosan                                                *
jc04 *==============================================================*
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc04 C                   IF        ASN003 = *Blanks
jc04 C                   EVAL      V01000 = '7012418700'
jc04 C                   ELSE
jc04 C                   EVAL      V01000 = ASN003
jc04 C                   ENDIF
jc04 C                   GOTO      CHECK2
jc04 C                   END
      * Begin - SR335992
     *==============================================================*
     * For the Rest           ======================================*
     *==============================================================*
     C                   GOTO      BYPASS
      /EJECT
     *==============================================================*
     *                                                             =*
     * Select Invoice Record  ======================================*
     *                                                             =*
     *==============================================================*
     C     CHECK2        TAG
      *
     C     EDI019        CABNE     0             BYPASS
      *
     C     EDI017        CABLE     19999         BYPASS
     C     EDI017        IFGE      50000
     C     EDI017        CABLE     79999         BYPASS
     C                   END
      *
     C                   MOVE      *BLANK        CMF066
     C     CUST4         CHAIN     FLCUSMF                            20
     C     CMF066        CABEQ     *BLANK        BYPASS
     C     CMF066        CABEQ     'N'           BYPASS

jc09  * For BOBCAT invoices, skip EDI if PO # < 378779
jc09  *                      or PO# > 500000
jc09 C                   IF        EDI026 = c_BobcatAry#01
jc09 C                             or EDI026 = c_BobcatAry#02
jc09 C                             or EDI026 = c_BobcatAry#03
jc09 C     EDI002        CHAIN     FLEDIDET                           20
jc09 C                   IF        *IN20 = *Off
jc09 C                   MOVE      *Zeros        PO_Numeric       15 0
jc09 C**                 EVAL      PO_Numeric = %dec(%trim(EDD003):15:0)
      /free
       monitor;
       eval PO_numeric= %dec(%trim(EDD003):15:0);
       on-error;
       endmon;
      /end-free
jc09 C                   IF        PO_Numeric <= 378779
jc09 C                             or PO_Numeric > 500000
jc09 C                   GOTO      BYPASS
jc09 C                   ENDIF
jc09 C                   ENDIF
jc09 C                   ENDIF

      *==========================================================
      * GET DATA FROM EDIDETL FILE
      *==========================================================
     C     EDI002        SETLL     FLEDIDET
     C                   Z-ADD     0             DETLIN            3 0
     C                   z-add     *ZEROS        TOTSC
      **============================================================**
      ** READ EDIDETL FILE -                                        **
      **============================================================**
     C     TOP04         TAG
     C                   READ      FLEDIDET                               20
     C     *IN20         CABEQ     '1'           END04
     C     EDD001        CABNE     EDI002        END04
     C     EDD004        CABEQ     *BLANK        TOP04
     C     EDD005        CABLE     0             TOP04
     C     EDD007        CABEQ     0             TOP04
     C     EDD012        CABEQ     'Y'           TOP04
     C     EDD013        CABEQ     'Y'           TOP04
     C                   ADD       1             DETLIN
     C                   GOTO      TOP04
     C     END04         TAG
     C     DETLIN        CABEQ     0             BYPASS
      /EJECT
     *==============================================================*
     * BIG        UINV4101       ==================================*
     *==============================================================*
     C                   Z-ADD     0             Bline             3 0
     C                   Z-ADD     0             Nline             3 0
     C                   MOVEL     EDI002        V01100
     C                   MOVEL     EDI001        V01200
     C                   MOVEL     Bline         V01300
     C                   MOVEL     nline         V01400
     C                   MOVEL     *blanks       V01500
      * Invoice Date
     C     EDI018        IFNE      0
     C                   Z-ADD     DATE8         V01001
     C                   ADD       EDI018        V01001
     C                   END
      * Invoice Number
     C                   MOVEL     EDI002        V01002
     C                   MOVE      *BLANK        V01004
      *---------------------------------------------------------------
      * Determine Purchase Order Number                            ---
      *---------------------------------------------------------------
     C                   EXSR      PONUMB
     C     *IN50         IFEQ      '0'
     C                   MOVEL     HOLDPO        V01004
     C                   END
     C     EDI026        IFEQ      1486
     C     EDI026        OREQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C     EDI026        OREQ      1594
     C     EDI026        OREQ      6325
     C     EDI026        OREQ      1205
     C     EDI026        OREQ      5617
jc04 C     EDI026        OREQ      c_BobcatAry#01
jc04 C     EDI026        OREQ      c_BobcatAry#02
jc04 C     EDI026        OREQ      c_BobcatAry#03
jc12 C     EDI026        OREQ      c_DTNAFtlMfg01
jc12 C     EDI026        OREQ      c_DTNAFtlMfg02
jc12 C     EDI026        OREQ      c_DTNAFtlMfg03
     C                   MOVEL     HOLDPO        V01004
jc13  * 11/6/2020 Change made for DTNA to assign line number and PO# from
jc13  * concatinated value currently stored as PO# (contains both PO# and
jc13  * po line number {3 bytes})
jc12 C     EDI026        IFEQ      c_DTNAFtlMfg01
jc12 C     EDI026        OREQ      c_DTNAFtlMfg02
jc12 C     EDI026        OREQ      c_DTNAFtlMfg03
jc13 C     *LIKE         DEFINE    w_Line#       W_POLen
jc13 C     *LIKE         DEFINE    w_Line#       W_POLineStart
jc13 C                   IF        %len(%trim(HOLDPO)) > 6
jc13 C                   EVAL      w_POLen = %len(%trim(HOLDPO)) - 3
jc13 C                   EVAL      w_POLineStart = w_POLen + 1
jc13 C                   EVAL      V01004 = %subst(HOLDPO:1:w_POLen)
jc13 C                   ELSE
jc13 C                   EVAL      V01004 = HOLDPO
jc13 C                   Endif
jc12 C                   ENDIF
     C                   ELSE
     C                   MOVEL     *blanks       V01004
     C                   END
      * BEGIN - SR431872
      * SCAN THE FIELD FOR 'ASN' AND IF NONE, MOVE EDI017 add Asn verbiage. IF F
      *  EDI013 as it is misc billing.
     C     EDI026        IFEQ      2728
     C                   Z-ADD     1             ZZ                3 0
     C     'ASN'         SCAN      EDI013
     C                   IF        %FOUND
     C                   MOVEL     EDI013        V01004
     C                   else
     C                   MOVEL     EDI017        V01004
     C                   ENDIF
     C                   END
      * END - SR431872
     C     EDI026        IFEQ      1594
     C                   MOVEL     *blanks       V01004
     C                   MOVEL     *blanks       V01005
     C                   MOVEL     *blanks       V01006
     C                   MOVEL     *blanks       V01007
     C                   MOVEL     'CA'          V01007
     C                   END
     C                   MOVEL     *blanks       V01003
     C     EDI026        IFEQ      6325
     C     EDI026        OREQ      5617
     C                   EXSR      PODATSR
     C                   MOVEL     podate        V01003
     C                   MOVEL     *blanks       V01005
     C                   MOVEL     *blanks       V01006
     C                   MOVEL     'DI'          V01007
     C                   END
      * Begin - SR335992
     C     EDI026        IFEQ      2728
     C                   MOVEL     *blanks       V01003
     C                   MOVEL     *blanks       V01005
     C                   MOVEL     *blanks       V01006
     C                   MOVEL     'DI'          V01007
     C                   END
      * End   - SR335992
      * Begin - SR319862
      * NACCO
     C                   IF        EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802
     C                   MOVEL     'CI'          V01007
     C                   ENDIF
      * End   - SR319862
      * Begin - SR379129
     C     EDI026        IFEQ      1205
     C                   EXSR      PODATSR
     C                   MOVEL     podate        V01003
     C                   MOVEL     *blanks       V01005
     C                   MOVEL     *blanks       V01006
     C                   MOVEL     'DR'          V01007
     C                   END
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc04 C                   IF        HoldPO = *Blanks
jc04 C                   MOVE      *Blanks       V01003
jc04 C                   MOVE      *Blanks       V01004
jc04 C                   ELSE
jc04 C                   EXSR      PODATSR
jc04 C                   MOVEL     podate        V01003
jc04 C                   MOVEL     *blanks       V01005
jc04 C                   MOVEL     *blanks       V01006
jc04 C                   MOVEL     'DR'          V01007
jc04 C                   ENDIF
jc04 C                   ENDIF
      * End   - SR379129
      *                  -----     -------
     C                   WRITE     FLINV01
     C                   MOVEL     *blanks       V01005
     C                   MOVEL     *blanks       V01006
     C                   MOVEL     *blanks       V01007
     *==============================================================*
     * CUR        UINV4103       ==================================*
     *==============================================================*
     C                   MOVEL     EDI002        V03100
     C                   MOVEL     EDI001        V03200
     C                   MOVEL     Bline         V03300
     C                   MOVEL     nline         V03400
     C                   MOVEL     *blanks       V03500
      * Begin - SR335992
     C                   MOVEL     *blanks       V03003
     C                   MOVE      *blanks       V03007
     C                   MOVE      *blanks       V03008
      * End   - SR335992
      * Begin - SR319862
     C                   IF        EDI026 = 1594 or EDI026 = 2704 or
     C                             EDI026 = 2706 or EDI026 = 2709 or
     C                             EDI026 = 2712 or EDI026 = 2783 or
     C                             EDI026 = 6802
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
      * End   - SR319862
     C                   MOVE      'SE '         V03001
     C                   ELSE
     C                   MOVE      'BY '         V03001
     C                   ENDIF
     C     EDI026        IFEQ      6325
     C                   MOVE      *blanks       V03001
     C                   MOVE      'ZZ '         V03001
     C                   ENDIF
jc01dC**** EDI026        IFEQ      8101
     C*****EDI026        orEQ      8104
jc01dC****               MOVE      *blanks       V03001
jc01dC****               MOVE      'II '         V03001
jc01dC****               ENDIF
      * Begin - SR356610  DANFOSS/DOOSAN
     C     EDI026        IFEQ      5617
     C                   MOVE      *blanks       V03001
     C                   MOVE      'SU '         V03001
     C                   ENDIF
      * End   - SR356610
     C                   MOVE      'USD'         V03002
      * Begin - SR335992
     C     EDI026        IFEQ      2728
     C                   MOVEL     '1.0000'      V03003
     C                   MOVE      '007'         V03007
     C                   MOVE      EDI018        V03008
     C                   ENDIF
      * End   - SR335992
      *                  -----     -------
     C                   WRITE     FLINV03
     *==============================================================*
     * REF        UINV4104       ==================================*
     *==============================================================*
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc06 C                   EVAL      E01003 = EDD003
jc06 C     E01003        CHAIN     EDPMSTL1
jc06 C                   IF        %Found(EDPMSTL1)
jc06 C                              and E01015 <> *Blanks
jc06 C                   EVAL      ASN014 = E01015
jc06 C                   ENDIF
jc04 C                   IF        ASN011 = 'IA'
jc04 C                   MOVEL     EDI002        V04100
jc04 C                   MOVEL     EDI001        V04200
jc04 C                   MOVEL     Bline         V04300
jc04 C                   MOVE      nline         V04400
jc04 C                   EVAL      V04500 = *Blanks
jc04 C                   EVAL      V04001 = ASN011
jc04 C                   EVAL      V04002 = ASN014
jc04 C                   WRITE     FLINV04
jc04 C                   ENDIF
jc04 C                   ENDIF
     C     EDI026        IFEQ      1486
     C     EDI026        OREQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     Bline         V04300
     C                   MOVEL     nline         V04400
     C                   MOVEL     *blanks       V04500
     C                   MOVE      'ZZ '         V04001
     C     EDI001        IFEQ      1490
     C                   MOVEL     'SPSNA'       V04002
     C                   ELSE
     C                   MOVEL     'CSCN'        V04002
     C                   endif
      *                  -----     -------
     C                   WRITE     FLINV04
     C                   ELSE
     C**** edi026        ifne      8101
     C*****edi026        andne     8104
     C     edi026        ifne      6325
     C     edi026        andne     2728
      * Begin - SR319862
     C     edi026        andne     2704
     C     edi026        andne     2706
     C     edi026        andne     2709
     C     edi026        andne     2712
     C     edi026        andne     2783
     C     edi026        andne     6802
      * End   - SR319862
     C     edi026        andne     1205
     C     edi026        andne     5617
jc04 C     EDI026        andne     c_BobcatAry#01
jc04 C     EDI026        andne     c_BobcatAry#02
jc04 C     EDI026        andne     c_BobcatAry#03
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     Bline         V04300
     C                   MOVEL     Nline         V04400
     C                   MOVEL     *blanks       V04500
     C                   MOVEL     *blanks       V04001
     C                   MOVEL     *blanks       V04002
     C                   MOVE      'PK '         V04001
     C                   MOVEL     EDI017        V04002
      *                  -----     -------
     C                   WRITE     FLINV04
     C                   endif
     C                   endif
      *
     C     edi026        ifeq      6325
jc12 C     edi026        oreq      c_DTNAFtlMfg01
jc12 C     edi026        oreq      c_DTNAFtlMfg02
jc12 C     edi026        oreq      c_DTNAFtlMfg03
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     Bline         V04300
     C                   MOVEL     Nline         V04400
     C                   MOVEL     *blanks       V04500
     C                   MOVEL     *blanks       V04001
     C                   MOVEL     *blanks       V04002
     C                   MOVE      'BM '         V04001
     C                   MOVEL     EDI017        V04002
      *                  -----     -------
     C                   WRITE     FLINV04
     C                   endif
      * Begin - SR335992
      * Begin - SR335992
      * Begin - IR579424
      * Add Hitachi Invoice Detail
      *
     C     EDI026        IFEQ      2728
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     Bline         V04300
     C                   MOVEL     Nline         V04400
     C                   MOVEL     *blanks       V04500
     C                   MOVEL     *blanks       V04001
     C                   MOVEL     *blanks       V04002
     C                   MOVEL     *blanks       V04003
     C                   MOVE      'IA '         V04001
     C                   MOVEL     EDI017        V04002
      *
      * Add Codes to notify Hitachi which system they will use for
      * Subaru (PD86852601) or Ford and Honda (DPD82730020).  Array#
      * 2728 will not be used for invoicing as a Ship-To though IBMi.
      * Hitachi GM Production Code is (PD82917601), Hitachi GM Service
      * Code is (PD82717603)
      *
     C                   SELECT
     C                   WHEN      EDI001 = 2794 or EDI001 = 2819 or
     C                             EDI001 = 2872
     C                   MOVEL     TXT(45)       V04003
      * GM - Production
     C                   WHEN      EDI001 = 2868 or EDI001 = 2878 or
     C                             EDI001 = 3047 or EDI001 = 3058 or
     C                             EDI001 = 3069 or EDI001 = 3077 or
     C                             EDI001 = 3078 or EDI001 = 3088
     C                   MOVEL     TXT(46)       V04003
      * GM - Service
     C                   WHEN      EDI001 = 3076
     C                   MOVEL     TXT(47)       V04003
     C                   OTHER
     C                   MOVEL     TXT(44)       V04003
     C                   ENDSL
      *                  -----     -------
     C                   WRITE     FLINV04
      *
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     BLINE         V04300
     C                   MOVEL     NLINE         V04400
     C                   MOVEL     *BLANKS       V04500
     C                   MOVE      'VN '         V04001
     C                   MOVEL     *BLANKS       V04002
     C                   MOVEL     EDI001        V04002
     C                   MOVEL     *BLANKS       V04003
      *                  -----     -------
     C                   WRITE     FLINV04
     C                   ENDIF
      * End   - IR579424
      * End   - SR335992
      * Begin - SR379129
      *   Baldor
     C                   IF        EDI026 = 1205
     C                   MOVEL     EDI002        V04100
     C                   MOVEL     EDI001        V04200
     C                   MOVEL     Bline         V04300
     C                   MOVEL     Nline         V04400
     C                   MOVEL     *blanks       V04500
     C                   MOVEL     *blanks       V04001
     C                   MOVEL     *blanks       V04002
     C                   MOVE      'IA '         V04001
     C     EDI002        CHAIN     LFWPC202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V04002
     C                   ELSEIF    MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V04002
     C                   ELSEIF    MOS005 = '4'
     C                   MOVEL     CMF077        V04002
     C                   ELSEIF    MOS005 = '5'
     C                   MOVEL     CMF092        V04002
     C                   ELSEIF    MOS005 = '6'
     C                   MOVEL     CMF093        V04002
     C                   ENDIF
      *                  -----     -------
     C                   WRITE     FLINV04
     C                   ENDIF
      * End   - SR379129
jc12 C                   If        edi026 = c_DTNAFtlMfg01
jc12 C                             or edi026 = c_DTNAFtlMfg02
jc12 C                             or edi026 = c_DTNAFtlMfg03
jc12 C                   MOVEL     EDI002        V04100
jc12 C                   MOVEL     EDI001        V04200
jc12 C                   MOVEL     Bline         V04300
jc12 C                   MOVEL     Nline         V04400
jc12 C                   MOVEL     *blanks       V04500
jc12 C                   MOVEL     *blanks       V04001
jc12 C                   MOVEL     *blanks       V04002
jc12 C                   MOVE      'SI '         V04001
jc12 C                   MOVEL     EDI017        V04002
jc12  *                  -----     -------
jc12 C                   WRITE     FLINV04
jc12 C                   endif
     *==============================================================*
     * N1,2,3,4   UINV4107       ==================================*
     *==============================================================*
      *set up qualifiers?
     C     EDI026        IFEQ      1182
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'SF '         V07001
     C                   MOVEL     TXT(1)        V07002
     C                   MOVEL     TXT(2)        V07015
     C                   MOVEL     TXT(3)        V07016
     C                   MOVEL     TXT(4)        V07017
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'SE '         V07001
     C
     C                   MOVEL     *blanks       V07004
     C                   MOVE      '006133441'   V07004
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'RE '         V07001
     C                   MOVEL     TXT(5)        V07002
     C                   MOVEL     TXT(6)        V07007
     C                   MOVEL     TXT(7)        V07015
     C                   MOVEL     TXT(8)        V07016
     C                   MOVEL     TXT(9)        V07017
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   ENDIF
      *** Nacco **************************************
     C                   IF        EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802

     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500

     C     BXPOID        KLIST
     C                   KFLD                    E00000
     C                   KFLD                    E70100
     C                   KFLD                    IDCODE            3

      * Get part associated with the PO# so that it can chain to EDP070
      * in the next step. (part is irrelavent at this time just need 1)

     C     EDI002        CHAIN     EDIDETL
     C                   IF        %FOUND(EDIDETL)

      * Setup to find Mailbox number from EDP070

     C                   MOVE      *BLANKS       PO22
     C                   MOVE      *BLANKS       PRT40
     C                   MOVEL     EDD003        PO22
     C                   MOVEL     EDD004        PRT40

     C     PO22          CHAIN     EDP07004
     C                   IF        %FOUND(EDP07004)

      * Get N1 segments for Nacco 'BT '

     C                   MOVE      'BT '         IDCODE
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07018

     C     BXPOID        CHAIN     EDP04002
     C                   IF        %FOUND(EDP04002)
     C                   MOVE      IDCODE        V07001
     C                   MOVEL     E40002        V07002
     C                   MOVEL     E40003        V07003
     C                   MOVEL     E40004        V07004
     C                   ELSE
     C                   MOVE      'BT '         V07001
     C                   EVAL      V07004 = 'HUBSPANMINTX12P'
     C*****              EVAL      V07004 = 'HUBSPANMINTX12T'
     C                   MOVEL     '92'          V07003
     C                   ENDIF

      * Get correct country code for 'BT ' NACCO

     C                   IF        E40018 <> *BLANKS
     C                   MOVEL     E40018        V07018
     C                   ELSE
     C                   MOVEL     'US'          V07018
     C                   ENDIF
     C                   WRITE     FLINV07

      * Get N1 segments for Nacco 'BY '

     C                   MOVE      'BY '         IDCODE
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07018

     C     BXPOID        CHAIN     EDP04002
     C                   IF        %FOUND(EDP04002)
     C                   MOVE      IDCODE        V07001
     C                   MOVEL     E40002        V07002
     C                   MOVEL     E40003        V07003
     C                   MOVEL     E40004        V07004

      * Get correct country code for 'BY ' NACCO

     C                   IF        E40018 <> *BLANKS
     C                   MOVEL     E40018        V07018
     C                   ELSE
     C                   MOVEL     'US'          V07018
     C                   ENDIF
     C                   WRITE     FLINV07
     C                   ENDIF

      * Get N1 segments for Nacco 'SE '

     C                   MOVE      'SE '         IDCODE
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004

     C     BXPOID        CHAIN     EDP04002
     C                   IF        %FOUND(EDP04002)
     C                   MOVE      IDCODE        V07001
     C                   MOVEL     E40002        V07002
     C                   MOVEL     E40003        V07003
     C                   MOVE      E40004        V07004
     C                   ELSE
     C                   MOVE      IDCODE        V07001
     C                   MOVEL     TXT(1)        V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     TXT(30)       V07004
     C                   ENDIF

     C                   MOVEL     'US'          V07018
     C                   WRITE     FLINV07

      * Get N1 segments for Nacco 'ST '

     C                   MOVE      'ST '         IDCODE
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07018

     C     BXPOID        CHAIN     EDP04002
     C                   IF        %FOUND(EDP04002)
     C                   MOVE      IDCODE        V07001
     C                   MOVEL     E40002        V07002
     C                   MOVEL     E40003        V07003
     C                   MOVEL     E40004        V07004
     C                   ELSE
     C                   MOVE      'ST '         V07001
     C                   MOVEL     '92'          V07003
     C                   MOVE      CMF001        V07004
     C                   ENDIF

      * Get correct country code for 'ST ' NACCO

     C                   IF        E40018 <> *BLANKS
     C                   MOVEL     E40018        V07018
     C                   ELSE
     C                   MOVEL     'US'          V07018
     C                   ENDIF
     C                   WRITE     FLINV07

     C                   ENDIF
     C                   ENDIF

     C                   ENDIF

      * End   - SR319862

      *** kohler**************************************
     C     EDI026        IFEQ      6325
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'SU '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C     edi002        CHAIN     lfwpc202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSE
     C                   IF        MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   ELSE
     C                   IF        MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   ELSE
     C                   IF        MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   ELSE
     C                   IF        MOS005 = '6'
     C                   MOVEL     CMF093        V07004                        P
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVE      'ST '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     'KS       '   V07004
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVE      'BT '         V07001
     C                   MOVEL     *blanks       V07002
     C                   EVAL      V07002 = 'ACCOUNTS PAYABLE DEPT - ENG1'
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVE      'SF '         V07001
     C                   MOVEL     *blanks       V07002
     C                   EVAL      V07002 = 'WFI        '
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C     edi002        CHAIN     lfwpc202                           25
      *
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSE
     C                   IF        MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   ELSE
     C                   IF        MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   ELSE
     C                   IF        MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   ELSE
     C                   IF        MOS005 = '6'
     C                   MOVEL     CMF093        V07004                        P
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   ENDIF
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'II '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     TXT(11)       V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     '120287'      V07004                        P
      *
     C                   MOVEL     TXT(2)        V07015
     C                   MOVEL     TXT(3)        V07016
     C                   MOVEL     TXT(4)        V07017
     C                   MOVEL     'US'          V07018
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   ENDIF
      * Begin - SR379129
      *** Baldor - N1 Segment ************************
     C                   IF        EDI026 = 1205
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07011
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'VN '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C     EDI002        CHAIN     LFWPC202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSEIF    MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   ELSEIF    MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   ELSEIF    MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   ELSEIF    MOS005 = '6'
     C                   MOVEL     CMF093        V07004
     C                   ENDIF
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVE      'BY '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     EDI003        V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     '0003     '   V07004
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVE      'ST '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     EDI008        V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     CMF086        V07004
     C                   Z-ADD     2             CSTTYP            3 0
      * Baldor - N2, N3, N4
     C     CSTKEY        KLIST
     C                   KFLD                    CUST4
     C                   KFLD                    CSTTYP
      *
     C     CSTKEY        CHAIN     CUSTADRS
     C                   IF        NOT %FOUND(CUSTADRS)
     C                   Z-ADD     1             CSTTYP
     C     CSTKEY        CHAIN     CUSTADRS
     C                   ENDIF
      *
     C                   MOVEL     CAD004        V07011
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     CAD006        V07015
     C                   MOVEL     CAD007        V07016
     C                   MOVEL     CAD008        V07017
     C                   MOVEL     CAD009        V07018
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   ENDIF
      * End   - SR379129
      ***************************************************
      *** CNH/N1 830 info    **************************************
      ***************************************************
jc12 C                   move      'N'           f_SU_Sent         1
jc12 C                   move      'N'           f_ST_Sent         1
     C     EDI026        IFEQ      1486
     C     EDI026        oreq      1489
     C     EDI026        oreq      1472
     C     EDI026        oreq      1551
     C     EDI026        oreq      1962
jc12 C     EDI026        OREQ      c_DTNAFtlMfg01
jc12 C     EDI026        OREQ      c_DTNAFtlMfg02
jc12 C     EDI026        OREQ      c_DTNAFtlMfg03
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
      *
     C     EDI002        chain     FLEDIDET                           91
     C                   if        *in91 = '0'
     C                   MOVEL     *blanks       HLDPRT
     C                   MOVEL     *blanks       HLDPO
     C                   MOVEL     EDD004        HLDPRT
     C                   MOVEL     EDD003        HLDPO
     C     N1KEY         KLIST
     C                   KFLD                    HLDprt
     C                   KFLD                    HLDPO
     C*                  KFLD                    M23001
     C     N2KEY         KLIST
     C                   KFLD                    EDD004
     C                   KFLD                    HLDPO
      *
     C     N1key         setll     edm4123                            90
     C     N1key         reade     edm4123                                90
     C                   move      '0'           *in56             1
     C                   IF        *in90 = '1'
     C     N2key         setll     edm412301                          90
     C     N2key         reade     edm412301                              90
     C                   move      '1'           *in56             1
     C                   endif
      *
     C                   dow       *in90 = '0'
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
      *
     C                   IF        E23001 = 'BY'
     C                   MOVE      'BT '         V07001
     C                   else
     C                   MOVE      E23001        V07001
     C                   endif
      *
     C                   MOVEL     E23002        V07002
     C                   MOVEL     E23003        V07003
     C                   MOVEL     E23004        V07004
     C                   MOVEL     *blanks       V07017
      *                  -----     -------
     C                   IF        E23001 <> 'SU' and E23001 <> 'SF'
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             and E23001 = 'SU'
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             and E23001 = 'SU'
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C                             and E23001 = 'SU'
jc12 C                   IF        E23001 = 'SU'
jc12 C                   EVAL      f_SU_Sent = 'Y'
jc12 C                   elseif    E23001 = 'ST'
jc12 C                   EVAL      f_ST_Sent = 'Y'
jc12 C                   Endif
     C                   WRITE     FLINV07
     C                   endif
     C                   IF        *in56 = '0'
     C     N1key         reade     edm4123                                90
     C                   else
     C     N2key         reade     edm412301                              90
     C                   endif
      *
     C                   enddo
      *****************************************************************
     C                   IF        EDI026 = 1309 OR edi026 = 1962 or
     C                             EDI026 = 1472 or edi026 = 1490 or
     C                             edi026 = 1489 or edi026 = 1479 or
     C                             edi026 = 1480 or edi026 = 1486 or
     C                             edi026 = 1551
     C                   MOVE      'SU '         V07001
     C                   MOVEL     txt(5)        V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
     C     edi002        CHAIN     lfwpc202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSEif    MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   elseif    MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   elseif    MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   elseif    MOS005 = '6'
     C                   MOVEL     CMF093        V07004                        P
     C                   ENDIF
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   endif
      *****************************************************************
     C                   endif
jc12  * Ensure DTNA SU data sent
jc12 C                   IF        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12  * SU (supplier) sent?
jc12 C                   IF        f_SU_Sent = 'N'
jc12 C                   MOVE      *Blanks       V07001
jc12 C                   MOVE      ASN011        V07001
jc12 C                   MOVEL     ASN012        V07002
jc12 C                   MOVEL     ASN013        V07003
jc12 C                   MOVEL     ASN014        V07004
jc12 C                   IF        ASN014 = *Blanks
jc12 C     EDI002        CHAIN     lfwpc202                           25
jc12 C                   Z-ADD     EDI001        CUST4
jc12 C     CUST4         CHAIN     FLCUSMF                            25
jc12 C                   IF        MOS005 = '1'
jc12 C                             or MOS005 = *Blanks
jc12 C                   MOVEL     CMF074        V07004
jc12 C                   elseif    MOS005 = '2' OR MOS005 = '3'
jc12 C                   MOVEL     CMF075        V07004
jc12 C                   elseif    MOS005 = '4'
jc12 C                   MOVEL     CMF077        V07004
jc12 C                   elseif    MOS005 = '5'
jc12 C                   MOVEL     CMF092        V07004
jc12 C                   elseif    MOS005 = '6'
jc12 C                   MOVEL     CMF093        V07004                        P
jc12 C                   ENDIF
jc12 C                   ENDIF
jc12 C                   WRITE     FLINV07
jc12 C                   Endif
jc12  * ST (ship-to) sent?
jc12 C                   IF        f_ST_Sent = 'N'
jc12 C                   MOVE      ASN015        V07001
jc12 C                   MOVEL     ASN016        V07002
jc12 C                   MOVEL     ASN017        V07003
jc12 C                   MOVEL     ASN018        V07004
jc12 C                   IF        ASN018 = *Blanks
jc12 C     EDI002        CHAIN     lfwpc202                           25
jc12 C                   Z-ADD     EDI001        CUST4
jc12 C     CUST4         CHAIN     FLCUSMF                            25
jc12 C                   IF        MOS005 = '1'
jc12 C                             or MOS005 = *Blanks
jc12 C                   MOVEL     CMF074        V07004
jc12 C                   elseif    MOS005 = '2' OR MOS005 = '3'
jc12 C                   MOVEL     CMF075        V07004
jc12 C                   elseif    MOS005 = '4'
jc12 C                   MOVEL     CMF077        V07004
jc12 C                   elseif    MOS005 = '5'
jc12 C                   MOVEL     CMF092        V07004
jc12 C                   elseif    MOS005 = '6'
jc12 C                   MOVEL     CMF093        V07004                        P
jc12 C                   ENDIF
jc12 C                   ENDIF
jc12 C                   WRITE     FLINV07
jc12 C                   Endif
jc12 C                   Endif
     C                   endif
      ***** CAT********************************************************
      ***** CAT********************************************************
     C     EDI026        IFEQ      1500
     C     EDI026        orEQ      1583
jc07 C     EDI026        orEQ      2107
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'ST '         V07001
     C                   MOVEL     'CATERPILLAR' V07002
     C                   MOVE      '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     QUAL          V07004
     C                   IF        CMF001 = 1515 or
     C                             CMF001 = 1519 or
     C                             CMF001 = 1647
     C                   MOVEL     CMF086        V07004
     C                   ENDIF
     C                   MOVEL     TXT(26)       V07007
     C                   MOVEL     *BLANKS       V07008
     C                   MOVEL     TXT(27)       V07015
     C                   MOVEL     TXT(28)       V07016
     C                   MOVEL     TXT(29)       V07017
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'SE '         V07001
     C                   MOVEL     TXT(11)       V07002
     C                   MOVE      '92'          V07003
     C                   MOVEL     *blanks       V07004
      * Begin - SR431230 Change hard code to be what supplier number sales
      *                  order shows
     C*****              MOVEL     'B5692Y0'     V07004
     C     edi002        CHAIN     lfwpc202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSEif    MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   elseif    MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   elseif    MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   elseif    MOS005 = '6'
     C                   MOVEL     CMF093        V07004                        P
     C                   ENDIF
      * SR431230 - End
     C                   MOVEL     TXT(6)        V07007
     C                   MOVEL     TXT(7)        V07015
     C                   MOVEL     TXT(8)        V07016
     C                   MOVEL     TXT(9)        V07017
     C                   MOVEL     'US'          V07018
      *                  -----     -------
     C                   WRITE     FLINV07
      *set up qualifiers for CAT SF
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'SF '         V07001
     C                   MOVEL     TXT(1)        V07002
     C                   MOVEL     TXT(2)        V07015
     C                   MOVEL     TXT(3)        V07016
     C                   MOVEL     TXT(4)        V07017
     C                   MOVEL     '92'          V07003
     C                   MOVEL     *blanks       V07004
      * Begin - SR431230 Change hard code to be what supplier number sales
      *                  order shows
     C*****              MOVEL     'B5692Y0'     V07004
     C     edi002        CHAIN     lfwpc202                           25
     C                   IF        MOS005 = '1'
     C                   MOVEL     CMF074        V07004
     C                   ELSEif    MOS005 = '2' OR MOS005 = '3'
     C                   MOVEL     CMF075        V07004
     C                   elseif    MOS005 = '4'
     C                   MOVEL     CMF077        V07004
     C                   elseif    MOS005 = '5'
     C                   MOVEL     CMF092        V07004
     C                   elseif    MOS005 = '6'
     C                   MOVEL     CMF093        V07004                        P
     C                   ENDIF
      * SR431230 - End
     C                   WRITE     FLINV07
      *                  -----     -------
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *                  -----     -------
     C                   ENDIF
      ***********************************************
      * CAT belgium
     C     EDI026        IFEQ      1594
     C                   Z-ADD     1             Nline             3 0
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVEL     *blanks       V07001
     C                   MOVE      'ST '         V07001
     C                   MOVEL     TXT(10)       V07002
     C                   MOVE      '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     '25'          V07004
     C                   MOVEL     TXT(19)       V07007
     C                   MOVEL     TXT(20)       V07008
     C                   MOVEL     TXT(21)       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     TXT(22)       V07017
     C                   MOVEL     TXT(23)       V07018
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     * REF        UINV4108       ==================================*
     C     EDI026        IFEQ      1594
     C                   MOVEL     EDI002        V08100
     C                   MOVEL     EDI001        V08200
     C                   MOVEL     Bline         V08300
     C                   MOVEL     nline         V08400
     C                   MOVEL     *blanks       V08500
     C                   MOVE      '   '         V08001
     C                   MOVEL     *blanks       V08002
      *                  -----     -------
     C                   WRITE     FLINV08
     C                   endif
      *
     C                   add       1             Nline             3 0
     C                   MOVEL     bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVEL     *blanks       V07001
     C                   MOVE      'SE '         V07001
     C                   MOVEL     TXT(11)       V07002
     C                   MOVE      '92'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     'B5692Y0'     V07004
     C                   MOVEL     TXT(6)        V07007
     C                   MOVEL     TXT(7)        V07015
     C                   MOVEL     TXT(8)        V07016
     C                   MOVEL     TXT(9)        V07017
     C                   MOVEL     'US'          V07018
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C     EDI026        IFEQ      1594
     C                   MOVEL     EDI002        V08100
     C                   MOVEL     EDI001        V08200
     C                   MOVEL     bline         V08300
     C                   MOVEL     nline         V08400
     C                   MOVEL     *blanks       V08500
     C                   MOVE      '   '         V08001
     C                   MOVEL     *blanks       V08002
      *                  -----     -------
     C                   WRITE     FLINV08
     C                   endif
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   add       1             Nline             3 0
     C                   MOVEL     bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'BY '         V07001
     C                   MOVEL     TXT(12)       V07002
     C                   MOVEL     '92'          V07003
     C                   MOVEL     '25'          V07004
     C                   MOVEL     TXT(13)       V07007
     C                   MOVEL     TXT(14)       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     'CH-1211'     V07017
     C                   MOVEL     'CH'          V07018
      *                  -----     -------
     C                   WRITE     FLINV07
     * REF        UINV4108       ==================================*
     C     EDI026        IFEQ      1594
     C                   MOVEL     EDI002        V08100
     C                   MOVEL     EDI001        V08200
     C                   MOVEL     bline         V08300
     C                   MOVEL     nline         V08400
     C                   MOVEL     *blanks       V08500
     C                   MOVE      'VX '         V08001
     C                   MOVEL     TXT(15)       V08002
      *                  -----     -------
     C                   WRITE     FLINV08
     C                   endif
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   add       1             Nline             3 0
     C                   MOVEL     bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'IC '         V07001
     C                   MOVEL     TXT(16)       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     TXT(17)       V07007
     C                   MOVEL     TXT(20)       V07008
     C                   MOVEL     'GOSSELIES'   V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     'B-6041'      V07017
     C                   MOVEL     'BE'          V07018
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C     EDI026        IFEQ      1594
     C                   MOVEL     EDI002        V08100
     C                   MOVEL     EDI001        V08200
     C                   MOVEL     bline         V08300
     C                   MOVEL     nline         V08400
     C                   MOVEL     *blanks       V08500
     C                   MOVE      'VX '         V08001
     C                   MOVEL     TXT(18)       V08002
      *                  -----     -------
     C                   WRITE     FLINV08
     C                   endif
      *
     C                   ENDIF
      *
      * Bosch Rexroth or hypro or Danfoss
     C**** EDI026        IFEQ      8101
     C*****EDI026        OREQ      8104
     C     EDI026        IFEQ      2703
     C     EDI026        OREQ      5617
     C                   MOVE      EDI001        custhD            4 0
     C     custhd        CHAIN     ASNCUST                            25
     C     *in25         IFEQ      '0'
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVE      'II '         V07001
     C                   MOVEL     TXT(11)       V07002
     C                   MOVEL     '01'          V07003
     C                   MOVEL     txt(30)       V07004
     C                   MOVEL     TXT(2)        V07015
     C                   MOVEL     TXT(3)        V07016
     C                   MOVEL     TXT(4)        V07017
     C                   MOVEL     'US'          V07018
      * Begin - SR356610 Danfoss/Doosan
     C     EDI026        IFEQ      5617
     C                   MOVE      'RE '         V07001
     C                   MOVE      *BLANKS       V07004
     C                   MOVEL     TXT(38)       V07011
     C                   ENDIF
      * End   - SR356610
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *ST shipto
      * ACQUIRE SHIP TO ADDRESS
     C                   MOVEL     ASN015        V07001
     C                   MOVEL     ASN016        V07002
     C                   MOVEL     ASN017        V07003
     C                   MOVEL     ASN018        V07004
      *
      *ST shipto chain to custadress
      *
     C     ADRKEY        KLIST
     C                   KFLD                    cust#             4 0
     C                   KFLD                    ADRTYP            3 0
     C                   Z-ADD     2             ADRTYP
     C                   z-add     edi001        cust#
     C     ADRKEY        CHAIN     FLCUSTAD                           25
     C                   IF        *IN25 = '1'
     C                   Z-ADD     1             ADRTYP
     C     ADRKEY        CHAIN     FLCUSTAD                           25
     C                   END
     C                   MOVEL     cad006        V07015
     C                   MOVEL     cad007        V07016
     C                   MOVEL     CAD008        V07017
     C                   IF        CAD009 <>'  '
     C                   MOVEL     CAD009        V07018
     C                   else
     C                   MOVEL     'US'          V07018
     C                   END
      * Begin - SR356610 Danfoss/Doosan
     C     EDI026        IFEQ      5617
     C                   MOVE      *BLANKS       V07002
     C                   MOVE      *BLANKS       V07003
     C                   MOVE      *BLANKS       V07004
     C                   MOVEL     CAD003        V07002
     C     CAD005        IFEQ      *BLANKS
     C                   MOVEL     CAD004        V07011
     C                   ELSE
     C                   MOVEL     CAD005        V07011
     C                   ENDIF
     C                   ENDIF
      * End   - SR356610 Danfoss/Doosan
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   ENDIF
     C                   ENDIF
      * Begin - SR335992
      *** HMA   **************************************
     C     EDI026        IFEQ      2728
     C                   MOVEL     EDI002        V07100
     C                   MOVEL     EDI001        V07200
     C                   MOVEL     Bline         V07300
     C                   MOVEL     nline         V07400
     C                   MOVEL     *blanks       V07500
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
     C                   MOVE      'RS '         V07001
     C                   MOVEL     txt(11)       V07002
     C                   MOVEL     *blanks       V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *BLANKS       V07007
     C                   MOVEL     *BLANKS       V07008
     C                   MOVEL     TXT(38)       V07007
     C                   MOVEL     TXT(2)        V07015
     C                   MOVEL     TXT(3)        V07016
     C                   MOVEL     TXT(4)        V07017
     C                   MOVEL     *blanks       V07018
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'RI '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     TXT(5)        V07002
     C                   MOVEL     '91'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     TXT(30)       V07004                        P
     C                   MOVEL     *BLANKS       V07007
     C                   MOVEL     *BLANKS       V07008
     C                   MOVEL     TXT(6)        V07007
     C                   MOVEL     TXT(7)        V07015
     C                   MOVEL     TXT(8)        V07016
     C                   MOVEL     TXT(9)        V07017
     C                   MOVEL     *blanks       V07018
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
     C                   MOVE      'PR '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     TXT(31)       V07002
     C                   MOVEL     '91'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     TXT(32)       V07004                        P
     C                   MOVEL     *BLANKS       V07007
     C                   MOVEL     *BLANKS       V07008
     C                   MOVEL     TXT(33)       V07007
     C                   MOVEL     TXT(34)       V07015
     C                   MOVEL     TXT(35)       V07016
     C                   MOVEL     TXT(36)       V07017
     C                   MOVEL     *blanks       V07018
      *                  -----     -------
     C                   WRITE     FLINV07
      *
     C                   MOVEL     *blanks       V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     *blanks       V07007
     C                   MOVEL     *blanks       V07008
     C                   MOVEL     *blanks       V07015
     C                   MOVEL     *blanks       V07016
     C                   MOVEL     *blanks       V07017
     C                   MOVEL     *blanks       V07018
      *
      *
     C                   MOVE      'ST '         V07001
     C                   MOVEL     *blanks       V07002
     C                   MOVEL     '91'          V07003
     C                   MOVEL     *blanks       V07004
     C                   MOVEL     TXT(43)       V07004
      *                  -----     -------
     C                   WRITE     FLINV07
     C                   ENDIF
      ***************************************************
      * End   - SR335992

jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc04  * Bill to
jc04 C                   MOVEL     EDI002        V07100
jc04 C                   MOVEL     EDI001        V07200
jc04 C                   MOVEL     Bline         V07300
jc04 C                   MOVEL     nline         V07400
jc04 C                   MOVEL     *blanks       V07500
jc04 C                   MOVE      'BT '         V07001
jc04 C                   Z-ADD     2             CSTTYP            3 0
jc04 C     CSTKEY        CHAIN     CUSTADRS
jc04 C                   IF        NOT %FOUND(CUSTADRS)
jc04 C                   Z-ADD     1             CSTTYP
jc04 C     CSTKEY        CHAIN     CUSTADRS
jc04 C                   ENDIF
jc04 C                   MOVEL     EDD003        PO22
jc04 C     PO22          CHAIN     EDP07004
jc04 C                   MOVE      'BT '         IDCODE
jc04 C     BXPOID        CHAIN     EDP04002
jc04 C                   IF        %FOUND(EDP04002)
jc04 C                   MOVEL     E40003        V07003
jc04 C                   MOVEL     E40004        V07004
jc04 C                   ELSE
jc04 C                   MOVE      *Blanks       V07003
jc04 C                   MOVE      *Blanks       V07004
jc04 C                   ENDIF
jc04 C                   EVAL      v07002 = CAD003
jc04 C                   EVAL      v07007 = CAD004
jc04 C                   EVAL      v07008 = CAD005
jc04 C                   EVAL      v07015 = CAD006
jc04 C                   EVAL      v07016 = CAD007
jc04 C                   EVAL      v07017 = %trim(%char(CAD008))
jc04 C                   EVAL      v07018 = CAD009
jc04 C                   WRITE     FLINV07
jc04  * Remit to
jc04 C                   MOVEL     EDI002        V07100
jc04 C                   MOVEL     EDI001        V07200
jc04 C                   MOVEL     Bline         V07300
jc04 C                   MOVEL     nline         V07400
jc04 C                   MOVEL     *blanks       V07500
jc04 C                   MOVE      'RE '         V07001
jc04 C                   MOVEL     TXT(5)        V07002
jc04 C                   IF        ASN011 = 'IA'
jc04 C                   EVAL      V07003 = ASN013
jc04 C                   EVAL      V07004 = ASN014
jc04 C                   ELSE
jc04 C                   EVAL      V07003 = *Blanks
jc04 C                   EVAL      V07004 = *Blanks
jc04 C                   ENDIF
jc04 C                   MOVEL     TXT(6)        V07007
jc04 C                   MOVEL     TXT(7)        V07015
jc04 C                   MOVEL     TXT(8)        V07016
jc04 C                   MOVEL     TXT(9)        V07017
jc04 C                   WRITE     FLINV07
jc04 C                   ENDIF
     *==============================================================*
     * ITD    UINV4111            ==================================*
     *==============================================================*
     C*                  z-add     *zeros        nline
      *set up qualifiers?
     C     EDI026        IFEQ      1182
     C                   MOVEL     EDI002        V11100
     C                   MOVEL     EDI001        V11200
     C                   MOVEL     bline         V11300
     C                   MOVEL     nline         V11400
     C                   MOVEL     *blanks       V11500
      *
     C* 12-9-94: BECAUSE OF A CHANGE IN INVOICING POLICY THE DISCOUNT
     C* OF .5%/10 DAYS HAS BEEN DROPPED.  ALL INVOICES ARE NOW
     C* "NET 30 DAYS".  THEREFORE, ELEMENTS 'ITD03' & 'ITD05' ARE
     C* NO LONGER USED.  THE CODE IN 'ITD01' WAS CHANGED FROM '08'
     C* (BASIC DISCOUNT OFFERED) TO '05' (DISCOUNT NOT APPLICABLE).
     C* ELEMENT 'ITD07' (TERMS NET DAYS) WAS ADDED AND IS SET TO "30".
     C                   MOVE      '05'          V11001
     C                   MOVE      '3'           V11002
     C                   Z-ADD     30            V11007
      *                  -----     -------
     C                   WRITE     FLINV11
     C                   ENDIF
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc04 C                   MOVEL     EDI002        V11100
jc04 C                   MOVEL     EDI001        V11200
jc04 C                   MOVEL     bline         V11300
jc04 C                   MOVEL     nline         V11400
jc04 C                   MOVEL     *blanks       V11500
jc04 C                   MOVE      '14'          V11001
jc04 C                   MOVE      '3'           V11002
jc04 C                   Z-ADD     30            V11007
jc04 C                   WRITE     FLINV11
jc04 C                   ENDIF
      *set up qualifiers?
     C     EDI026        IFEQ      6325
     C     EDI026        OREQ      2728
     C     edi026        CHAIN     billto                             25
     C     BIL032        CHAIN     btcage                             25
      *
     C                   MOVEL     EDI002        V11100
     C                   MOVEL     EDI001        V11200
     C                   MOVEL     bline         V11300
     C                   MOVEL     nline         V11400
     C                   MOVEL     *blanks       V11500
     C*                  MOVE      '05'          V11001
     C*                  MOVE      '3'           V11002
     C                   IF        *in25 = '0'
     C                   movel     BTC002        V11012
     C                   else
     C                   movel     60            V11012
     C                   endif
      *                  -----     -------
     C                   WRITE     FLINV11
     C                   ENDIF
      * Begin - SR379129
      *   Baldor
      *set up qualifiers?
     C     EDI026        IFEQ      1205
     C     EDI026        CHAIN     billto                             25
     C     BIL032        CHAIN     btcage                             25
      *
     C                   MOVEL     EDI002        V11100
     C                   MOVEL     EDI001        V11200
     C                   MOVEL     bline         V11300
     C                   MOVEL     nline         V11400
     C                   MOVEL     *blanks       V11500
     C                   MOVE      '01'          V11001
     C                   MOVE      '3'           V11002
     C                   IF        *in25 = '0'
     C                   MOVEL     BTC002        V11012
     C                   ELSE
     C                   MOVEL     30            V11012
     C                   ENDIF
      *                  -----     -------
     C                   WRITE     FLINV11
     C                   ENDIF
      * End   - SR379129
     *==============================================================*
     * DTM        UINV4112       ==================================*
     *==============================================================*
     C                   MOVEL     EDI002        V12100
     C                   MOVEL     EDI001        V12200
     C                   If        EDI026 <> 2728
     C                   If        EDI026 = 1594
     C                   add       1             Nline             3 0
     C                   MOVEL     bline         V12300
     C                   MOVEL     Nline         V12400
     C                   MOVEL     '000'         V12500
     C                   Else
     C                   MOVEL     bline         V12300
     C                   MOVEL     Nline         V12400
     C                   MOVEL     '000'         V12500
     C                   ENDIF
     C                   MOVE      '011'         V12001
     C                   Z-ADD     DATE8         V12002
     C                   ADD       EDI016        V12002
      *                  -----     -------
      *
      * Not equal to NACCO write DTM
      *
     C                   IF        EDI026 <> 2704 and EDI026 <> 2706 and
     C                             EDI026 <> 2709 and EDI026 <> 2712 and
     C                             EDI026 <> 2783 and EDI026 <> 6802
jc04 C                             and EDI026 <> c_BobcatAry#01
jc04 C                             and EDI026 <> c_BobcatAry#02
jc04 C                             and EDI026 <> c_BobcatAry#03
     C                   WRITE     FLINV12
      * Begin - SR319862
     C                   ENDIF
     C                   ENDIF
      * Begin - SR335992
     C                   If        EDI026 = 2728
     C                   add       1             Nline             3 0
     C                   MOVEL     '000'         V12500
     C                   MOVEL     bline         V12300
     C                   MOVEL     Nline         V12400
     C                   MOVEL     '000'         V12500
      *shipdate
     C                   MOVE      '067'         V12001
     C                   Z-ADD     DATE8         V12002
     C                   ADD       EDI016        V12002
      *                  -----     -------
     C                   WRITE     FLINV12
      *
     C                   add       1             Nline             3 0
     C                   MOVEL     '000'         V12500
     C                   MOVEL     bline         V12300
     C                   MOVEL     Nline         V12400
     C                   MOVEL     '000'         V12500
      *invoice
     C                   MOVE      '999'         V12001
     C                   Z-ADD     DATE8         V12002
     C                   ADD       EDI018        V12002
      *                  -----     -------
     C                   WRITE     FLINV12
      *
     C                   add       1             Nline             3 0
     C                   MOVEL     '000'         V12500
     C                   MOVEL     bline         V12300
     C                   MOVEL     Nline         V12400
     C                   MOVEL     '000'         V12500
      *price date
     C                   MOVE      '814'         V12001
     C*                  EXSR      PODATSR
     C*                  z-add     podate        V12002
     C                   Z-ADD     DATE8         V12002
     C                   ADD       EDI016        V12002
      *                  -----     -------
     C                   WRITE     FLINV12
     C                   ENDIF
     *==============================================================*
      * FOB segment                                                ---
     *==============================================================*
      * End   - SR319862
     *==============================================================*
      * Total Invoice Amount                                       ---
     *==============================================================*
     C     EDI021        IFLT      0
     C                   Z-SUB     EDI021        EDI021
     C                   END
      /EJECT
     ****************************************************************
     **                                                            **
     **             DETAIL FILES                                   **
     **                                                            **
     ****************************************************************
      * SET LOWER LIMITS ON DETAIL FILE
      *=====================================
     C     EDI002        SETLL     FLEDIDET
     C                   z-add     *ZEROS        TOTSC
      *=====================================
      * SET LOWER LIMITS ON DUNNAGE FILE
      *=====================================
     C     EDI002        SETLL     FLEDIDUN
     C                   Z-ADD     0             LINE#             3 0
jc04 C                   MOVE      *Zeros        w_TotDetail      11 2
      *=====================================
      * READ EDIDETL FILE
      *=====================================
     C     REDETL        TAG
     C                   MOVE      '0'           *IN20
     C                   READ      FLEDIDET                               20
     C     *IN20         CABEQ     '1'           REDIDUN
     C     EDD001        CABNE     EDI002        REDIDUN
     C     EDD003        CABEQ     *BLANK        REDETL
     C     EDD012        CABEQ     'Y'           REDETL
     C     EDD013        CABEQ     'Y'           REDETL
      *--------------------------
      *  VALID RECORD
      *--------------------------
     C                   ADD       1             LINE#
      *==============================================================*
      * TOTAL UP SURCHARGE AMOUNTS TO BE OUTPUTED AS ONE ITA RECORD
      * AT THE END OF THE INVOICE.
      *---------------------------------------------------------------
     C     EDD010        IFNE      0
     C                   ADD       EDD010        TOTSC             7 2
     C                   END

jc03 C                   IF        EDI026 = 1500
jc03 C                             or EDI026 = 1583
jc07 C                             or EDI026 = 2107
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc03 C                   ADD       EDD024        TOTSC
jc03 C                   END
      * Begin - SR319862
     C                   IF        EDI026 = 6740 or
     C                             EDI026 = 2704 or
     C                             EDI026 = 2706 or EDI026 = 2709 or
     C                             EDI026 = 2712 or EDI026 = 2783 or
     C                             EDI026 = 6802 or EDI026 = 1205
jc04 C                             or EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
      * End   - SR319862
     C*****              IF        EDD024 <> *ZEROS
     C*****              ADD       EDD024        TOTSC             7 2
     C*****              END
     C                   IF        EDD026 <> *ZEROS
     C                   ADD       EDD026        TOTSC             7 2
     C                   END
     C                   END
      /EJECT
     *==============================================================*
     * IT1        UINV4131       ==================================*
     *==============================================================*
     C                   MOVEL     EDI002        V31100
     C                   MOVEL     EDI001        V31200
     C                   MOVEL     LINE#         V31300
     C                   MOVEL     *blanks       V31400
     C                   MOVEL     *blanks       V31500
     C                   MOVEL     *blanks       V31001
      *
     C                   IF        EDI001 = 1490 or EDI001 = 1959
     C                   MOVE      EDD002        V31001
     C                   endif
     C     EDI026        IFEQ      6325
     C                   MOVE      EDD023        V31001
     C                   endif

     C     EDI026        IFEQ      1962
     C     EDD023        IFne      *zeros
     C                   MOVE      *blanks       V31001
     C                   MOVE      EDD023        V31001
     C                   else
     C                   MOVE      *blanks       V31001
     C                   MOVE      EDD002        V31001
     C                   endif
     C                   endif
      *
     C                   IF        EDI026 = 1205
jc04 C                              or EDI026 = c_BobcatAry#01
jc04 C                              or EDI026 = c_BobcatAry#02
jc04 C                              or EDI026 = c_BobcatAry#03
     C                   MOVE      *BLANKS       V31001
     C                   IF        EDD023 = *ZERO
     C                   MOVEL     '001'         V31001
     C                   ELSE
     C                   MOVEL     EDD023        V31001
     C                   ENDIF
     C                   ENDIF
      *
     C                   MOVEL     EDD005        V31002
      * Begin - SR319862
     C*****              IF        EDI026 = 8101 or EDI026 = 8104 or
     C                   IF
     C                             EDI026 = 2728 or EDI026 = 1205 or
     C                             EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802 or
     C                             EDI026 = 5617
jc04 C                             or EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
      * End   - SR319862
     C                   MOVEL     'EA'          V31003
     C                   else
     C                   MOVEL     'PC'          V31003
     C                   endif
      * Unit Price --------------------------------------
     C                   MOVE      *BLANKS       V31004
      *
     C                   IF        EDI026 <> 1500
     C                             and EDI026 <> 1583
jc07 C                             and EDI026 <> 2107
     C     EDD009        add       EDD007        EDD007
      * Begin - 410859
      * For World Class Industry also add Energy Surchg to unit price
      * Do this for Danfoss and Baldor as well.
jc04  * And for bobcat
     C                   IF        EDI026 = 6740 OR
     C                             EDI026 = 5617 OR
     C                             EDI026 = 1205
jc04 C                             or EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc12 C                             or EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
     C     EDD025        ADD       EDD007        EDD007
     C                   ENDIF
      * End   - 410859
     C                   endif
     C                   MOVE      EDD007        DECML3            3
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDD007        WHOLE5            5
     C                   MOVE      DECML3        DECML8            8
     C                   MOVEL     WHOLE5        DECML8
     C                   MOVEL     DECML8        V31004
      * Begin - SR319862
     C                   IF        EDI026 <> 1500
     C                             and EDI026 <> 1583
jc07 C                             and EDI026 <> 2107
     C                              and EDI026 <> 2704 and
     C                             EDI026 <> 2706 and EDI026 <> 2709 and
     C                             EDI026 <> 2712 and EDI026 <> 2783 and
     C                             EDI026 <> 6802 and EDI026 <> 2728 and
     C                             EDI026 <> 1205
jc04 C                             and EDI026 <> c_BobcatAry#01
jc04 C                             and EDI026 <> c_BobcatAry#02
jc04 C                             and EDI026 <> c_BobcatAry#03
      * End   - SR319862
     C                   MOVE      'PE'          V31005
     C                   endif
      * P.O. Number--------------------------------------
     C     EDI026        IFeq      1486
     C     EDI026        oreq      1489
     C     EDI026        oreq      1472
     C     EDI026        oreq      1551
     C     EDI026        oreq      1962
     C                   MOVE      *BLANK        V31008
     C                   MOVE      *BLANK        V31009
     C                   ELSE
     C                   MOVE      'PO'          V31008
     C                   MOVEL     EDD003        V31009
     C                   END
     C**** EDI026        IFeq      8101
     C*****EDI026        oreq      8104
     C****               MOVE      'PL'          V31010
     C****               MOVEL     EDD023        V31011
     C****               END
      * Part Number--------------------------------------
     C                   MOVEL     EDD003        POHFLD            2
     C                   IF        POHFLD = '45'
     C                   MOVE      'PL'          V31006
     C                   ELSE
     C                   MOVE      'BP'          V31006
     C                   ENDIF
      * Begin - SR319862
     C*****              IF        EDI026 = 8101 or EDI026 = 8104 or
     C                   IF
     C                             EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802 or
     C                             EDI026 = 2728 or EDI026 = 1205 or
     C                             EDI026 = 5617
      * End   - SR319862
     C                   MOVE      'BP'          V31006
     C                   ENDIF
      *
     C                   IF        EDI026 <> 1725 AND
     C                             EDI026 <> 1205
     C                   IF        POHFLD = '45'
     C                   IF        EDD023 <> *zeros
     C                   MOVEL     00000         poline            5 0
     C                   MOVE      EDD023        poline
     C                   MOVE      poline        V31001
     C                   ELSE
     C                   MOVEL     00010         V31001
     C                   ENDIF
     C                   endif
     C                   endif
      *
     C     EDI026        IFNE      2728
     C     EDI026        IFEQ      1500
     C     EDI026        orEQ      1583
jc07 C     EDI026        orEQ      2107
     C                   IF        EDD023 <> *zeros
     C                   MOVEL     *blanks       V31001
     C                   MOVEL     EDD023        V31001
     C                   MOVEL     *blanks       V31300
     C                   MOVEL     EDD023        V31300
     C                   ELSE
     C                   MOVEL     '001'         V31300
     C                   ENDIF
     C                   endif
     C                   endif

     C                   EXSR      GETPRT#

     C                   MOVEL     PARTNO        V31007
      *
      * Begin - SR319862
      * NACCO get original PO Line#
     C                   IF        EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802
     C     POPART        KLIST
     C                   KFLD                    PO22
     C                   KFLD                    PRT40

     C                   MOVE      *BLANKS       PRT40            40
     C                   MOVE      *BLANKS       PO22             22
     C                   MOVEL     EDD004        PRT40
     C                   MOVEL     EDD003        PO22
     C                   MOVEL     '1'           V31001
     C                   MOVEL     '1'           V31013
      *
     C     POPART        CHAIN     EDP07004
     C                   IF        %FOUND(EDP07004) AND
     C                             E70001 <> *BLANKS
     C                   MOVEL     E70001        V31001
     C                   ENDIF
      *
     C                   MOVE      'VP'          V31008
     C                   MOVEL     EDD004        V31009
     C                   MOVE      'PO'          V31010
     C                   MOVEL     EDD003        V31011
     C                   MOVE      'PL'          V31012
     C                   MOVEL     V31001        V31013
     C                   ELSE
     C                   MOVE      *BLANKS       V31010
     C                   MOVE      *BLANKS       V31011
jc08 C                   MOVE      *BLANKS       V31012
jc08 C                   MOVE      *BLANKS       V31013
     C                   ENDIF
      * End   - SR319862

jc02aC                   IF        EDI026 = c_KohlerAry#
jc02aC                   IF        V31001 = *Blanks
jc02aC                              or V31001 = '000'
jc02aC                              or V31001 = '                 000'
jc02aC                   EVAL      V31001 = '010'
jc02aC                   EVAL      V31012 = 'PL'
jc02aC                   EVAL      V31013 = '10'
jc02aC                   ENDIF
jc02aC                   ENDIF


      * Begin - SR379129
      *   Baldor PO Line ALSO Danfoss/Doosan
     C     EDI026        IFEQ      1205
     C     EDI026        oreq      4479
     C     EDI026        oreq      5617
     C                   MOVE      'VP'          V31008
     C                   MOVEL     EDD004        V31009
      *
     C                   END
      * End   - SR379129
jc12 C                   If        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C                   EVAL      V31008 = 'PO'
jc12 C                   EVAL      V31009 = EDD003
jc12 C                   If        EDD023 > *Zeros
jc12 C                   EVAL      V31010 = 'PL'
jc12 C                   EVAL      V31011 = %char(EDD023)
jc12 C                   Endif
jc12 C                   ENDIF
jc12 C                   EVAL      V31012 = 'PD'
jc12 C                   EVAL      V31013 = PDS003
jc12 C     Key_4123      KList
jc12 C                   KFld                    E23200
jc12 C                   KFld                    E23100
jc12
jc12 C                   IF        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C                   EVAL      V31010 = 'PL'
jc12 C****               EVAL      V31011 = '001'
jc12 C                   Add       +1            w_Line#           3 0
jc12 C                   EVAL      E23200 = EDD004
jc12 C                   EVAL      E23100 = EDD003
jc12 C     Key_4123      CHAIN     EDM4123
jc12 C                   IF        %Found(EDM4123)
jc12 C                   EVAL      V31011 = E23300
jc12 C                   ELSE
jc12 C                   MOVEL     W_Line#       V31011
jc12 C                   Endif
jc13 C                   if        %len(%trim(E23100)) > 6
jc13 C                   EVAL      w_POLen = %len(%trim(E23100)) - 3
jc13 C                   EVAL      w_POLineStart = w_POLen + 1
jc13 C                   EVAL      V31009 = %subst(E23100:1:w_POLen)
jc13 C                   EVAL      V31011 = %subst(E23100:w_POLineStart:3)
jc13 C                   Else
jc13 C                   EVAL      V31009 = E23100
jc13 C                   EVAL      V31011 = '001'
jc13 C                   Endif
jc12 C                   ENDIF
      *                  -----     -------
     C                   WRITE     FLINV31
      *                  -----     -------
jc04 C                   EVAL      w_TotDetail = w_TotDetail
jc04 C                              + (EDD007 * EDD005)
     *==============================================================*
     * PID        UINV4138       ==================================*
     *==============================================================*
      *
     C                   IF        EDI026 = 5617
     C                   MOVE      *BLANK        PDS003
     C     EDD004        CHAIN     FLPARTFI                           25
     C     PTF016        CHAIN     PRTDSC01                           25
     C                   MOVEL     EDI002        V38100
     C                   MOVEL     EDI001        V38200
     C                   MOVEL     LINE#         V38300
     C                   MOVEL     *blanks       V38400
     C                   MOVEL     *blanks       V38500
     C                   MOVEL     'F'           A38001
     C                   MOVEL     PDS003        A38005
     C                   WRITE     FLINV38
     C                   ENDIF
      *
     *==============================================================*
     * CTP        uinv4136       ==================================*
     *==============================================================*
     C     EDI026        IFEQ      6325
     C                   MOVEL     EDI002        V36100
     C                   MOVEL     EDI001        V36200
     C                   MOVEL     LINE#         V36300
     C                   MOVEL     *blanks       V36400
     C                   MOVEL     *blanks       V36500
     C                   MOVEL     *blanks       V36001
     C                   MOVEL     'ICL'         V36002
     C                   MOVEL     V31004        V36003
     C                   MOVEL     '0000000001'  V36009
     C                   WRITE     FLINV36
     C                   ENDIF
     C                   MOVE      *BLANKS       V31002
     C                   MOVE      *BLANKS       V31006
     C                   MOVE      *BLANKS       V31007
     C                   MOVE      *BLANKS       V31008
     C                   MOVE      *BLANKS       V31009
     C                   MOVE      *BLANKS       V31004
      *                  -------------------------------
      *
     C**** EDI026        IFeq      8101
     C     'Customer'    IFeq      'Bosch'
     C*****EDI026        oreq      8104
     C     TOTSC         IFNE      0
     *==============================================================*
     * REF        UINV4144       ==================================*
     *==============================================================*
      * Begin - SR319862  Not NACCO
     C                   IF        EDI026 <> 2704 and EDI026 <> 2706 and
     C                             EDI026 <> 2709 and EDI026 <> 2712 and
     C                             EDI026 <> 2783 and EDI026 <> 6802 and
     C                             EDI026 <> 5617
jc12 C                             and EDI026 <> c_DTNAFtlMfg01
jc12 C                             and EDI026 <> c_DTNAFtlMfg02
jc12 C                             and EDI026 <> c_DTNAFtlMfg03
      * End   - SR319862
     C                   Z-ADD     0             TOTDUN
     C                   MOVEL     EDI002        V44100
     C                   MOVE      EDI001        V44200
     C                   MOVEL     LINE#         V44300
     C                   MOVEL     *blanks       V44400
     C                   MOVEL     *blanks       V44500
     C                   MOVEL     *blanks       V44001
     C                   MOVEL     *blanks       V44002
     C                   MOVE      'PK '         V44001
     C                   MOVEL     EDI017        V44002
      *                  -----     -------
     C                   WRITE     FLINV44
      *                  -----     -------
      * Begin - SR319862
     C                   ENDIF
      * End   - SR319862
     *==============================================================*
     * SAC        UINV4144       ==================================*
     *==============================================================*
     C                   IF        EDI026 <> 2704 and EDI026 <> 2706 and
     C                             EDI026 <> 2709 and EDI026 <> 2712 and
     C                             EDI026 <> 2783 and EDI026 <> 6802 and
     C                             EDI026 <> 5617
     C                   z-add     *zeros        surline           8 2
     C                   If        edd026 <> *zeros
     C     edd010        add       edd026        surline
     C                   endif
     C                   END
     C                   END
     C                   END
      *
      * Begin - IR421351 Danfoss Energy Surcharge
      *
     C*****              IF        EDI026 = 5617 and
     C*****                        EDD026 <> *ZERO
     C*****              ADD       EDD026        SURLINE
     C*****              MOVEL     EDI002        V52100
     C*****              MOVEL     EDI001        V52200
     C*****              MOVEL     LINE#         V52300
     C*****              MOVEL     *blanks       V52400
     C*****              MOVEL     *blanks       V52500
     C*****              MOVEL     'C'           V52001
     C*****              MOVEL     'D240'        V52002
     C*****              MOVE      SURLINE       V52005
     C*****              MOVEL     'SURCHARGE'   V52015
      *****              -----     -------
     C*****              WRITE     FLINV52
      *****              -----     -------
     C*****              ENDIF
      *
      * End   - IR421351
      *
     C                   GOTO      REDETL
      /EJECT
      **============================================================**
      ** DUNNAGE FILE       EDIDUNN                                 **
      **============================================================**
     C     REDIDUN       TAG
     C     EDI026        IFne      1486
     C     EDI026        andne     1489
     C     EDI026        andne     1472
     C     EDI026        andne     1551
     C     EDI026        andne     1962
     C     EDI026        andne     1594
     C     EDI026        andne     1500
     C     EDI026        andne     1583
jc07 C     EDI026        andne     2107
     C     EDI026        andne     2728
     C     EDI026        andne     1205
     C     EDI026        andne     5617
     C                   Z-ADD     0             TOTDUN            7 2
     C                   MOVE      '0'           *IN20
      *
     C                   READ      FLEDIDUN                               20
     C     *IN20         CABEQ     '1'           EREDIDUN
     C     EDG001        CABNE     EDI002        EREDIDUN
     C     EDG008        CABEQ     0             REDIDUN
      *
     C     EDI026        IFEQ      1486
     C     EDI026        orEQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C                   MOVEL     'PC'          V31003
     C                   ELSE
     C                   MOVEL     'EA'          V31003
     C                   endif
     C                   MOVE      *BLANKS       V31004
      * Begin - SR357129 - Add Line# to Dunnage that displays for Baldor
      *
     C**** EDI026        IFEQ      1205
     C****               ADD       1             LINE#
     C****               Z-ADD     LINE#         LINE#2            5 0
     C****               MOVE      *BLANKS       V31001
     C****               MOVEL     LINE#2        V31001
     C****               ENDIF
      * End   - SR357129
     C                   MOVEL     EDG005        V31002
     C                   MOVE      EDG007        DECML3            3
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDG007        WHOLE3            3
     C                   MOVE      DECML3        DECML6            6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        V31004
      *
     C                   MOVE      *BLANKS       V31010
     C                   MOVE      *BLANKS       V31011
      /EJECT
      *=====================================================:
      *                                                     |
      *------------  DUNNAGE DESCRIPTIONS  -----------------|
      *                                                     |
      *=====================================================:
     C     DUNKEY        KLIST
     C                   KFLD                    CUST4
     C                   KFLD                    EDG003
      *
     C                   MOVE      *BLANKS       V31005
     C                   MOVE      *BLANKS       V31006
     C                   MOVE      *BLANKS       V31007
     C                   MOVE      *BLANKS       V31008
     C                   MOVE      *BLANKS       V31009
      *
      * Begin - SR319862  Not BOSCH or NACCO
     C*****EDI026        IFne      8101
     C*****EDI026        andne     8104
     C*****              IF        EDI026 <> 8101 and EDI026 <> 8104 and
     C                   IF
     C                             EDI026 <> 2704 and EDI026 <> 2706 and
     C                             EDI026 <> 2709 and EDI026 <> 2712 and
     C                             EDI026 <> 2783 and EDI026 <> 6802 and
     C                             EDI026 <> 1205 and EDI026 <> 5716
jc04 C                             and EDI026 <> c_BobcatAry#01
jc04 C                             and EDI026 <> c_BobcatAry#02
jc04 C                             and EDI026 <> c_BobcatAry#03
jc12 C                             and EDI026 <> c_DTNAFtlMfg01
jc12 C                             and EDI026 <> c_DTNAFtlMfg02
jc12 C                             and EDI026 <> c_DTNAFtlMfg03
      * End   - SR319862
     C     DUNKEY        CHAIN     FLDUNIVC                           80
     C     *IN80         IFEQ      *OFF
     C     EDI026        IFEQ      1486
     C     EDI026        orEQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C                   MOVE      'PE'          V31005
     C                   MOVEL     'BP'          V31006
     C                   ELSE
     C                   MOVEL     'RC'          V31006
     C                   END
     C                   MOVEL     DNV006        V31007
     C                   ELSE
     C     DUNKEY        CHAIN     FLDUNUSA                           80
     C     *IN80         IFEQ      *OFF
     C     EDI026        IFEQ      1486
     C     EDI026        orEQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C                   MOVE      'PE'          V31005
     C                   MOVEL     'BP'          V31006
     C                   ELSE
     C                   MOVEL     'RC'          V31006
     C                   END
     C                   MOVEL     DNU010        V31007
     C                   END
     C                   END
      *                  -----     -------
     C                   WRITE     FLINV31
      *                  -----     -------
     C                   MOVE      *BLANKS       V31006
     C                   MOVE      *BLANKS       V31007
     C                   MOVE      *BLANKS       V31008
     C                   MOVE      *BLANKS       V31009
      *                  -----     -------
     C                   GOTO      REDIDUN
      *                  -----     -------
     C     EREDIDUN      TAG
     C                   endif
     C                   endif
      /EJECT
     *==============================================================*
     *==============================================================*
     * PID        uinv4138       ==================================*
     *==============================================================*
     C     EDI026        IFEQ      1500
     C     EDI026        orEQ      1583
jc07 C     EDI026        orEQ      2107
     C     EDI026        orEQ      1205
     C                   MOVE      *BLANK        PDS003
     C     EDD004        CHAIN     FLPARTFI                           25
     C     PTF016        CHAIN     PRTDSC01                           25
     C                   MOVEL     EDI002        V38100
     C                   MOVEL     EDI001        V38200
     C                   MOVEL     LINE#         V38300
     C                   MOVEL     *blanks       V38400
     C                   MOVEL     *blanks       V38500
     C                   MOVEL     'F'           A38001
     C                   MOVEL     PDS003        A38005
     C                   WRITE     FLINV38
     C                   ENDIF
     *==============================================================*
     * REF        UINV4144       ==================================*
     *==============================================================*
      * Begin - SR319862
     C*****              IF        EDI026 <> 8101 and EDI026 <> 8104 and
     C                   IF
     C                             EDI026 <> 2704 and EDI026 <> 2706 and
     C                             EDI026 <> 2709 and EDI026 <> 2712 and
     C                             EDI026 <> 2783 and EDI026 <> 6802 and
     C                             EDI026 <> 2728 and EDI026 <> 1205
jc12 C                             and EDI026 <> c_DTNAFtlMfg01
jc12 C                             and EDI026 <> c_DTNAFtlMfg02
jc12 C                             and EDI026 <> c_DTNAFtlMfg03
      * End   - SR319862
     C                   Z-ADD     0             TOTDUN
     C                   MOVEL     EDI002        V44100
     C                   MOVE      EDI001        V44200
     C                   MOVEL     LINE#         V44300
     C                   MOVEL     *blanks       V44400
     C                   MOVEL     *blanks       V44500
     C                   MOVEL     *blanks       V44001
     C                   MOVEL     *blanks       V44002
     C     EDI026        IFEQ      1594
     C                   MOVE      'BM '         V44001
     C                   ELSE
     C                   MOVE      'PK '         V44001
     C                   ENDIF
     C     EDI026        IFEQ      1962
     C                   MOVE      'SI '         V44001
     C                   ENDIF
     C                   MOVEL     EDI017        V44002
      *                  -----     -------
     C                   WRITE     FLINV44
      *                  -----     -------
     c                   endif
     *==============================================================*
     * SAC        UINV4152       ==================================*
     *==============================================================*
      **============================================================**
      ** DUNNAGE FILE       EDIDUNN                                 **
      **============================================================**
     C     EDI002        SETLL     FLEDIDUN
     C     REDIDUN3      TAG
     C     EDI026        IFEQ      1486
     C     EDI026        orEQ      1489
     C     EDI026        OREQ      1472
     C     EDI026        OREQ      1551
     C     EDI026        OREQ      1962
     C                   Z-ADD     0             TOTDUN            7 2
     C                   MOVE      '0'           *IN20
      *
     C                   READ      FLEDIDUN                               20
     C     *IN20         CABEQ     '1'           eREDIDUN3
     C     EDG001        CABNE     EDI002        EREDIDUN3
     C     EDG008        CABEQ     0             REDIDUN3
      *
     C                   MOVEL     EDI002        V52100
     C                   MOVEL     EDI001        V52200
     C                   MOVEL     LINE#         V52300
     C                   MOVEL     *blanks       V52400
     C                   MOVEL     *blanks       V52500
     C                   MOVEL     'C'           V52001
     C                   MOVEL     'F150'        V52002
     C                   MOVE      *BLANKS       V52005
     C                   MOVE      EDG008        V52005
     C                   MOVE      '2'           V52006
     C                   MOVE      '06'          V52012
     C     EDG008        IFne      0
     C                   WRITE     FLINV52
     C                   endif
      *                  -----     -------
     C                   MOVE      *BLANKS       V75001
     C                   MOVE      *BLANKS       V75002
     C                   MOVE      *BLANKS       V75005
     C                   MOVE      *BLANKS       V75006
     C                   MOVE      *BLANKS       V75012
      *                  -----     -------
     C                   GOTO      REDIDUN3
      *                  -----     -------
     C                   endif
     C     Eredidun3     TAG
      *
     *==============================================================*
     * SAC        UINV4175       ==================================*
     *==============================================================*
     C                   Z-ADD     0             TOTDUN
     C     EDI026        IFNE      6740
     C     EDI026        andne     1811
     C**** EDI026        andne     8101
     C*****EDI026        andne     8104
     C     EDI026        andne     1205
     C     EDI026        andne     2704
     C     EDI026        andne     2706
     C     EDI026        andne     2709
     C     EDI026        andne     2712
     C     EDI026        andne     2783
     C     EDI026        andne     6802
jc04 C**###EDI026        andne     c_BobcatAry#01
jc04 C**###EDI026        andne     c_BobcatAry#02
jc04 C**###EDI026        andne     c_BobcatAry#03
     C     TOTSC         IFNE      0
jc12 C                   IF        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C                   MOVEL     EDI002        V52100
jc12 C                   MOVEL     EDI001        V52200
jc12 C                   MOVEL     LINE#         V52300
jc12 C                   MOVEL     *blanks       V52400
jc12 C                   MOVEL     *blanks       V52500
jc12 C                   MOVEL     'C'           V52001
jc12 C                   MOVEL     'H550'        V52002
jc12 C                   MOVE      TOTSC         V52005
jc12 C                   WRITE     FLINV52
jc12 C                   Else
     C                   MOVEL     EDI002        V75100
     C                   MOVEL     EDI001        V75200
     C                   MOVEL     LINE#         V75300
     C                   MOVEL     *blanks       V75400
     C                   MOVEL     *blanks       V75500
     C                   MOVEL     'C'           V75001
     C                   MOVEL     'H550'        V75002
     C                   MOVE      TOTSC         V75005
      *                  -----     -------
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             or EDI026 = c_BobcatAry#03
jc04 C                   EVAL      V75005 = EDI021 - w_TotDetail
jc04 C                   ENDIF
jc04  * Suppress SAC if amount is zero
jc04 C                   IF        EDI026 = c_BobcatAry#01
jc04 C                             And V75005 = *Zeros
jc04 C                             or EDI026 = c_BobcatAry#02
jc04 C                             And V75005 = *Zeros
jc04 C                             or EDI026 = c_BobcatAry#03
jc04 C                             And V75005 = *Zeros
jc04 C                   ELSE
     C                   WRITE     FLINV75
jc04 C                   ENDIF
jc12 C                   Endif
      *                  -----     -------
     C                   z-add     *ZEROS        TOTSC
     C                   END
     C                   END
jc12  * Write dunnage info out for DTNA in SAC level before TDS
jc12 C                   IF        EDI026 = c_DTNAFtlMfg01
jc12 C                             or EDI026 = c_DTNAFtlMfg02
jc12 C                             or EDI026 = c_DTNAFtlMfg03
jc12 C                   MOVE      '0'           *IN20
jc12 C     EDI002        SETLL     FLEDIDUN
jc12 C     edi002        READE     FLEDIDUN                               20
jc12 C                   Z-ADD     0             TOTDUN            7 2
jc12 C     *in20         doweq     '0'
jc12 C                   add       EDG008        totdun
jc12 C     edi002        READE     FLEDIDUN                               20
jc12 c                   ENDDO
jc12  *
jc12 C     TOTdun        IFNE      0
jc12 C                   MOVEL     EDI002        V52100
jc12 C                   MOVEL     EDI001        V52200
jc12 C                   MOVEL     LINE#         V52300
jc12 C                   MOVEL     *blanks       V52400
jc12 C                   MOVEL     *blanks       V52500
jc12 C                   MOVEL     'C'           V52001
jc12 C                   MOVEL     'R060'        V52002
jc12 C                   MOVE      TOTDUN        V52005
jc12 C                   WRITE     FLINV52
jc12 C                   Endif
jc12 C                   EVAL      TOTDUN = *Zeros
jc12 C                   Endif
      ****************************************************************
      **** 5/20/2016 - discussed dunnage not on invoice with Kathy   *
      *   Verified that customer bosch rexroth does not want dunnage *
      *   on invoice only total invoice (include dunnage) and display*
      *   pricing for parts and surcharge only.  Their system will   *
      *   do the rest.                                               *
      ****************************************************************
      * Begin - SR319862
     C*****              IF        EDI026 = 8101 or EDI026 = 8104 or
     C                   IF
     C                             EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802 or
     C                             EDI026 = 1205
      * End   - SR319862
     C                   MOVE      '0'           *IN20
     C     EDI002        SETLL     FLEDIDUN
     C     edi002        READE     FLEDIDUN                               20
     C                   Z-ADD     0             TOTDUN            7 2
     C     *in20         doweq     '0'
     C                   add       EDG008        totdun
     C     edi002        READE     FLEDIDUN                               20
     c                   ENDDO
      *
     C     TOTdun        IFNE      0
      *
      * Begin - SR319862
      * Add Packaging to SAC file to upload for NACCO requirements
      *
     C                   IF        EDI026 = 2704 or EDI026 = 2706 or
     C                             EDI026 = 2709 or EDI026 = 2712 or
     C                             EDI026 = 2783 or EDI026 = 6802 or
     C                             EDI026 = 1205
     C                   MOVEL     EDI002        V75100
     C                   MOVEL     EDI001        V75200
     C                   MOVEL     LINE#         V75300
     C                   MOVEL     *blanks       V75400
     C                   MOVEL     *blanks       V75500
     C                   MOVEL     'C'           V75001
     C                   MOVEL     'R060'        V75002
     C                   MOVE      TOTDUN        V75005
      *                  -----     -------
      * Begin - SR379129
     C                   IF        EDI026 = 1205
     C                   MOVEL     'D015'        V75002
     C                   MOVEL     'EX'          V75003
     C                   MOVEL     'ZZ'          V75004
     C                   MOVEL     '06'          V75012
     C                   MOVEL     'DUNNAGE'     V75015
     C                   ENDIF
      * End   - SR379129
      *                  -----     -------
     C                   WRITE     FLINV75
      *                  -----     -------
     C                   END
      * End   - SR319862
      * Begin - SR379129
     C                   MOVEL     *BLANKS       V75004
     C                   MOVEL     *BLANKS       V75003
     C                   MOVEL     *BLANKS       V75012
     C                   MOVEL     *BLANKS       V75015
      * End   - SR379129
     C                   z-add     *ZEROS        TOTdun
     C                   END
     C                   END
      *
     *==============================================================*
     * CAD        UINV4177       ==================================*
     *==============================================================*
     C     EDI026        IFEQ      1594
     C                   MOVEL     EDI002        V77100
     C                   MOVEL     EDI001        V77200
     C                   MOVEL     LINE#         V77300
     C                   MOVEL     *blanks       V77400
     C                   MOVEL     *blanks       V77500
     C                   MOVEL     'T'           V77001
     C                   MOVEL     *blanks       V77002
     C                   MOVEL     *blanks       V77003
     C                   MOVEL     *blanks       V77004
     C*                  MOVE      *blanks       V77005
     C                   MOVE      'Z'           V77005
      *                  -----     -------
     C                   WRITE     FLINV77
      *                  -----     -------
     C                   END
      /EJECT
     *==============================================================*
     * ITA        UINV4178               ==========================*
     *==============================================================*
      ** DUNNAGE FILE       EDIDUNN                                 **
     C     EDI026        IFEQ      1500
     C     EDI026        orEQ      1583
jc07 C     EDI026        orEQ      2107
     C*    EDI026        orEQ      8101
     C*    EDI026        orEQ      8104
     C     EDI002        SETLL     FLEDIDUN
     C                   MOVE      '0'           *IN20
     C     TOP02         TAG
     C     EDI002        READE     FLEDIDUN                               20
     C     *IN20         CABEQ     '1'           END02
     C     EDG001        CABNE     EDI002        END02
     C     EDG008        CABEQ     0             TOP02
     C                   MOVEL     EDI002        V78100
     C                   MOVEL     EDI001        V78200
     C                   MOVEL     LINE#         V78300
jc11 C                   IF        EDI026 = 2107
jc10 C     EDI002        Chain     FLEDIDET                           25
jc10 C                   IF        EDD023 <> *zeros
jc10 C                   MOVEL     *blanks       V78300
jc10 C                   MOVEL     EDD023        V78300
jc10 C                   ELSE
jc10 C                   MOVEL     '001'         V78300
jc10 C                   ENDIF
jc11 C                   ENDIF
     C                   MOVEL     *blanks       V78400
     C                   MOVEL     *blanks       V78500
      *
     C                   MOVE      'C'           V78001
     C                   MOVE      *BLANKS       V78002
     C                   MOVEL     'AX'          V78002
     C                   MOVE      *BLANKS       V78003
     C                   MOVE      *BLANKS       V78004
     C     EDI026        IFEQ      1500
     C     EDI026        orEQ      1583
kh01dC*****EDI026        orEQ      2107
     C                   MOVEL     'S0050'       V78003
     C                   else
kh01aC     EDI026        IFEQ      2107
kh01aC                   MOVEL     'FS'          V78003
kh01aC                   else
     C                   MOVEL     'PN'          V78003
kh01aC                   endif
     C                   endif
     C                   MOVE      '06'          V78004
      *
     C                   MOVE      *blanks       Unitpc
     C                   MOVE      *blanks       v78006
     C                   MOVE      *blanks       Huprc
      *
     C                   MOVE      EDG007        Unitpc
     C                   MOVE      upri          hprc
     C                   MOVEL     '.'           HDEC
     C                   MOVE      ucnt          Hcnt
     C                   MOVE      Huprc         V78006
      *
     C                   MOVE      *blanks       v78007
     C                   MOVE      *blanks       v78010
     C                   MOVE      *blanks       v78011
     C                   MOVE      *blanks       v78012
     C                   MOVE      *blanks       v78013
     C*                  Z-ADD     EDG008        V78007
jc10 C                   IF        EDI026 = 2107
jc10 C                   Z-ADD     EDG008        V78007
jc10 C                   ELSE
jc10 C                   Move      *zeros        V78007
jc10 C                   ENDIF
     C                   MOVE      EDG005        V78010
     C                   MOVE      'PC'          V78011
     C                   MOVEL     EDG003        WORK30           30
     C                   MOVE      EDG004        WORK30
     C                   MOVEL     WORK30        WORK55           55
     C     EDG009        IFEQ      'Y'
     C                   MOVEL     txt(24)       V78013
     C                   ELSE
     C                   MOVEL     txt(25)       V78013
     C                   END
     C                   MOVE      WORK55        V78012
     C                   WRITE     FLINV78
     C                   GOTO      TOP02
     C     END02         TAG
     C                   endif
     *==============================================================*
     * TDS        UINV4171       ==================================*
     *==============================================================*
     C                   MOVEL     EDI002        V71100
     C                   MOVEL     EDI001        V71200
     C                   If        EDI026 = 1594 or EDI026 = 1962
     C                   z-add     999           Nline             3 0
     C                   If        EDI026 = 1962
     C                   z-add     LINE#         Bline             3 0
     C                   endif
     C                   MOVEL     bline         V71300
     C                   MOVEL     Nline         V71400
     C                   MOVEL     *blanks       V71500
     C                   Else
     C                   MOVEL     LINE#         V71300
     C                   MOVEL     *blanks       V71400
     C                   MOVEL     *blanks       V71500
     C                   ENDIF
     C                   MOVE      EDI021        V71001
     C                   z-add     *zeros        V71002
     C                   z-add     *zeros        V71003
     C                   z-add     *zeros        V71004
      *                  -----     -------
     C                   WRITE     FLINV71
      *                  -----     -------
      /EJECT
      /EJECT
     *==============================================================*
     * End reading EDIDETL FILE  ==================================*
     *==============================================================*
     C     ERDETL        TAG
      **============================================================**
      *
      * CODE EDIMSTR (TRANSMITTED DATE) WITH TODAY'S DATE
      *
      **============================================================**
     C                   TIME                    DATTIM           12 0
     C                   MOVE      DATTIM        EDI019
     C                   MULT      10000.01      EDI019
     C                   UPDATE    FLEDIMST
      *----------------------------------------------------
     C                   ADD       1             REC#
      *
     C     BYPASS        TAG
      /EJECT
      **============================================================**
      *
      * LR TIME - MOVE COUNTER INTO PROPER ALPHA FIELD TO SUPRESS ZEROS
      *
      **============================================================**
     CLR   REC#          IFGT      99
     CLR                 MOVE      REC#          INREC
     CLR                 ELSE
     CLR   REC#          IFGT      9
     CLR                 MOVE      REC#          WRK2              2
     CLR                 MOVE      WRK2          INREC
     CLR                 ELSE
     CLR                 MOVE      REC#          WRK1              1
     CLR                 MOVE      WRK1          INREC
     CLR                 END
     CLR                 END
      /EJECT
      ****************************************************************
      ***                                                          ***
      ****       S U B R O U T I N E   SECTION                    ****
      ***                                                          ***
      **============================================================**
      ** SR - SETS A SWITCH TO DETERMINE WHERE THE PO #'S SHOULD GO **
      **============================================================**
     C     PONUMB        BEGSR
      *--------------------------------------------------------------*
      * IF THERE IS ONLY ONE P/O NUMBER FOR THE INVOICE PUT IT
      * THE HEADER AREA.  IF SEVERAL P/O NUMBERS ARE PRESENT IN
      * THE DETAIL RECORDS PUT THEM IN THE LINE ITEMS.
      *--------------------------------------------------------------*
     C     EDI002        SETLL     FLEDIDET
     C                   Z-ADD     0             COUNT             3 0
     C                   MOVE      '0'           *IN50
     C     TOPS1         TAG
     C                   MOVE      '0'           *IN20
     C                   READ      FLEDIDET                               20
     C     *IN20         CABEQ     '1'           ENDS1
     C     EDD001        CABNE     EDI002        ENDS1
     C     EDD003        CABEQ     *BLANK        TOPS1
     C                   ADD       1             COUNT
     C     COUNT         IFEQ      1
     C                   MOVEL     EDD003        HOLDPO           12
     C                   END
     C     EDD003        IFNE      HOLDPO
     C                   MOVE      '1'           *IN50
     C                   END
     C                   GOTO      TOPS1
     C     ENDS1         ENDSR
      /EJECT
      **============================================================**
      ** SR - determines date                                       **
      **============================================================**
     C     PODATSR       BEGSR
      *--------------------------------------------------------------*
      * Pull PO date from moldords/ordmvment of when it hit our system.
      *--------------------------------------------------------------*
      *  Need to be able to look up invoice/ps/part number combo.
     C     EDI002        chain     FLEDIDET                           25
     C     *in25         IFeq      '0'
     C                   MOVEL     EDD003        HPO              20
     C     EDd004        chain     ivcpar01                           25
     C     *in25         IFeq      '0'
     C                   MOVEL     IVC001        Hpart            15
     C                   Else
     C                   MOVEL     EDD004        Hpart
     C                   END
      *
     C     podtky        KLIST
     C                   KFLD                    IVP015
     C                   KFLD                    hpart
     C     edi017        Chain     ivcprth                            26
     C     podtky        Chain     MOLDOR10                           25
     C     *in25         IFeq      '1'
     C     podtky        Chain     ordmvmnt                           25
     C                   END
     C     *in25         IFeq      '0'
     C                   MOVE      MOL093        pmo
     C                   MOVE      MOL094        pday
     C                   MOVE      MOL095        pyear
      * Begin - SR379129
     C                   Else
     C                   MOVE      *month        pmo
     C                   MOVE      *day          pday
     C                   MOVE      *year         pyear
      * End   - SR379129
     C                   END
     C                   Else
     C                   MOVE      *month        pmo
     C                   MOVE      *day          pday
     C                   MOVE      *year         pyear
     C                   END
     C     ENDpod        ENDSR
      /EJECT
     C     CKNUMERIC     BEGSR
     C                   CLEAR                   NUMERIC           1
     C                   RESET                   POS
     C                   CLEAR                   X
     C                   DOW       X<LENGTH AND POS=0
     C                   ADD       1             X
     C                   EVAL      POS=%CHECK(DIGITS:ARRNUM(X))
     C                   ENDDO
      *ALL DIGITS
     C                   IF        POS=0
     C                   EVAL      NUMERIC='Y'
     C                   ENDIF
      *
     C                   ENDSR
      * Begin - #2892
      **************************************************************
      * GETPRT# - Subroutine to Acquire Part Number to Print
      **************************************************************
     C     GETPRT#       BEGSR

      * Key by Part and PO

     C     RLSKEY        KLIST
     C                   KFLD                    EDD004
     C                   KFLD                    EDD003

      * Key by Part and Customer

     C     RLSKY3        KLIST
     C                   KFLD                    EDD004
     C                   KFLD                    CUST4

     C                   MOVEL     *BLANKS       PARTNO

      * Chain to Cross Ref file by Part and PO. If found and Invoice
      * & PO <> blank & Customer matchs (IVC011) or (IVC011) is zero &
      * Invoice field equals 'Y' move Customer's Part(IVC002) into Part

     C                   EVAL      FOUND = 'N'
     C     RLSKEY        CHAIN     IVCPARTS
     C                   IF        %FOUND(IVCPARTS) AND
     C                             IVC010 <> *BLANKS AND
     C                             IVC011 = CUST4 AND
     C                             IVC003 = 'Y' OR
     C                             %FOUND(IVCPARTS) AND
     C                             IVC010 <> *BLANKS AND
     C                             IVC011 = *ZEROS AND
     C                             IVC003 = 'Y'
     C                   EVAL      FOUND = 'Y'
     C                   MOVEL     IVC002        PARTNO

      * If not found above, chain to IVCPAR03 file by Part/Cust. If PO
      * (IVC010) not equal to blank make sure it matches with the input PO.
      * If found and Invoice field equals 'Y' move Customer's Part(IVC002)
      * into Part Number

     C                   ELSEIF    FOUND = 'N'
     C     RLSKY3        SETLL     IVCPAR03
     C     RLSKY3        READE     IVCPAR03
     C                   DOW       %FOUND(IVCPAR03) AND
     C                             NOT %EOF(IVCPAR03)
     C                   IF        IVC010 = EDD003 AND
     C                             IVC003 = 'Y' OR
     C                             IVC010 = *BLANKS AND
     C                             IVC003 = 'Y'
     C                   EVAL      FOUND = 'Y'
     C                   MOVEL     IVC002        PARTNO
     C                   LEAVE
     C                   ENDIF
     C     RLSKY3        READE     IVCPAR03
     C                   ENDDO

     C                   ENDIF

      * ELSE loop through IVCPARTS file by WAREHOUS Part Number(EDD004)
      * If found and Invoice field equals 'Y' and PO and Cust equal zero
      * move Customer's Part(IVC002) into Part Number, leave when found

     C                   IF        FOUND = 'N'
     C     EDD004        SETLL     IVCPARTS
     C     EDD004        READE     IVCPARTS
     C                   DOW       %FOUND(IVCPARTS) AND
     C                             NOT %EOF(IVCPARTS)
     C                   IF        IVC003 = 'Y' AND
     C                             IVC011 = *ZEROS AND
     C                             IVC010 = *BLANKS
     C                   EVAL      FOUND = 'Y'
     C                   MOVEL     IVC002        PARTNO
     C                   LEAVE
     C                   ENDIF
     C     EDD004        READE     IVCPARTS
     C                   ENDDO

     C                   ENDIF

      * If Part Number is still blank then move Warehouse Part Number
      * into Part Number field

     C                   IF        PARTNO = *BLANKS
     C                   MOVEL     EDD004        PARTNO
     C                   ENDIF

      * CHECK FOR LARGER PART#
      * Loop though file for part that is not blank in the 'Cust Part#
      * To Print' field and PO either blank or matchs with inputted PO
      * Or Cust either zero or matchs with inputted Cust#

     C     EDD004        SETLL     IVCPARTS
     C     EDD004        READE     IVCPARTS
     C                   DOW       %FOUND(IVCPARTS) AND
     C                             NOT %EOF(IVCPARTS)
     C                   IF        IVC015 <> *BLANKS AND
     C                             IVC016 = 'Y'
     C                   IF        IVC011 = CUST4 AND
     C                             IVC010 = EDD003 OR
     C                             IVC011 = *ZEROS AND
     C                             IVC010 = *BLANKS OR
     C                             IVC011 = CUST4 AND
     C                             IVC010 = *BLANKS OR
     C                             IVC011 = *ZEROS AND
     C                             IVC010 = EDD003
     C                   MOVEL     IVC015        PARTNO
     C                   LEAVE
     C                   ENDIF
     C                   ENDIF
     C     EDD004        READE     IVCPARTS
     C                   ENDDO

     C                   ENDSR
      * End   - #2892
      *****************************************************************
      **
jc12  *===============================================================
jc12  * GetPlant Subroutine - Picks up to 3 plants that part can be
jc12  *                       produced at from PRTPLT file
jc12  *                       Code copied from EDI009
jc12  *===============================================================
jc12 C     GETPLANT      BEGSR
jc12
jc12 C**   SUPOKEY       KLIST
jc12  **                 KFLD                    SUPLR#
jc12 C**                 KFLD                    PART#
jc12
jc12 C                   EVAL      PART#    = *BLANKS
jc12 C**                 EVAL      SUPLR#   = *BLANKS
jc12 C                   EVAL      PLANT##  = *ZEROS
jc12 C                   EVAL      PLANT##2 = *ZEROS
jc12 C                   EVAL      PLANT##3 = *ZEROS
jc12 C                   EVAL      *IN95    = *OFF
jc12 C                   EVAL      *IN96    = *OFF
jc12 C                   EVAL      WRKPRT35 = *BLANKS
jc12
jc12 C                   MOVEL     EDD004        PART#            15
jc12 C                   MOVEL     EDD004        WRKPRT35         35
jc12 C**                 MOVEL     M23002        SUPLR#           10
jc12  *
jc12  * Check 15 alpha character Part#
jc12  *
jc12 C     PART#         CHAIN     IVCPAR01
jc12 C                   IF        %FOUND(IVCPAR01)
jc12 C                   MOVEL     IVC001        PART#
jc12 C                   ELSE
jc12  *
jc12  * Check 35 alpha character Part#
jc12  *
jc12 C     WRKPRT35      CHAIN     IVCPAR05
jc12 C                   IF        %FOUND(IVCPAR05)
jc12 C                   MOVEL     L_IVC001      PART#
jc12 C                   ENDIF
jc12 C                   ENDIF
jc12
jc12 C                   IF        PART# = *BLANK
jc12 C                   MOVEL     PARTNO        PART#
jc12 C                   ENDIF
jc12  *
jc12 C**   SUPOKEY       CHAIN     SUPLOVR
jc12 C**                 IF        %FOUND(SUPLOVR) and
jc12 C**                           NOT %EOF(SUPLOVR)
jc12 C**                 Z-ADD     SUPL03        PLANT##           2 0
jc12 C**                 ELSE
jc12 C     PART#         SETLL     PRTPLT03
jc12 C     PART#         READE     PRTPLT03
jc12 C                   IF        %FOUND(PRTPLT03) and
jc12 C                             NOT %EOF(PRTPLT03)
jc12 C                   MOVE      PRP002        PLANT##           2 0
jc12 C     PART#         READE     PRTPLT03
jc12 C                   IF        %FOUND(PRTPLT03) and
jc12 C                             NOT %EOF(PRTPLT03)
jc12 C                   MOVE      PRP002        PLANT##2          2 0
jc12 C                   EVAL      *IN95    = *ON
jc12 C     PART#         READE     PRTPLT03
jc12 C                   IF        %FOUND(PRTPLT03) and
jc12 C                             NOT %EOF(PRTPLT03)
jc12 C                   MOVE      PRP002        PLANT##3          2 0
jc12 C                   EVAL      *IN96    = *ON
jc12 C                   ENDIF
jc12 C                   ENDIF
jc12 C                   ENDIF
jc12 C**                 ENDIF
jc12 C                   ENDSR


jc12  *===============================================================
jc12  * GetPartner  Subroutine - Determines partner id for DTNA.
jc12  *===============================================================
jc12 C     sr_GetPartner BEGSR
jc12 C     Key_SUPLOVR   KList
jc12 C                   KFLD                    SUPL02
jc12 C                   KFLD                    SUPL03
jc12 C                   KFLD                    SUPL04
jc12 C                   EVAL      SUPL02 = PART#
jc12 C                   EVAL      SUPL03 = PLANT##
jc12 C                   EVAL      SUPL04 = EDI001
jc12 C     Key_SuplOvr   CHAIN     SUPLOL01
jc12 C                   IF        %Found(SUPLOL01)
jc12 C                   EVAL      w_PartnerId = 'DTNA ' + SUPL01
jc12 C                   Else
jc12 C                   Eval      w_PartnerId = 'DTNA LJ94'                    Default
jc12 C                   Endif
jc12 C     *LIKE         DEFINE    V01000        w_PartnerId
jc12 C                   EndSr
      *==============================================================*
**
WAUPACA FOUNDRY, INC.                            1   SHIP FROM ADDRESS
WAUPACA                                          2
WI                                               3
549810000                                        4
WAUPACA FOUNDRY, INC.                            5   REMIT TO ADDRESS
29223 NETWORK PLACE                              6
CHICAGO                                          7
IL                                               8
606731292                                        9
CATERPILLAR BELGIUM SA                          10
WAUPACA FOUNDRY INC                             11
CATERPILLAR SARL                                12
ROUTE DE FONTENEX 76                            13
GENEVA                                          14
BE0466550796                                    15
CATERPILLAR GROUP SERVICES SA                   16
AVENUE DES ETATS UNIS 1                         17
BE0428189078                                    18
AV DES ETATS UNIS 1                             19
BP1                                             20
GOSSELIES                                       21
B-6041                                          22
BE                                              23
RETURNABLE DUNNAGE                              24
NON RETURNABLE DUNNAGE                          25
100 NE ADAMS STREET AH9401                      26
PEORIA                                          27
IL                                              28
61629                                           29
006133441                                       30
HITACHI METALS AMERICA  LTD                     31
S0100                                           32
2 MANHATTANVILLE ROAD, SUITE 301                33
PURCHASE                                        34
NY                                              35
10577                                           36
HITACHI METALS AUTOMOTIVE COMPONENT             37
1955 BRUNNER DRIVE                              38
                                                39
                                                40
                                                41
0001000116                                      42
0002102007                                      43
PD82730020                                      44
PD86852601                                      45
PD82917601                                      46
PD82717603                                      47
