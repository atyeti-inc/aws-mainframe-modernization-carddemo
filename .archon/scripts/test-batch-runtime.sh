#!/usr/bin/env bash
# General project test runner for CardDemo batch programs with EBCDIC sample datasets
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build"
DATA_DIR="$REPO_ROOT/app/data/EBCDIC"

COBC="${COBC:-cobc}"
COBFLAGS="${COBFLAGS:--std=ibm -ftab-width=4}"
INCLUDES="${INCLUDES:--I app/cpy -I app/cpy-bms}"

mkdir -p "$BUILD_DIR"

echo "=== Running Batch Dataset Runtime I/O Verification ==="

# 1. Test CBIMPORT file organization and data ingestion against AWS.M2.CARDDEMO.EXPORT.DATA.PS
if [ -f "$REPO_ROOT/app/cbl/CBIMPORT.cbl" ] && [ -f "$DATA_DIR/AWS.M2.CARDDEMO.EXPORT.DATA.PS" ]; then
    printf "  TEST %-40s " "CBIMPORT runtime I/O against EXPORT.DATA.PS"
    
    # Attempt standalone executable compilation
    if ! $COBC -x $COBFLAGS $INCLUDES "$REPO_ROOT/app/cbl/CBIMPORT.cbl" -o "$BUILD_DIR/CBIMPORT" 2>/dev/null; then
        echo "[FAILED]"
        echo "CBIMPORT failed to compile executable binary." >&2
        exit 1
    fi
    
    TMP_OUT="$(mktemp -d /tmp/carddemo-test-XXXXXX)"
    trap 'rm -rf "$TMP_OUT"' EXIT
    
    # Simulating IDCAMS REPRO: unpack sequential flat file to VSAM KSDS ISAM fixture
    cat << 'EOF' > "$TMP_OUT/repro_ksds.cbl"
       IDENTIFICATION DIVISION.
       PROGRAM-ID. REPROKSD.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SEQ-FILE ASSIGN TO SEQIN
               ORGANIZATION IS RECORD SEQUENTIAL
               FILE STATUS IS WS-SEQ-STATUS.
           SELECT KSDS-FILE ASSIGN TO KSDSOUT
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS EXPORT-SEQUENCE-NUM
               FILE STATUS IS WS-KSDS-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  SEQ-FILE
           RECORD CONTAINS 500 CHARACTERS.
       01  SEQ-RECORD PIC X(500).
       FD  KSDS-FILE
           RECORD CONTAINS 500 CHARACTERS.
       COPY CVEXPORT.
       WORKING-STORAGE SECTION.
       01  WS-SEQ-STATUS PIC X(2).
       01  WS-KSDS-STATUS PIC X(2).
       01  WS-RECORDS-LOADED PIC 9(9) VALUE 0.
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT SEQ-FILE
           IF WS-SEQ-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING SEQ-FILE: ' WS-SEQ-STATUS
               STOP RUN RETURNING 1
           END-IF
           OPEN OUTPUT KSDS-FILE
           IF WS-KSDS-STATUS NOT = '00'
               DISPLAY 'ERROR OPENING KSDS-FILE: ' WS-KSDS-STATUS
               STOP RUN RETURNING 1
           END-IF
           PERFORM UNTIL WS-SEQ-STATUS = '10'
               READ SEQ-FILE
               IF WS-SEQ-STATUS = '00'
                   MOVE SEQ-RECORD TO EXPORT-RECORD
                   WRITE EXPORT-RECORD
                   IF WS-KSDS-STATUS NOT = '00'
                       DISPLAY 'ERROR WRITING KSDS-RECORD: '
                               WS-KSDS-STATUS
                       STOP RUN RETURNING 1
                   END-IF
                   ADD 1 TO WS-RECORDS-LOADED
               ELSE
                   IF WS-SEQ-STATUS NOT = '10'
                       DISPLAY 'ERROR READING SEQ-FILE: ' WS-SEQ-STATUS
                       STOP RUN RETURNING 1
                   END-IF
               END-IF
           END-PERFORM
           CLOSE SEQ-FILE
           CLOSE KSDS-FILE
           GOBACK.
EOF

    if ! $COBC -x $COBFLAGS $INCLUDES "$TMP_OUT/repro_ksds.cbl" -o "$BUILD_DIR/repro_ksds" 2>/dev/null; then
        echo "[FAILED]"
        echo "repro_ksds failed to compile." >&2
        exit 1
    fi

    export DD_SEQIN="$DATA_DIR/AWS.M2.CARDDEMO.EXPORT.DATA.PS"
    export DD_KSDSOUT="$TMP_OUT/EXPORT.DATA.KSDS"
    if ! "$BUILD_DIR/repro_ksds" >/dev/null 2>&1; then
        echo "[FAILED]"
        echo "Failed to load sequential seed data into KSDS fixture." >&2
        exit 1
    fi

    export DD_EXPFILE="$TMP_OUT/EXPORT.DATA.KSDS"
    export DD_CUSTOUT="$TMP_OUT/CUSTOUT.dat"
    export DD_ACCTOUT="$TMP_OUT/ACCTOUT.dat"
    export DD_XREFOUT="$TMP_OUT/XREFOUT.dat"
    export DD_TRNXOUT="$TMP_OUT/TRNXOUT.dat"
    export DD_CARDOUT="$TMP_OUT/CARDOUT.dat"
    export DD_ERROUT="$TMP_OUT/ERROUT.dat"
    
    # Run binary and capture output
    if ! OUTPUT="$("$BUILD_DIR/CBIMPORT" 2>&1)"; then
        echo "[FAILED]"
        echo "Runtime abend or non-zero exit in CBIMPORT:" >&2
        echo "$OUTPUT" >&2
        exit 1
    fi
    
    # Verify file was successfully opened and read (not abended with status 30 or similar error)
    if echo "$OUTPUT" | grep -q "ERROR: Reading EXPORT-INPUT"; then
        echo "[FAILED]"
        echo "CBIMPORT failed to read input file (file organization / dataset mismatch):" >&2
        echo "$OUTPUT" >&2
        exit 1
    fi
    
    if ! echo "$OUTPUT" | grep -q "Total Records Read: 000000500"; then
        echo "[FAILED]"
        echo "CBIMPORT did not read expected 500 records:" >&2
        echo "$OUTPUT" >&2
        exit 1
    fi

    echo "[OK]"
fi

echo "All batch runtime verification tests passed successfully."
