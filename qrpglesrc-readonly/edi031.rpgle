      ****
      ** AUTHOR ----- BARB HAASE                               **
      **                                                           **
      **  DATE  -----  JUNE   2004                            **
      **                                                          **
      **  DESC  ----- EDI031 CREATE DESADV EDI INVOICE         **
      ****
      **               Modification History Index               **
      **                                                          **
      **REQ BY  | DATE |WHO|JOB|CHANGE DESCRIPTION       **
      **internal |09/10/07| BJH | --- | added NAD segment         **
      **internal |01/16/08| BJH | --- | added customer            **
      **Billie c |06/21/10| BJH | --- | chg cummins 1688 ID       **
      **Cummins  |08/15/11| BJH |1112 | meet new cummins requirements
      **Cummins  |09/26/11| BJH |---- | Changed 1688 to direct to    
      **         |        |     |     |  other ID.                **
      **Cummins  |10/11/11| BJH |---- | correct ALC detail for       
      **         |        |     |     |  amortization & paint cost **
      **Barb O.  |04/11/16| BJH |SR   | added eng surg fields to   **
      **         |        |     323577|  ivcprt and edidetl        **
      **Darrell O|03/21/17| KMH |SR   | Add ZF Gainesville to      **
      **         |        |     249958|  INVOIC Doc                **
      **Barb O.  |07/22/17| KMH |IR   | Made changes to above code **
      **         |        |     477621|  so that CUMMINS would pro **
      **         |        |     |     |  cess correctly after chg.**
jc01a **Kathy H. |12/21/18| JC  |SR   | Made changes to allow for  **
jc01a **         |        |     379169| Volvo (Mack) invoicing.    **
jc01a **         |        |           | Supplier array +9475.      **
      **                                                          **
      **        Function Keys & important indicator usage       **
      **      *IN01 THRU *IN24 = RESERVED FOR FUNCTION KEYS     **
      ** *IN25  -  Validate Chains and Reads                      **
      ****
      **               Logical File Reference                   **
      **Logical |Physical|Path                                **
      ****
      **                                                          **
      ****************************************************************
     FEDIMSTR   UP   E             DISK
     FEDFASN    IF   E           K DISK
     FEDIDETL   IF   E           K DISK
     FEDIDUNN   IF   E           K DISK
     FEDIDTA    IF   E           K DISK
     Fivchdrh   IF   E           K DISK
     FEDINOTES  IF   E           K DISK
     FIVCPAR01  IF   E           K DISK
     FU97BIN01  O    E             DISK
     FU97BIN02  O    E             DISK
     FU97BIN11  O    E             DISK
     FU97BIN19  O    E             DISK
     FU07AIN192 O    E             DISK
     FU97BIN31  O    E             DISK
     FU97BIN91  O    E             DISK
     FU97BIN93  O    E             DISK
     FU97BIN95  O    E             DISK
     FU07AIN24  O    E             DISK
     FU97BIN98  O    E             DISK
     FU97BIN106 O    E             DISK
     FU97BIN112 O    E             DISK
     FU07AIN193 O    E             DISK
     FU07AIN25  O    E             DISK
     FU97BIN176 O    E             DISK
     FU97BIN183 O    E             DISK
     FU97BIN189 O    E             DISK
     FU97BIN191 O    E             DISK
     FEDIDATE   UF   E             DISK
     FCUSMF     IF   E           K DISK
     FDUNNAGE   IF   E           K DISK
     FDUNUSAGE  IF   E           K DISK
     FPARTFILE  IF   E           K DISK
     FPRTDSC01  IF   E           K DISK
      *
     D TXT             S             35    DIM(10) CTDATA PERRCD(1)             text info
      *
     D TOTPRC          S                   LIKE(EDD008)
     D EAPRC           S                   LIKE(EDD008)
     D TGROSS          S                   LIKE(EDD008)
      *
     D HPRICE          DS
     D  HPRI                   1      5  0
     D  HDEC                   7      8  0
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
      *
     C                   MOVE      'A'           I01001
     C                   MOVE      'INVOIC'      I01002
     C                   MOVE      'D'           I01003
jc01aC                   IF        EDI026 = +9475
jc01aC                   ELSE
     C                   MOVE      '97B'         I01004
jc01aC                   ENDIF
     C                   MOVE      'UN'          I01005
      *
     C                   TIME                    DATE             12 0
     C                   MOVE      *BLANKS       DATHLD            6 0
     C                   MOVE      DATE          DATHLD            6 0
     C                   MULT      10000.01      DATHLD
      *
     C                   Z-ADD     0             REC#              3 0
      *
     C                   MOVE      'PC'          I91003
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
      **     1 - THIS IS NOT A DESADV INV. CUSTOMER(USE ARRAY NO.)  **
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
     *==============================================================*
     * Customer Number      ========================================*
     *==============================================================*
     C                   Z-ADD     EDI001        CUST4             4 0
     C                   MOVEL     *blanks       I00000
     *==============================================================*
     * CUMMINS engine              =================================*
     *==============================================================*
     C     EDI001        IFEQ      1674                                         Recvr Id
     C     EDI001        orEQ      1650                                         Recvr Id
     C     EDI001        orEQ      1681                                         Recvr Id
     C     EDI001        orEQ      1677                                         Recvr Id
     C     EDI001        orEQ      1688                                         Recvr Id
     C                   MOVEL     '006415160'   I00000
     C                   MOVE      'A'           I01001
     C                   MOVE      'INVOIC'      I01002
     C                   MOVE      'D'           I01003
     C                   MOVE      '97B'         I01004
     C                   MOVE      'UN'          I01005
     C                   MOVE      *BLANKS       I01006
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * CUMMINS engine             =================================*
     *==============================================================*
     C     EDI001        IFEQ      1680                                         Recvr Id
     C                   MOVEL     '081535635'   I00000
     C                   MOVE      'A'           I01001
     C                   MOVE      'INVOIC'      I01002
     C                   MOVE      'D'           I01003
     C                   MOVE      '97B'         I01004
     C                   MOVE      'UN'          I01005
     C                   MOVE      *BLANKS       I01006
     C                   GOTO      CHECK2
     C                   END
     *==============================================================*
     * ZF Gainesville Array - SR249958   ==========================*
     *==============================================================*
     C                   IF        EDI026 = 7005                                Recvr Id
     C                   MOVEL     'AG-FLT1  '   I00000
     C                   MOVE      'A'           I01001
     C                   MOVE      'INVOIC'      I01002
     C                   MOVE      'D'           I01003
     C                   MOVE      '07A'         I01004
     C                   MOVE      'UN'          I01005
     C                   MOVE      'GAVA11'      I01006
     C                   GOTO      CHECK2
     C                   END

jc01a*==============================================================*
jc01a* Volvo                  SR379169   ==========================*
jc01a*==============================================================*
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVEL     'VOLVO 4285'  I00000                         Recvr Id
jc01aC                   MOVE      'A'           I01001                         Recvr Id
jc01aC                   MOVE      'INVOIC'      I01002                         Recvr Id
jc01aC                   MOVE      'D'           I01003                         Recvr Id
jc01aC                   MOVE      '03A'         I01004                         Recvr Id
jc01aC                   MOVE      'UN'          I01005                         Recvr Id
jc01aC                   MOVE      *Blanks       I01006                         Recvr Id
jc01aC                   MOVEL     'C'           I01007                         Recvr Id
jc01aC                   MOVEL     'F'           I01008                         Recvr Id
jc01aC                   GOTO      CHECK2                                       Recvr Id
jc01aC                   END                                                    Recvr Id

     *==============================================================*
     * For the Rest           ======================================*
     *==============================================================*
     C                   GOTO      BYPASS
      /EJECT
     *==============================================================*
     * Select Invoice Record  ======================================*
     *==============================================================*
     C     CHECK2        TAG
      *
     C     EDI019        CABNE     0             BYPASS                         TRANSMITTED DATE
      *
     C     EDI017        CABLE     19999         BYPASS                         PACKING SLIP #
     C     EDI017        IFGE      50000
     C     EDI017        CABLE     79999         BYPASS
     C                   END
      *
     C                   MOVE      *BLANK        CMF066                         EDI INVOICING FLAG
     C     CUST4         CHAIN     FLCUSMF                            20
     C     CMF066        CABEQ     *BLANK        BYPASS                         CHECK 4
     C     CMF066        CABEQ     'N'           BYPASS                         CHECK 4
      *==========================================================
      * GET DATA FROM EDIDETL FILE
      *==========================================================
     C     EDI002        SETLL     FLEDIDET                                     INVOICE NUMBER
     C                   Z-ADD     0             DETLIN            3 0
      **============================================================**
      ** READ EDIDETL FILE -                                        **
      **============================================================**
     C     TOP04         TAG
     C     edi002        READE     FLEDIDET                               20
     C     *IN20         CABEQ     '1'           END04
     C     EDD001        CABNE     EDI002        END04                          INVOICE NUMBER
     C     EDD004        CABEQ     *BLANK        TOP04                          PART NUMBER
     C     EDD005        CABEQ     0             TOP04                          QUANTITY
     C     EDD007        CABEQ     0             TOP04                          UNIT PRICE
     C     EDD012        CABEQ     'Y'           TOP04                          NO-CHARGE FLAG
     C     EDD013        CABEQ     'Y'           TOP04                          PRICE LATER FLAG
     C                   ADD       1             DETLIN
     C                   GOTO      TOP04
     C     END04         TAG
     C     DETLIN        CABEQ     0             BYPASS
      /EJECT
     *==============================================================*
     * BGM      U97BIN01          ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I01000                                      R
     C                   MOVE      'A'           I01100
     C                   Z-ADD     01            I01200
      *
      * document type (380 = invoice)
     C                   MOVEL     380           I01010                                      R
     C                   MOVEL     EDI002        I01014                         invoice number
      * Msg function (9= original)
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVE      '03A'         I01004
jc01aC                   MOVE      EDI021        DECML3
jc01aC                   MOVEL     '.'           DECML3
jc01aC                   MOVEL     EDI021        WHOLE3
jc01aC                   MOVE      DECML3        DECML6
jc01aC                   MOVEL     WHOLE3        DECML6
jc01aC                   MOVEL     DECML6        I01020
jc01aC                   ELSE
     C                   MOVEL     9             I01017                                      R
jc01aC                   ENDIF
      *
     C                   WRITE     FLIN#01
     *==============================================================*
     * DTM        U97BIN02        ==================================*
     *==============================================================*
      * Begin - SR249958
     C                   IF        EDI026 = 7005                                Recvr Id
jc01aC                              or EDI026 = +9475                           Recvr Id
      * packing slip, recID and # - First DTM for ZF
     C                   MOVEL     EDI017        I02000                                      R
     C                   MOVE      'A'           I02100
     C                   Z-ADD     02            I02200
      *
     C                   MOVE      '137'         I02001                         CUST #
      *
     C                   MOVE      DATE8         I02002                         INVOICE NUMBER
     C                   MOVE      EDI018        I02002                         INVOICE NUMBER
      *
     C                   MOVEL     '102'         I02003                         INVOICE NUMBER
      *                  -----     -------
     C                   WRITE     FLIN#02
      *
      * packing slip, recID and # - Second DTM for ZF
     C                   MOVEL     EDI017        I02000                                      R
     C                   MOVE      'A'           I02100
     C                   Z-ADD     02            I02200
      *
     C                   MOVE      '  1'         I02001                         CUST #
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVE      '158'         I02001                         CUST #
jc01aC                   ENDIF
      *
     C                   MOVE      DATE8         I02002                         INVOICE NUMBER
     C                   MOVE      EDI018        I02002                         INVOICE NUMBER
      *
     C                   MOVEL     '102'         I02003                         INVOICE NUMBER
      *                  -----     -------
     C                   WRITE     FLIN#02
      *
jc01aC                   IF        EDI026 = +9475                               Recvr Id
jc01aC                   MOVEL     EDI017        I02000                                      R
jc01aC                   MOVE      'A'           I02100
jc01aC                   Z-ADD     02            I02200
jc01aC                   MOVE      '159'         I02001                         CUST #
jc01aC                   MOVE      DATE8         I02002                         INVOICE NUMBER
jc01aC                   MOVE      EDI018        I02002                         INVOICE NUMBER
jc01aC                   MOVEL     '102'         I02003                         INVOICE NUMBER
jc01aC                   WRITE     FLIN#02
jc01aC                   ENDIF
     C                   ELSE
      *
      * packing slip, recID and #
     C                   MOVEL     EDI017        I02000                                      R
     C                   MOVE      'A'           I02100
     C                   Z-ADD     02            I02200
      *
     C                   MOVE      '  3'         I02001                         CUST #
      *
     C                   MOVE      DATE8         I02002                         INVOICE NUMBER
     C                   MOVE      EDI018        I02002                         INVOICE NUMBER
      *
     C                   MOVEL     '102'         I02003                         INVOICE NUMBER
      *                  -----     -------
     C                   WRITE     FLIN#02
     C                   ENDIF
     *==============================================================*
     * RFF        U97BIN11       ==================================*
     *==============================================================*
     C                   IF        EDI026 <> 7005
      * Purchase Order ID
     C                   MOVEL     EDI017        I11000                                      R
     C                   MOVE      'A'           I11100
     C                   Z-ADD     11            I11200
      *---------------------------------------------------------------
      * Determine Purchase Order Number                            ---
      *---------------------------------------------------------------
     C                   EXSR      PONUMB
     C     *IN50         IFEQ      '0'                                          1st TIME
     C                   MOVEL     HOLDPO        I11002                         ONLY
     C                   END
     C                   MOVE      'ON '         I11001
      *                  -----     -------
     C                   WRITE     FLIN#11
      *---------------------------------------------------------------
      * packing slip #
     C                   MOVEL     EDI017        I11000                                      R
     C                   MOVE      'A'           I11100
     C                   Z-ADD     11            I11200
     C                   MOVE      'SI '         I11001
     C                   MOVEL     *blanks       I11002
     C                   MOVEL     EDI017        I11002
     C                   WRITE     FLIN#11
     C                   ELSE
      *---------------------------------------------------------------
      * ZF Invoice # SR249958
      * Invoice #
     C                   MOVEL     EDI017        I11000                                      R
     C                   MOVE      'A'           I11100
     C                   Z-ADD     11            I11200
     C                   MOVE      'IV '         I11001
     C                   MOVEL     *blanks       I11002
     C                   MOVEL     EDI002        I11002
     C                   WRITE     FLIN#11
     C                   ENDIF
     *==============================================================*
     * NAD        U97BIN19        ==================================*
     *==============================================================*
      * Invoice #
     C                   MOVE      EDI001        CUSN              4 0                       R
     C     CUSN          CHAIN     FLEDFASN                                     INVOICE NUMBER
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDA021        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'IV'          I19001
     C                   MOVE      EDA022        I19002
     C                   MOVE      EDA023        I19004
     C                   MOVE      EDA024        I19005
      *                  -----     -------
     C                   WRITE     FLIN#19
      *
      *---------------------------------------------------------------
      * ZF - NAD Segment for BY - SR249958
      * packing slip, recID and #
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'BY'          I19001
     C                   MOVE      EDA030        I19002
     C                   MOVE      EDA031        I19004
     C                   MOVE      EDA032        I19005
      *                  -----     -------
     C                   WRITE     FLIN#19
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *
     C                   IF        EDI026 = 7005
      * ZF RFF following NAD Segment
     C                   MOVEL     EDI017        I192000                                     R
     C                   MOVE      'A'           I192100
     C                   Z-ADD     19            I192200
     C                   MOVE      'VA '         I192001
     C                   MOVEL     *blanks       I192002
     C                   MOVEL     '1111'        I192002
     C                   WRITE     FLIN#192
      *---------------------------------------------------------------
      * ZF - NAD Segment for IV - SR249958
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'IV'          I19001
     C                   MOVE      EDA030        I19002
     C                   MOVE      EDA031        I19004
     C                   MOVE      EDA032        I19005
     C                   MOVE      EDA034        I19006
      *                  -----     -------
     C                   WRITE     FLIN#19
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *---------------------------------------------------------------
      * Ship-From for ZF - SR249958
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'SF'          I19001
     C                   MOVE      EDA022        I19002
     C                   MOVE      EDA023        I19004
     C                   MOVE      EDA024        I19005
     C                   MOVE      *BLANKS       I19006
      *                  -----     -------
     C                   WRITE     FLIN#19
      *
     C                   ENDIF
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *---------------------------------------------------------------
      *
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'SE'          I19001
      *
     C     EDA022        IFEQ      *BLANK
     C     EDI026        OREQ      7005
     C     EDI017        CHAIN     IVCHDRH                                      INVOICE NUMBER
      *
     C     IVH018        IFEQ      1
     C                   MOVEL     CMF074        I19002                         PLANT1
     C                   ELSE
     C     IVH018        IFEQ      2
     C                   MOVEL     CMF075        I19002                         PLANT1
     C                   ELSE
     C     IVH018        IFEQ      3
     C                   MOVEL     CMF076        I19002                         PLANT1
     C                   ELSE
     C     IVH018        IFEQ      4
     C                   MOVEL     CMF077        I19002                         PLANT1
     C                   ELSE
     C     IVH018        IFEQ      5
     C                   MOVEL     CMF092        I19002                         PLANT1
     C                   ELSE
     C     IVH018        IFEQ      6
     C                   MOVEL     CMF093        I19002                         PLANT1
     C                   END                                                   MARIINETTE
     C                   END                                                   MARIINETTE
     C                   END
     C                   END
     C                   END
     C                   END
     C                   ELSE
     C                   MOVE      EDA022        I19002
     C                   ENDIF
jc01aC     *LIKE         DEFINE    I19002        Save_I19002
jc01aC                   EVAL      Save_I19002 = I19002
      *
     C                   MOVE      EDA023        I19004
     C                   MOVE      EDA024        I19005
     C                   MOVE      *BLANKS       I19006
      *                  -----     -------
     C                   WRITE     FLIN#19
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *---------------------------------------------------------------
      *
      * ZF RFF following NAD Segment
     C                   IF        EDI026 = 7005
jc01aC                              or EDI026 = +9475
     C*****              MOVEL     EDI017        I192000                                     R
     C*****              MOVE      'A'           I192100
     C*****              Z-ADD     19            I192200
     C*****              MOVE      'VA '         I192001
     C*****              MOVEL     *blanks       I192002
     C*****              MOVEL     '1111'        I192002
     C*****              WRITE     FLIN#192
      *---------------------------------------------------------------
      * ZF - NAD Segment for PE - SR249958
      * packing slip, recID and #
jc01aC                   MOVEL     *Blanks       I19000                                      R
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'PE'          I19001
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVEL     'PE '         I19001
jc01aC                   MOVE      Save_I19002   I19002
jc01aC                   MOVE      EDA023        I19004
jc01aC                   MOVE      EDA024        I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   ELSE
     C                   MOVE      EDA030        I19002
     C                   MOVE      EDA031        I19004
     C                   MOVE      EDA032        I19005
jc01aC                   ENDIF
      *                  -----     -------
     C                   WRITE     FLIN#19
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *
      * ZF RFF following NAD Segment for PE
     C                   MOVEL     EDI017        I192000                                     R
     C                   MOVE      'A'           I192100
     C                   Z-ADD     19            I192200
     C                   MOVE      'PE '         I192001
     C                   MOVEL     *blanks       I192002
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVEL     Save_I19002   I192002
jc01aC                   ELSE
     C                   MOVEL     EDA030        I192002
jc01aC                   ENDIF
     C                   WRITE     FLIN#192
      *
      * Ship-To for ZF
jc01aC                   MOVEL     *Blanks       I19000                                      R
jc01aC                   MOVEL     *Blanks       I19001
     C                   MOVEL     EDI017        I19000                                      R
     C                   MOVE      'A'           I19100
     C                   Z-ADD     19            I19200
      *
     C                   MOVE      'ST'          I19001
     C                   MOVE      EDA030        I19002
     C                   MOVE      EDA031        I19004
     C                   MOVE      EDI008        I19005
     C                   MOVE      EDI009        I19006
     C                   MOVE      EDI010        I19007
      *                  -----     -------
     C                   WRITE     FLIN#19
jc01aC                   MOVE      *Blanks       I19002
jc01aC                   MOVE      *Blanks       I19004
jc01aC                   MOVE      *Blanks       I19005
jc01aC                   MOVE      *Blanks       I19006
jc01aC                   MOVE      *Blanks       I19007
      *
     C                   ENDIF
     *==============================================================*
     * CUX    U97BIN31            ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I31100                                      R
     C                   MOVE      'A'           I31200
     C                   Z-ADD     31            I31300
      *
     C                   MOVE      '1'           I31001                         ITD01
     C                   MOVE      'USD'         I31002                         ITD02
      *                  -----     -------
     C                   WRITE     FLIN#31
     ****************************************************************
     **                                                            **
     **             DETAIL FILES                                   **
     **                                                            **
     ****************************************************************
      * SET LOWER LIMITS ON DETAIL FILE
      *=====================================
     C     EDI002        SETLL     FLEDIDET
      *=====================================
      * SET LOWER LIMITS ON DUNNAGE FILE
      *=====================================
     C     EDI002        SETLL     FLEDIDUN
     C                   Z-ADD     0             LINE#             3 0
     C                   z-add     0             hlid              3 0
     C                   z-add     0             TOTSUR            9 2
     C                   z-add     0             ETTSUR            9 2
     C                   z-add     0             PNTSUR            9 2
     C                   z-add     0             AMTSUR            9 2
     C                   z-add     0             dunct             4 0
      *=====================================
      * READ EDIDETL FILE
      *=====================================
     C     REDETL        TAG
     C                   MOVE      '0'           *IN20
     C                   add       1             hlid              3 0
     C     edi002        READE     FLEDIDET                               20
     C     *IN20         CABEQ     '1'           REDIDUN                        END OF FILE
     C     EDD001        CABNE     EDI002        REDIDUN                        END OF INV'S
     C     EDD003        CABEQ     *BLANK        REDETL                         NO P/O #
     C     EDD012        CABEQ     'Y'           REDETL                         N/C LINE
     C     EDD013        CABEQ     'Y'           REDETL                         PRICE LATER LINE
      *--------------------------
      *  VALID RECORD
      *--------------------------
     C                   ADD       1             LINE#                          START COUNT
      *==============================================================*
      * TOTAL UP SURCHARGE AMOUNTS TO BE OUTPUTED AS ONE ITA RECORD
      * AT THE END OF THE INVOICE.
      *---------------------------------------------------------------
     C     EDD010        IFNE      0
     C                   ADD       EDD010        TOTSC             7 2
     C                   END
      /EJECT
     *==============================================================*
     * LIN        U97BIN91       ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I91000                                      R
     C                   MOVE      'D'           I91100
     C                   Z-ADD     hlid          I91200
     C                   MOVE      *blanks       I91300
     C                   MOVE      *blanks       I91400
     C                   MOVEL     EDI002        I91300                         INVOICE NUMBER
     C                   MOVEL     EDD004        I91400                         INVOICE NUMBER
      *
     C                   MOVE      *BLANKS       I91001                         UNIT PRICE
     C                   MOVEL     EDD002        I91001                         QUANTITY INVOICED
     C                   MOVE      *BLANKS       I91003                         UNIT PRICE
     C                   MOVEL     EDD004        I91003                         QUANTITY INVOICED
     C                   MOVE      *BLANKS       I91004                         UNIT PRICE
     C                   MOVE      'IN'          I91004                         UNIT PRICE
     C                   ADD       EDD010        TOTSUR                         QUANTITY INVOICED
     C                   IF        edd024 <> *zeros
     C                   ADD       EDD024        ETTSUR                         QUANTITY INVOICED
     C                   endif
     C                   if        edd026 <> *zeros
     C                   ADD       EDD026        ETTSUR                         QUANTITY INVOICED
     C                   endif
     C                   ADD       EDD019        PNTSUR                         QUANTITY INVOICED
     C                   ADD       EDD022        AMTSUR                         QUANTITY INVOICED
      *                  -----     -------
     C                   WRITE     FLIN#91                                      IT1 RECORD
      *                  -----     -------
     C                   MOVE      *BLANKS       I91001                         QUANTITY INVOICED
     C                   MOVE      *BLANKS       I91003
     C                   MOVE      *BLANKS       I91004
      *                  -------------------------------
      /EJECT
     *==============================================================*
     * IMD        U97BIN93       ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I93000                                      R
     C                   MOVE      'D'           I93100
     C                   Z-ADD     hlid          I93200
     C                   MOVE      *blanks       I93300
     C                   MOVE      *blanks       I93400
     C                   MOVEL     EDI002        I93300                         INVOICE NUMBER
     C                   MOVEL     EDD004        I93400                         INVOICE NUMBER
     C                   MOVE      *BLANKS       I93001                         SN102
     C                   MOVE      *BLANKS       I93006                         SN102
      * -- Item Type code
     C                   MOVEL     EDA049        I93001                         SN102
      * -- Item Desc #1
     C     EDA049        IFNE      *BLANKS
     C     EDD004        CHAIN     FLPARTFI                           25
     C     PTF016        CHAIN     PRTDSC01                           25
     C     *in25         IFEQ      '0'
     C                   MOVEL     PDS003        I93006
     C                   END
     C                   END
      *                  -----------------
      * -- Item Desc #1 ZF ONLY
     C     EDI026        IFEQ      7005
     C     EDD004        CHAIN     IVCPAR01                           25
     C     IVC001        CHAIN     FLPARTFI                           25
     C     PTF016        CHAIN     PRTDSC01                           25
     C     *in25         IFEQ      '0'
     C                   MOVEL     PDS003        I93006
     C                   END
     C                   END
      *                  -----------------
     C                   WRITE     FLIN#93
     *==============================================================*
     * QTY        U97BIN95       ==================================*
     *==============================================================*
     C     EDA048        IFNE      *BLANKS
      * packing slip, recID and #
     C                   MOVEL     EDI017        I95000                                      R
     C                   MOVE      'D'           I95100
     C                   Z-ADD     hlid          I95200
     C                   MOVE      *blanks       I95300
     C                   MOVE      *blanks       I95400
     C                   MOVEL     EDI002        I95300                         INVOICE NUMBER
     C                   MOVEL     EDD004        I95400                         INVOICE NUMBER
     C                   MOVE      *blanks       I95500
      *
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVEL     '12'          I95001                         MEA01        ID
jc01aC                   ELSE
     C                   MOVEL     '47'          I95001                         MEA01        ID
jc01aC                   ENDIF
     C                   MOVE      EDD005        I95002                         MEA02        ID
     C                   MOVEL     'EA'          I95003                         MEA01        ID
      *                  -----------------
     C                   WRITE     FLIN#95
     C                   END
     *==============================================================*
     * DTM        U07AIN24       ==================================*
     *==============================================================*
     C                   IF        EDI026 = 7005
jc01aC                             or EDI026 = +9475
      * packing slip, recID and #
     C                   MOVEL     EDI017        I24000                                      R
     C                   MOVE      'D'           I24100
     C                   Z-ADD     hlid          I24200
     C                   MOVE      *blanks       I24300
     C                   MOVE      *blanks       I24400
     C                   MOVEL     EDI002        I24300                         INVOICE NUMBER
     C                   MOVEL     EDD004        I24400                         INVOICE NUMBER
     C                   MOVE      *blanks       I24500
      *
     C                   MOVEL     '  1'         I24001                         MEA01        ID
     C                   MOVE      DATE8         I24002                         INVOICE NUMBER
     C                   MOVE      EDI018        I24002                         INVOICE NUMBER
     C                   MOVEL     '102'         I24003                         MEA01        ID
      *                  -----------------
     C                   WRITE     FLIN#24
      *
     C                   END
     *==============================================================*
     * MOA        U97BIN106      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I106000                                     R
     C                   MOVE      'D'           I106100
     C                   Z-ADD     hlid          I106200
     C                   MOVE      *blanks       I106300
     C                   MOVE      *blanks       I106400
     C                   MOVEL     EDI002        I106300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I106400                        INVOICE NUMBER
     C                   MOVE      *blanks       I106500
      *
     C                   MOVEL     '203'         I106001                        MEA01        ID
      *
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
      *
      * SR249958 - Add surcharge to each if ZF else use each price only
      *
     C                   IF        EDI026 = 7005
     C                   MOVE      EDI021        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDI021        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      'USD'         I106003                        MEA02        ID
     C                   ELSE
     C                   MOVE      EDD008        DECML3            3            DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDD008        WHOLE3            7            DUNNAGE UNIT PRICE
     C                   MOVE      *BLANKS       I106003                        MEA02        ID
     C                   ENDIF
      *
     C                   MOVE      DECML3        DECML6           10
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I106002                        MEA02        ID
      *                  -----------------
jc01aC                   IF        EDI026 = +9475
jc01aC                   ELSE
     C                   WRITE     FLIN#106
jc01aC                   ENDIF
      *
      * SR249958 - MOA for ZF that is extended price and surcharge
      * packing slip, recID and #
     C                   IF        EDI026 = 7005
jc01aC                              or EDI026 = +9475
     C                   MOVEL     EDI017        I106000                                     R
     C                   MOVE      'D'           I106100
     C                   Z-ADD     hlid          I106200
     C                   MOVE      *blanks       I106300
     C                   MOVE      *blanks       I106400
     C                   MOVEL     EDI002        I106300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I106400                        INVOICE NUMBER
     C                   MOVE      *blanks       I106500
      *
     C                   MOVEL     '38 '         I106001                        MEA01        ID
      *
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
      *
     C                   Z-ADD     *ZERO         EAPRC
     C                   ADD       EDD007        EAPRC
     C                   ADD       EDD009        EAPRC
     C                   ADD       EDD025        EAPRC
     C     EAPRC         MULT      EDD005        TGROSS                         DUNNAGE UNT PR
      *
     C                   MOVE      TGROSS        DECML3            3            DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     TGROSS        WHOLE3            7            DUNNAGE UNIT PRICE

     C                   MOVE      DECML3        DECML6           10
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I106002                        MEA02        ID
     C                   MOVE      'USD'         I106003                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#106
     C                   ENDIF
      *
      * SR249958 - If ZF this is CON pricing plus SurCharges
     *==============================================================*
     * PRI - For ZF ONLY  U97BIN112      =========================*
     *==============================================================*
      * packing slip, recID and #
     C                   IF        EDI026 = 7005
     C                   MOVEL     EDI017        I112000                                     R
     C                   MOVE      'D'           I112100
     C                   MOVE      *blanks       I112300
     C                   MOVE      *blanks       I112400
     C                   Z-ADD     hlid          I112200
     C                   MOVEL     EDI002        I112300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I112400                        INVOICE NUMBER
     C                   MOVE      *blanks       I112500
      *
     C                   MOVEL     'AAA'         I112001                        MEA01        ID
      *
     C                   Z-ADD     EDD007        TOTPRC
     C                   ADD       EDD009        TOTPRC
     C                   ADD       EDD025        TOTPRC
      *
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      TOTPRC        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     TOTPRC        WHOLE3                         DUNNAGE UNIT PRICE
      *
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I112002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#112
     C                   ENDIF
      *---------------------------------------------------------------
     C                   IF        EDI026 = 7005
      * ON - Packing Slip# for ZF
     C                   MOVEL     EDI017        I11000                                      R
     C                   MOVE      'A'           I11100
     C                   Z-ADD     11            I11200
     C                   MOVE      'ON '         I11001
     C                   MOVEL     *blanks       I11002                         ONLY
     C                   MOVEL     EDI017        I11002                         ONLY
     C                   WRITE     FLIN#11
     C                   ENDIF
      *---------------------------------------------------------------
      *
     *==============================================================*
     * PRI        U97BIN112      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I112000                                     R
     C                   MOVE      'D'           I112100
     C                   MOVE      *blanks       I112300
     C                   MOVE      *blanks       I112400
     C                   Z-ADD     hlid          I112200
     C                   MOVEL     EDI002        I112300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I112400                        INVOICE NUMBER
     C                   MOVE      *blanks       I112500
      *
     C                   IF        EDI026 = 7005
     C                   MOVEL     'CON'         I112001                        MEA01        ID
     C                   ELSE
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVEL     'AAB'         I112001                        MEA01        ID
jc01aC                   ELSE
     C                   MOVEL     'INV'         I112001                        MEA01        ID
jc01aC                   ENDIF
     C                   ENDIF
      *
     C                   MOVEL     EDD007        HPRI                           MEA02        ID
      *
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      EDD007        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVE      HPRI          WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I112002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#112
      *
     *==============================================================*
     * RFF        U07AIN193      ==================================*
     *==============================================================*
     C                   IF        EDI026 = 7005
      * AAU - Dispatch Notes for ZF
     C                   MOVE      *BLANKS       I193300
     C                   MOVE      *BLANKS       I193400
     C                   MOVE      *BLANKS       I193002
      *
     C                   MOVEL     EDI017        I193000                                     R
     C                   MOVE      'D'           I193100
     C                   Z-ADD     HLID          I193200
     C                   MOVEL     EDI002        I193300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I193400                        INVOICE NUMBER
     C                   MOVEL     *BLANKS       I193500
jc01aC                   IF        EDI026 = +9475
jc01aC                   MOVE      'AAK'         I193001
jc01aC                   EVAL      I193006 = '20' + %char(EDI016)
jc01aC                   ELSE
     C                   MOVE      'AAU'         I193001
jc01aC                   ENDIF
     C                   MOVEL     EDI017        I193002
     C                   WRITE     FLIN#193
jc01aC                   EVAL      I193006 = *Blanks
      * packing slip, recID and #
     C                   MOVE      *BLANKS       I193300
     C                   MOVE      *BLANKS       I193400
     C                   MOVE      *BLANKS       I193002
      *
     C                   MOVEL     EDI017        I193000                                     R
     C                   MOVE      'D'           I193100
     C                   Z-ADD     HLID          I193200
     C                   MOVEL     EDI002        I193300                        INVOICE NUMBER
     C                   MOVEL     EDD004        I193400                        INVOICE NUMBER
     C                   MOVE      *BLANKS       I193500
      *
     C                   MOVEL     'ON '         I193001
     C                   MOVEL     EDD003        I193002
      *                  --
     C                   WRITE     FLIN#193
      *
     *==============================================================*
     * TAX        U07AIN25       ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I25000                                      R
     C                   MOVE      'D'           I25100
     C                   MOVE      *BLANKS       I25300
     C                   MOVE      *BLANKS       I25400
     C                   Z-ADD     hlid          I25200
     C                   MOVEL     EDI002        I25300                         INVOICE NUMBER
     C                   MOVEL     EDD004        I25400                         INVOICE NUMBER
     C                   MOVE      *BLANKS       I25500
      *
     C                   MOVE      '  7'         I25001
     C                   MOVE      'VAT'         I25002
     C                   MOVEL     '0.0'         I25013
      *                  -----------------
     C                   WRITE     FLIN#25
      *
     C                   ENDIF
      *
     C                   GOTO      REDETL
     *==============================================================*
     * UNS        U97BIN176      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I176000                                     R
     C                   MOVE      'D'           I176100
     C                   Z-ADD     84            I176200
      *
     C                   MOVEL     'S'           I176001                        MEA01        ID
      *                  -----------------
     C                   WRITE     FLIN#176
      **============================================================**
      ** DUNNAGE FILE       EDIDUNN                                 **
      **============================================================**
     C     REDIDUN       TAG
     C                   Z-ADD     0             TOTDUN            9 2          CLEAR FIELD
     C     REDIDUN2      TAG
     C                   MOVE      '0'           *IN20
      *
     C     EDI002        READE     FLEDIDUN                               20
     C     *IN20         CABEQ     '1'           EREDIDUN
     C     EDG001        CABNE     EDI002        EREDIDUN                       INVOICE NUMBER
     C     EDG008        CABEQ     0             REDIDUN2                       DUNNAGE EXT. PRICE
      *
     C                   ADD       EDG008        TOTDUN
     C                   goto      REDIDUN2                                     DUNNAGE EXT. PRICE
     C     EREDIDUN      TAG
      /EJECT
     *==============================================================*
     * MOA        U97BIN183      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I183000                                     R
     C                   MOVE      'D'           I183100
     C                   Z-ADD     89            I183200
     C                   MOVE      *blanks       I183300
     C                   MOVE      *blanks       I183400
     C                   MOVE      *blanks       I183500
      *
      * If ZF code is 77 ELSE 39
     C                   IF        EDI026 = 7005
     C                   MOVEL     '77'          I183001                        MEA01        ID
     C                   MOVE      'USD'         I183003                        MEA02        ID
     C                   ELSE
     C                   MOVEL     '39'          I183001                        MEA01        ID
     C                   ENDIF

     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      EDI021        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDI021        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I183002                        MEA02        ID
      *                  -----------------
      *                  -----------------
     C                   WRITE     FLIN#183
     *==============================================================*
     * ALC  SURCHARGE  U97BIN189      ==============================*
     *==============================================================*
     C     TOTSUR        IFNE      0
     C     ETTSUR        ORNE      0
      * packing slip, recID and #
     C                   MOVEL     EDI017        I189000                                     R
     C                   MOVE      'D'           I189100
     C                   Z-ADD     92            I189200
     C                   add       1             dunct             4 0
     C                   movel     dunct         I189300
     C                   movel     *blanks       I189400
     C                   movel     *blanks       I189500
     C                   movel     *blanks       I189006
     C                   MOVEL     'C'           I189001                        MEA01        ID
     C                   MOVEL     'SC'          I189006                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#189
      *
      * SR249958 - ZF only Tax totals for MOA for codes 125, 176, and 79
      *
     C                   IF        EDI026 = 7005
     *==============================================================*
     * MOA        U97BIN183      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I183000                                     R
     C                   MOVE      'D'           I183100
     C                   Z-ADD     89            I183200
     C                   MOVE      *blanks       I183300
     C                   MOVE      *blanks       I183400
     C                   MOVE      *blanks       I183500
      *
     C                   MOVEL     '125'         I183001                        MEA01        ID

     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      *ZEROS        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     *ZEROS        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I183002                        MEA02        ID
     C                   MOVE      'USD'         I183003                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#183
     *==============================================================*
     * MOA        U97BIN183      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I183000                                     R
     C                   MOVE      'D'           I183100
     C                   Z-ADD     89            I183200
     C                   MOVE      *blanks       I183300
     C                   MOVE      *blanks       I183400
     C                   MOVE      *blanks       I183500
      *
     C                   MOVEL     '176'         I183001                        MEA01        ID

     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      *ZEROS        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     *ZEROS        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I183002                        MEA02        ID
     C                   MOVE      'USD'         I183003                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#183
     *==============================================================*
     * MOA        U97BIN183      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I183000                                     R
     C                   MOVE      'D'           I183100
     C                   Z-ADD     89            I183200
     C                   MOVE      *blanks       I183300
     C                   MOVE      *blanks       I183400
     C                   MOVE      *blanks       I183500
      *
     C                   MOVEL     '79 '         I183001                        MEA01        ID

     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      EDI021        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDI021        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I183002                        MEA02        ID
     C                   MOVE      'USD'         I183003                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#183
     C                   ENDIF
      * SR249958 - End of Code 125, 176, and 79 change for ZF
     *==============================================================*
     * MOA        U97BIN191      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I191000                                     R
     C                   MOVE      'D'           I191100
     C                   Z-ADD     92            I191200
     C                   movel     dunct         I191300
     C                   movel     *blanks       I191500
     C                   MOVEL     '8'           I191001                        MEA01        ID
     C                   MOVEL     *blanks       I191002                        MEA02        ID
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C     ETTSUR        ADD       TOTSUR        TOTSUR
     C                   MOVE      TOTSUR        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     TOTSUR        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I191002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#191
     C                   endif
     *==============================================================*
     * ALC Amortization U97BIN189   ================================*
     *==============================================================*
     C     AMTSUR        IFNE      0
      * packing slip, recID and #
     C                   MOVEL     EDI017        I189000                                     R
     C                   MOVE      'D'           I189100
     C                   Z-ADD     92            I189200
     C                   add       1             dunct             4 0
     C                   movel     dunct         I189300
     C                   movel     *blanks       I189400
     C                   movel     *blanks       I189500
     C                   movel     *blanks       I189006
     C                   MOVEL     'C'           I189001                        MEA01        ID
     C                   MOVEL     'ABG'         I189006                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#189
     *==============================================================*
     * MOA        U97BIN191      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I191000                                     R
     C                   MOVE      'D'           I191100
     C                   Z-ADD     92            I191200
     C                   movel     dunct         I191300
     C                   movel     *blanks       I191500
     C                   MOVEL     '8'           I191001                        MEA01        ID
     C                   MOVEL     *blanks       I191002                        MEA02        ID
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      AMTSUR        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     AMTSUR        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I191002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#191
     C                   endif
     *==============================================================*
     * ALC Paint/oil  U97BIN189    =================================*
     *==============================================================*
     C     PNTSUR        IFNE      0
      * packing slip, recID and #
     C                   MOVEL     EDI017        I189000                                     R
     C                   MOVE      'D'           I189100
     C                   Z-ADD     92            I189200
     C                   add       1             dunct             4 0
     C                   movel     dunct         I189300
     C                   movel     *blanks       I189400
     C                   movel     *blanks       I189500
     C                   movel     *blanks       I189006
     C                   MOVEL     'C'           I189001                        MEA01        ID
     C                   MOVEL     'ABK'         I189006                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#189
     *==============================================================*
     * MOA        U97BIN191      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I191000                                     R
     C                   MOVE      'D'           I191100
     C                   Z-ADD     92            I191200
     C*                  add       1             dunct             4 0
     C                   movel     dunct         I191300
     C                   movel     *blanks       I191500
     C                   MOVEL     '8'           I191001                        MEA01        ID
     C                   MOVEL     *blanks       I191002                        MEA02        ID
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML6
     C                   MOVE      *BLANKS       WHOLE3
     C                   MOVE      PNTSUR        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     PNTSUR        WHOLE3                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML6
     C                   MOVEL     WHOLE3        DECML6
     C                   MOVEL     DECML6        I191002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#191
     C                   endif
     *==============================================================*
     * ALC DUNNAGE    U97BIN189    =================================*
     *==============================================================*
     C     TOTDUN        IFNE      0
     C                   MOVE      '0'           *IN20
     C     EDI002        SETLL     FLEDIDUN                               20
     C     REDIDUN3      TAG
     C     EDI002        READE     FLEDIDUN                               20
     C     *IN20         CABEQ     '1'           EREDID3
     C     EDG001        CABNE     EDI002        EREDID3                        INVOICE NUMBER
     C     EDG008        CABEQ     0             REDIDUN3                       DUNNAGE EXT. PRICE
      * packing slip, recID and #
     C                   MOVEL     EDI017        I189000                                     R
     C                   MOVE      'D'           I189100
     C                   Z-ADD     92            I189200
     C                   add       1             dunct             4 0
     C                   movel     dunct         I189300
     C                   movel     *blanks       I189400
     C                   movel     *blanks       I189500
     C                   movel     *blanks       I189006
      *
     C                   MOVEL     'C'           I189001                        MEA01        ID
     C     EDG002        IFEQ      1
     C                   MOVEL     'PN'          I189006                        MEA02        ID
     C                   ELSE
     C                   MOVEL     'PC'          I189006                        MEA02        ID
     c                   endif
      *                  -----------------
     C                   WRITE     FLIN#189
     *==============================================================*
     * MOA        U97BIN191      ==================================*
     *==============================================================*
      * packing slip, recID and #
     C                   MOVEL     EDI017        I191000                                     R
     C                   MOVE      'D'           I191100
     C                   Z-ADD     92            I191200
     C*                  add       1             dunct             4 0
     C                   movel     dunct         I191300
     C                   movel     *blanks       I191500
     C                   MOVEL     '8'           I191001                        MEA01        ID
     C                   MOVEL     *blanks       I191002                        MEA02        ID
     C*                  MOVEL     EDG008        I191002                        MEA02        ID
     C                   MOVE      *BLANKS       DECML3
     C                   MOVE      *BLANKS       DECML7            8
     C                   MOVE      *BLANKS       WHOLE4            5
     C                   MOVE      EDG008        DECML3                         DUNNAGE UNT PR
     C                   MOVEL     '.'           DECML3
     C                   MOVEL     EDG008        WHOLE4                         DUNNAGE UNIT PRICE
     C                   MOVE      DECML3        DECML7
     C                   MOVEL     WHOLE4        DECML7
     C                   MOVEL     DECML7        I191002                        MEA02        ID
      *                  -----------------
     C                   WRITE     FLIN#191
     C                   goto      REDIDUN3                                     DUNNAGE EXT. PRICE
     C                   ENDIF
     C     EREDID3       TAG
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
     C     edi002        READE     FLEDIDET                               20
     C     *IN20         CABEQ     '1'           ENDS1
     C     EDD001        CABNE     EDI002        ENDS1
     C     EDD003        CABEQ     *BLANK        TOPS1
     C                   ADD       1             COUNT
     C     COUNT         IFEQ      1
     C                   MOVE      EDD003        HOLDPO           20
     C                   END
     C     EDD003        IFNE      HOLDPO
     C                   MOVE      '1'           *IN50
     C                   END
     C                   GOTO      TOPS1
     C     ENDS1         ENDSR
      /EJECT
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
**********************************************************************
