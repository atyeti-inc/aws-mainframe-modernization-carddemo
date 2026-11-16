# Makefile for AWS Mainframe Modernization CardDemo COBOL Suite
# Compiler: GnuCOBOL (cobc) targeting IBM Enterprise COBOL dialect

COBC ?= cobc
COBFLAGS = -std=ibm -ftab-width=4
INCLUDES = -I app/cpy -I app/cpy-bms

BUILD_DIR = build

# Core batch COBOL modules (standard batch programs & utilities)
BATCH_SRCS = \
	app/cbl/CBACT01C.cbl \
	app/cbl/CBACT02C.cbl \
	app/cbl/CBACT03C.cbl \
	app/cbl/CBACT04C.cbl \
	app/cbl/CBCUS01C.cbl \
	app/cbl/CBEXPORT.cbl \
	app/cbl/CBIMPORT.cbl \
	app/cbl/CBTRN01C.cbl \
	app/cbl/CBTRN02C.cbl \
	app/cbl/CBTRN03C.cbl \
	app/cbl/CBSTM03A.CBL \
	app/cbl/CBSTM03B.CBL \
	app/cbl/CSUTLDTC.cbl \
	app/cbl/COBSWAIT.cbl

# Sub-module batch utilities (IMS/DB2/MQ unload/load utilities)
SUBAPP_AUTH_SRCS = \
	app/app-authorization-ims-db2-mq/cbl/DBUNLDGS.CBL \
	app/app-authorization-ims-db2-mq/cbl/PAUDBLOD.CBL \
	app/app-authorization-ims-db2-mq/cbl/PAUDBUNL.CBL

BATCH_OBJS = \
	$(BUILD_DIR)/CBACT01C.o \
	$(BUILD_DIR)/CBACT02C.o \
	$(BUILD_DIR)/CBACT03C.o \
	$(BUILD_DIR)/CBACT04C.o \
	$(BUILD_DIR)/CBCUS01C.o \
	$(BUILD_DIR)/CBEXPORT.o \
	$(BUILD_DIR)/CBIMPORT.o \
	$(BUILD_DIR)/CBTRN01C.o \
	$(BUILD_DIR)/CBTRN02C.o \
	$(BUILD_DIR)/CBTRN03C.o \
	$(BUILD_DIR)/CBSTM03A.o \
	$(BUILD_DIR)/CBSTM03B.o \
	$(BUILD_DIR)/CSUTLDTC.o \
	$(BUILD_DIR)/COBSWAIT.o

.PHONY: all check test clean help

all: $(BUILD_DIR) $(BATCH_OBJS)
	@echo "All batch COBOL modules compiled successfully to $(BUILD_DIR)/."

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Compilation rules
$(BUILD_DIR)/%.o: app/cbl/%.cbl | $(BUILD_DIR)
	$(COBC) -c $(COBFLAGS) $(INCLUDES) $< -o $@

$(BUILD_DIR)/%.o: app/cbl/%.CBL | $(BUILD_DIR)
	$(COBC) -c $(COBFLAGS) $(INCLUDES) $< -o $@

# Syntax-only verification for batch modules
check:
	@echo "Checking syntax of core batch COBOL modules..."
	@for src in $(BATCH_SRCS); do \
		printf "  CHECK %-35s " "$$src"; \
		$(COBC) -fsyntax-only $(COBFLAGS) $(INCLUDES) $$src && echo "[OK]" || exit 1; \
	done
	@echo "Checking syntax of sub-application batch modules..."
	@for src in $(SUBAPP_AUTH_SRCS); do \
		printf "  CHECK %-35s " "$$src"; \
		$(COBC) -fsyntax-only $(COBFLAGS) -I app/app-authorization-ims-db2-mq/cpy $(INCLUDES) $$src && echo "[OK]" || exit 1; \
	done
	@echo "All batch COBOL syntax checks passed successfully."

# Test target: runs checks, compiles modules, and validates artifacts
test: check all
	@echo "Running verification tests..."
	@echo "Verifying generated object files..."
	@for obj in $(BATCH_OBJS); do \
		test -f $$obj || (echo "Missing object: $$obj" && exit 1); \
	done
	@echo "Verifying copybook existence in app/cpy and app/cpy-bms..."
	@for cpy in app/cpy/*.cpy app/cpy/*.CPY app/cpy-bms/*.CPY; do \
		test -f "$$cpy" || (echo "Missing copybook: $$cpy" && exit 1); \
	done
	@echo "All CardDemo COBOL tests passed."

clean:
	rm -rf $(BUILD_DIR) *.o *.so *.gnt *.int *.lst *.listing *.tmp test.txt

help:
	@echo "CardDemo COBOL Suite - Targets:"
	@echo "  make check - Run syntax verification across all batch modules"
	@echo "  make all   - Compile all batch COBOL modules into $(BUILD_DIR)/"
	@echo "  make test  - Run syntax check, full compile, and artifact verification"
	@echo "  make clean - Remove build artifacts"
	@echo "  make help  - Show this help message"

