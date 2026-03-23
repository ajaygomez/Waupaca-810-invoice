SHELL=/QOpenSys/usr/bin/qsh
DATA_LIBRARY=EDITEST

all: invdriver.clle edi810.sqlrpgle invoice.sqlrpgle

%.rpgle:
	-system -q "CRTSRCPF FILE($(DATA_LIBRARY)/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE($(DATA_LIBRARY)/QRPGLESRC) MBR($*) SRCTYPE(RPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/$*.rpgle') TOMBR('/QSYS.LIB/$(DATA_LIBRARY).LIB/QRPGLESRC.FILE/$*.MBR') MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE($(DATA_LIBRARY)/QRPGLESRC) MBR($*) SRCTYPE(RPGLE)"
	liblist -al $(DATA_LIBRARY); \
	system "CRTBNDRPG PGM($(DATA_LIBRARY)/$*) SRCFILE($(DATA_LIBRARY)/QRPGLESRC) SRCMBR($*) DBGVIEW(*SOURCE) REPLACE(*YES) TEXT('$(DATA_LIBRARY)/$*')"

%.sqlrpgle:
	-system -q "CRTSRCPF FILE($(DATA_LIBRARY)/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE($(DATA_LIBRARY)/QRPGLESRC) MBR($*) SRCTYPE(SQLRPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/$*.sqlrpgle') TOMBR('/QSYS.LIB/$(DATA_LIBRARY).LIB/QRPGLESRC.FILE/$*.MBR') MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE($(DATA_LIBRARY)/QRPGLESRC) MBR($*) SRCTYPE(SQLRPGLE)"
	liblist -al $(DATA_LIBRARY); \
	system "CRTSQLRPGI OBJ($(DATA_LIBRARY)/$*) SRCFILE($(DATA_LIBRARY)/QRPGLESRC) SRCMBR($*) COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) DBGVIEW(*SOURCE)"

%.clle:
	-system -q "CRTSRCPF FILE($(DATA_LIBRARY)/QCLLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE($(DATA_LIBRARY)/QCLLESRC) MBR($*) SRCTYPE(CLLE)"
	system "CPYFRMSTMF FROMSTMF('./qcllesrc/$*.clle') \
	            TOMBR('/QSYS.LIB/$(DATA_LIBRARY).LIB/QCLLESRC.FILE/$*.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE($(DATA_LIBRARY)/QCLLESRC) \
	            MBR($*) SRCTYPE(CLLE)"
	liblist -al $(DATA_LIBRARY); \
	  system "CRTCLPGM PGM($(DATA_LIBRARY)/$*) \
	              SRCFILE($(DATA_LIBRARY)/QCLLESRC) SRCMBR($*) \
	              OPTION(*SRCDBG) \
	              REPLACE(*YES) TEXT('CLLE program $*')"

production-compile:
	liblist -al $(DATA_LIBRARY); \
	system "COMPILE SRCMBR($*) FILE(QRPGLESRC) LIB($(DATA_LIBRARY)) MBRTYPE(RPGLE) OBJNAM($*) OBJLIB($(DATA_LIBRARY)) JOBD(AGLIB/ALBARO) DLTLSTNG(*YES)"

# --- DEV - Compile Invoice Programs to GOMEZA (Dev Library) ---
# Compiles INVDRIVER, EDI810, and INVOICE into GOMEZA library
# Usage: make dev
# Individual targets: make invdriver-dev, make edi810-dev, make invoice-dev
# This target is NOT part of 'all' - compile on request only
.PHONY: dev
dev: invdriver-dev edi810-dev invoice-dev
	@echo ""
	@echo "========================================"
	@echo "GOMEZA Dev Compilation Complete!"
	@echo "========================================"
	@echo "Programs compiled to GOMEZA:"
	@echo "  GOMEZA/INVDRIVER - Invoice EDI Driver (CL)"
	@echo "  GOMEZA/EDI810   - X12 810 Invoice Generator"
	@echo "  GOMEZA/INVOICE  - EDIFACT INVOIC Generator"
	@echo ""
	@echo "Usage:"
	@echo "  CALL GOMEZA/INVDRIVER PARM('145566' '004285' '1234567' '00')"
	@echo "========================================"

# --- INVDRIVER-DEV - INVDRIVER Program to GOMEZA ---
# Compiles INVDRIVER CL program into GOMEZA library
# Usage: make invdriver-dev (or as part of 'make dev')
.PHONY: invdriver-dev
invdriver-dev:
	@echo "Compiling INVDRIVER to GOMEZA..."
	-system -q "CRTSRCPF FILE(GOMEZA/QCLLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(GOMEZA/QCLLESRC) MBR(INVDRIVER) SRCTYPE(CLLE)"
	system "CPYFRMSTMF FROMSTMF('./qcllesrc/invdriver.clle') \
	            TOMBR('/QSYS.LIB/GOMEZA.LIB/QCLLESRC.FILE/INVDRIVER.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(GOMEZA/QCLLESRC) \
	            MBR(INVDRIVER) SRCTYPE(CLLE)"
	liblist -al GOMEZA; \
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTCLPGM PGM(GOMEZA/INVDRIVER) \
	              SRCFILE(GOMEZA/QCLLESRC) SRCMBR(INVDRIVER) \
	              OPTION(*SRCDBG) \
	              REPLACE(*YES) TEXT('INVDRIVER - Invoice EDI Driver')"
	@echo "INVDRIVER compiled successfully to GOMEZA."

# --- EDI810-DEV - EDI810 Program to GOMEZA ---
# Compiles EDI810 SQLRPGLE program into GOMEZA library
# Usage: make edi810-dev (or as part of 'make dev')
.PHONY: edi810-dev
edi810-dev:
	@echo "Compiling EDI810 to GOMEZA..."
	-system -q "CRTSRCPF FILE(GOMEZA/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(GOMEZA/QRPGLESRC) MBR(EDI810) SRCTYPE(SQLRPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/edi810.sqlrpgle') \
	            TOMBR('/QSYS.LIB/GOMEZA.LIB/QRPGLESRC.FILE/EDI810.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(GOMEZA/QRPGLESRC) \
	            MBR(EDI810) SRCTYPE(SQLRPGLE)"
	liblist -al GOMEZA; \
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTSQLRPGI OBJ(GOMEZA/EDI810) \
	              SRCFILE(GOMEZA/QRPGLESRC) SRCMBR(EDI810) \
	              COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) \
	              DBGVIEW(*SOURCE) REPLACE(*YES) \
	              TEXT('EDI810 - X12 810 Invoice Generator')"
	@echo "EDI810 compiled successfully to GOMEZA."

# --- INVOICE-DEV - INVOICE Program to GOMEZA ---
# Compiles INVOICE SQLRPGLE program into GOMEZA library
# Usage: make invoice-dev (or as part of 'make dev')
.PHONY: invoice-dev
invoice-dev:
	@echo "Compiling INVOICE to GOMEZA..."
	-system -q "CRTSRCPF FILE(GOMEZA/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(GOMEZA/QRPGLESRC) MBR(INVOICE) SRCTYPE(SQLRPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/invoice.sqlrpgle') \
	            TOMBR('/QSYS.LIB/GOMEZA.LIB/QRPGLESRC.FILE/INVOICE.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(GOMEZA/QRPGLESRC) \
	            MBR(INVOICE) SRCTYPE(SQLRPGLE)"
	liblist -al GOMEZA; \
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTSQLRPGI OBJ(GOMEZA/INVOICE) \
	              SRCFILE(GOMEZA/QRPGLESRC) SRCMBR(INVOICE) \
	              COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) \
	              DBGVIEW(*SOURCE) REPLACE(*YES) \
	              TEXT('INVOICE - EDIFACT INVOIC Generator')"
	@echo "INVOICE compiled successfully to GOMEZA."

# --- TEST-INV - Compile Invoice Programs to EDITEST (Test Library) ---
# Compiles INVDRIVER, EDI810, and INVOICE into EDITEST library
# Usage: make test-inv
# Individual targets: make invdriver-test, make edi810-test, make invoice-test
# This target is NOT part of 'all' - compile on request only
.PHONY: test-inv
test-inv: invdriver-test edi810-test invoice-test
	@echo ""
	@echo "========================================"
	@echo "EDITEST Test Compilation Complete!"
	@echo "========================================"
	@echo "Programs compiled to EDITEST:"
	@echo "  EDITEST/INVDRIVER - Invoice EDI Driver (CL)"
	@echo "  EDITEST/EDI810   - X12 810 Invoice Generator"
	@echo "  EDITEST/INVOICE  - EDIFACT INVOIC Generator"
	@echo ""
	@echo "Usage:"
	@echo "  CALL EDITEST/INVDRIVER PARM('145566' '004285' '1234567' '00')"
	@echo "========================================"

# --- INVDRIVER-TEST - INVDRIVER Program to EDITEST ---
# Compiles INVDRIVER CL program into EDITEST library
# Usage: make invdriver-test (or as part of 'make test-inv')
.PHONY: invdriver-test
invdriver-test:
	@echo "Compiling INVDRIVER to EDITEST..."
	-system -q "CRTSRCPF FILE(EDITEST/QCLLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(EDITEST/QCLLESRC) MBR(INVDRIVER) SRCTYPE(CLLE)"
	system "CPYFRMSTMF FROMSTMF('./qcllesrc/invdriver.clle') \
	            TOMBR('/QSYS.LIB/EDITEST.LIB/QCLLESRC.FILE/INVDRIVER.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(EDITEST/QCLLESRC) \
	            MBR(INVDRIVER) SRCTYPE(CLLE)"
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTCLPGM PGM(EDITEST/INVDRIVER) \
	              SRCFILE(EDITEST/QCLLESRC) SRCMBR(INVDRIVER) \
	              OPTION(*SRCDBG) \
	              REPLACE(*YES) TEXT('INVDRIVER - Invoice EDI Driver')"
	@echo "INVDRIVER compiled successfully to EDITEST."

# --- EDI810-TEST - EDI810 Program to EDITEST ---
# Compiles EDI810 SQLRPGLE program into EDITEST library
# Usage: make edi810-test (or as part of 'make test-inv')
.PHONY: edi810-test
edi810-test:
	@echo "Compiling EDI810 to EDITEST..."
	-system -q "CRTSRCPF FILE(EDITEST/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(EDITEST/QRPGLESRC) MBR(EDI810) SRCTYPE(SQLRPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/edi810.sqlrpgle') \
	            TOMBR('/QSYS.LIB/EDITEST.LIB/QRPGLESRC.FILE/EDI810.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(EDITEST/QRPGLESRC) \
	            MBR(EDI810) SRCTYPE(SQLRPGLE)"
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTSQLRPGI OBJ(EDITEST/EDI810) \
	              SRCFILE(EDITEST/QRPGLESRC) SRCMBR(EDI810) \
	              COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) \
	              DBGVIEW(*SOURCE) REPLACE(*YES) \
	              TEXT('EDI810 - X12 810 Invoice Generator')"
	@echo "EDI810 compiled successfully to EDITEST."

# --- INVOICE-TEST - INVOICE Program to EDITEST ---
# Compiles INVOICE SQLRPGLE program into EDITEST library
# Usage: make invoice-test (or as part of 'make test-inv')
.PHONY: invoice-test
invoice-test:
	@echo "Compiling INVOICE to EDITEST..."
	-system -q "CRTSRCPF FILE(EDITEST/QRPGLESRC) RCDLEN(112)"
	-system -q "ADDPFM FILE(EDITEST/QRPGLESRC) MBR(INVOICE) SRCTYPE(SQLRPGLE)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/invoice.sqlrpgle') \
	            TOMBR('/QSYS.LIB/EDITEST.LIB/QRPGLESRC.FILE/INVOICE.MBR') \
	            MBROPT(*REPLACE) CVTDTA(*AUTO)"
	system "CHGPFM FILE(EDITEST/QRPGLESRC) \
	            MBR(INVOICE) SRCTYPE(SQLRPGLE)"
	liblist -al EDITEST; \
	liblist -al WFLIB; \
	liblist -al WFDTA; \
	  system "CRTSQLRPGI OBJ(EDITEST/INVOICE) \
	              SRCFILE(EDITEST/QRPGLESRC) SRCMBR(INVOICE) \
	              COMMIT(*NONE) OPTION(*EVENTF) RPGPPOPT(*LVL2) \
	              DBGVIEW(*SOURCE) REPLACE(*YES) \
	              TEXT('INVOICE - EDIFACT INVOIC Generator')"
	@echo "INVOICE compiled successfully to EDITEST."
