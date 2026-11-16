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
    
    # Compile and run a helper to stage sequential EXPORT.DATA.PS into an indexed file (simulating IDCAMS REPRO)
    cat << 'EOF' > "$TMP_OUT/stage_export.cbl"
       IDENTIFICATION DIVISION.
       PROGRAM-ID. STGEXP.
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT SEQ-INPUT ASSIGN TO SEQIN
               ORGANIZATION IS RECORD SEQUENTIAL
               FILE STATUS IS WS-SEQ-STATUS.
           SELECT IDX-OUTPUT ASSIGN TO IDXOUT
               ORGANIZATION IS INDEXED
               ACCESS MODE IS SEQUENTIAL
               RECORD KEY IS EXPORT-SEQUENCE-NUM
               FILE STATUS IS WS-IDX-STATUS.
       DATA DIVISION.
       FILE SECTION.
       FD  SEQ-INPUT
           RECORDING MODE IS F
           RECORD CONTAINS 500 CHARACTERS.
       01  SEQ-RECORD PIC X(500).
       FD  IDX-OUTPUT.
       COPY CVEXPORT.
       WORKING-STORAGE SECTION.
       01  WS-STATUS.
           05 WS-SEQ-STATUS PIC X(2).
           05 WS-IDX-STATUS PIC X(2).
       PROCEDURE DIVISION.
       0000-MAIN.
           OPEN INPUT SEQ-INPUT
           OPEN OUTPUT IDX-OUTPUT
           PERFORM UNTIL WS-SEQ-STATUS = '10'
               READ SEQ-INPUT INTO EXPORT-RECORD
               IF WS-SEQ-STATUS = '00'
                   WRITE EXPORT-RECORD
               END-IF
           END-PERFORM
           CLOSE SEQ-INPUT
           CLOSE IDX-OUTPUT
           STOP RUN.
EOF

    if ! $COBC -x $COBFLAGS $INCLUDES "$TMP_OUT/stage_export.cbl" -o "$TMP_OUT/STGEXP" 2>/dev/null; then
        echo "[FAILED]"
        echo "Failed to compile dataset staging helper." >&2
        exit 1
    fi

    export DD_SEQIN="$DATA_DIR/AWS.M2.CARDDEMO.EXPORT.DATA.PS"
    export DD_IDXOUT="$TMP_OUT/EXPORT.INDEXED.dat"
    if ! "$TMP_OUT/STGEXP" 2>/dev/null; then
        echo "[FAILED]"
        echo "Failed to stage sequential export dataset into indexed format." >&2
        exit 1
    fi

    export DD_EXPFILE="$TMP_OUT/EXPORT.INDEXED.dat"
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
    
    echo "[OK]"
fi

echo "All batch runtime verification tests passed successfully."
