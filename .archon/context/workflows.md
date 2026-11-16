# Workflow Execution Context: aws-mainframe-modernization-carddemo

## 1. Governance & Dispatch Boundaries
- **Git Remotes**: `origin` = `atyeti-inc/aws-mainframe-modernization-carddemo` (Workspace target). `upstream` = `aws-samples/aws-mainframe-modernization-carddemo` (Upstream reference).
- **Zero-Leak Invariant**: Autonomous commands (`git push`, `gh pr create`) MUST target `origin` ONLY. Interacting with `upstream` beyond read-only fetching is strictly prohibited.
- **Benchmark Corpus Invariant**: CardDemo is an explicit migration stress-test benchmark for AWS Blu Age, Micro Focus, and OpenFrame, NOT a typical business application. Archaic idioms, varied coding styles, and unusual constructs are intentional parser fixtures. Work is strictly restricted to issues authored/posted by AWS maintainers.
- **Permitted File Extensions**: COBOL (`.cbl`, `.CBL`), Copybooks (`.cpy`, `.CPY`), JCL (`.jcl`, `.JCL`, `.prc`), BMS (`.bms`), Assembler (`.asm`, `.mac`), Control files (`.ctl`, `.csd`, `.ca7`, `.controlm`), Shell (`.sh`), Documentation (`.md`, `.txt`).
- **Prohibited Actions**: No synthetic throwaway test scripts (`.py`/`.sh`), no unrequested package managers, and no ad-hoc build shims or non-mainframe runtime additions.

## 2. COBOL Architecture & Source Standards

### IBM 80-Column Fixed Layout Invariant
All COBOL source must preserve standard IBM 80-column fixed format. Never introduce tab characters or free-format lines.
- **Cols 1–6**: Sequence Number area
- **Col 7**: Indicator area (`*` comment, `/` page eject, `-` continuation, `D` debugging)
- **Cols 8–11**: Area A (division, section, paragraph headers, 01/77 levels)
- **Cols 12–72**: Area B (statements, continuation, subordinate data levels)
- **Cols 73–80**: Identification / Program-ID comment area

### Source, Schema & Diff Hygiene
- **Identifier & Symbol Immutability (The Typo Rule)**: Variable names, copybook identifiers, and schema tokens—including apparent typos (e.g., `EXPIRAION`)—are frozen external contracts. Never "correct" or rename identifiers under the guise of spelling or cosmetic cleanup UNLESS specifically and explicitly directed by an AWS-posted issue work item. Unsolicited token renaming is strictly prohibited, as downstream migration tool parsers (Blu Age, Micro Focus, OpenFrame) and AST maps rely on exact token matching.
- **Fixed-Format Schema Sensitivity**: Copybooks, `FD`s, and record layouts define byte-precise fixed-width datasets for VSAM files. Byte boundaries, field lengths, and key offsets (e.g., IDCAMS `KEYS`) are immutable.
- **Surgical Scoping**: Zero gratuitous reformatting, cosmetic realignment, or whitespace churn on untouched lines. Diffs must isolate functional changes only.
- **Preserve Archaic Benchmark Idioms**: Do not refactor adjacent working legacy constructs (e.g., `ALTER/GO TO`, complex `REDEFINES`, unusual control flows). Only resolve concrete compilation or runtime execution blockers.
- **Fidelity Preservation**: Maintain mainframe source fidelity; reject wrappers or off-target language conversions.

### Copybook Directory Layout
- **Core CardDemo Copybooks**:
  - `app/cpy/`: Primary record layouts, commareas (`COCOM01Y`), message buffers (`CSMSG01Y`), date utilities (`CSDAT01Y`).
  - `app/cpy-bms/`: Symbolic screen map copybooks generated from BMS source (`COSGN00.CPY`, `COMEN01.CPY`, `COACTVW.CPY`).
- **Extension Module Copybooks**:
  - `app/app-authorization-ims-db2-mq/cpy/` and `cpy-bms/`: IMS PCBs, MQ buffers, authorization layouts, and BMS maps.
  - `app/app-transaction-type-db2/cpy/` and `cpy-bms/`: DB2 DCLGEN host structures (`CSDB2RPY`, `CSDB2RWY`) and BMS maps.

### Module Classification & Compilability
- **Batch COBOL Modules**:
  - Patterns: `app/cbl/CB*.cbl`, `app/cbl/CB*.CBL`, `app/cbl/CSUTLDTC.cbl`, `app/cbl/COBSWAIT.cbl`, and `app/app-authorization-ims-db2-mq/cbl/*.CBL`.
  - Characteristics: Standard batch programs reading sequential or VSAM indexed files; callable via JCL; locally compilable via GnuCOBOL.
  - Note: Modules with embedded SQL (`EXEC SQL`) or IMS DL/I calls (`EXEC DLI`) require external precompilers and cannot compile standalone with local `cobc`.
- **Online CICS COBOL Modules**:
  - Patterns: `app/cbl/CO*.cbl` (except `COBSWAIT.cbl`) and sub-application online modules.
  - Characteristics: Contain native `EXEC CICS` commands (`SEND`, `RECEIVE`, `RETURN`, `XCTL`), referencing CICS copybooks (`DFH*`) and runtime structures (`EIBCALEN`, `EIBAID`).
  - Compilation: Requires IBM CICS preprocessor/translator; not compilable standalone with local `cobc`.

## 3. Toolchain & Verification Contract

### Dialect & Compiler Flags
- **Target Dialect**: IBM Enterprise COBOL (target `IGYCRCTL` V6.3), simulated locally via GnuCOBOL 3.2.0 (`/usr/bin/cobc`).
- **Mandatory Flag Invariant**: `cobc -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms`
  - `-ftab-width=4` prevents copybook tab expansion from crossing column 72 and triggering truncation.

### Root Makefile Targets
The repository root `Makefile` standardizes build and test commands:
- **`make check`**: Validates syntax across all batch modules via `cobc -fsyntax-only $(COBFLAGS) $(INCLUDES)`.
- **`make all`**: Compiles all buildable batch COBOL modules into binaries in `build/`.
- **`make test`**: Runs syntax verification, compilation, binary output checks, and copybook integrity checks.
- **`make test-runtime`**: Executes batch dataset runtime I/O simulation against sample EBCDIC files (`.archon/scripts/test-batch-runtime.sh`).
- **`make clean`**: Removes `build/` and intermediate compilation artifacts.

### Verification Workflow & Pass Criteria
1. **Batch Syntax Check**: `cobc -fsyntax-only -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms app/cbl/<modified_program>.cbl` (must exit 0). Or run `make check`.
2. **Online CICS COBOL Validation**: Verify Area A/B column alignment, copybook integrity, and CICS syntax without standalone compilation.
3. **Data-Path Runtime I/O**: Mandatory when touching `FD`, `FILE-CONTROL`, file organization, dataset layouts, or copybook record layouts. Run `make test-runtime` (must exit 0 with zero runtime abends or File Status errors).
4. **Git Cleanliness**: All build outputs (`build/`, `*.o`, `*.so`), listings, and temp files must remain untracked via `.gitignore`.

## 4. Git & Contribution Hygiene
- **Branch Naming**: `issue-<id>-<brief-slug>`
- **Commit Format**: Conventional Commits (`fix: ...`, `feat: ...`, `docs: ...`).
- **DCO Signoff**: REQUIRED. All commits MUST include signoff (`git commit -s`):
  `Signed-off-by: Christopher Caldwell <Christopher.Caldwell@Atyeti.com>`
- **License / Header**: Apache-2.0. Retain Amazon copyright headers on existing files; add Apache-2.0 SPDX header if introducing new files.
- **PR Target**: `origin` -> `main`.

## 5. Upstream PR & Reviewer Acceptance Protocol

### The Upstream Environment & Viability Imperative
- **Upstream Reality**: `aws-samples` maintainers have merged only 7 PRs in the project's lifetime and are inundated with 25+ automated AI spam PRs proposing Spring Boot/React rewrites. Maintainers instantly close or ignore unsolicited rewrites, cosmetic churn, and AI-generated noise.
- **Upstream-Ready Standard**: Every PR we open on `origin` must be engineered as our absolute best shot at an upstream contribution. It must cut through the AI spam noise by being surgical, pristine, byte-exact, and indistinguishable from expert human mainframe engineering.

### Mandatory PR Template & Legal Attribution
Every PR body MUST follow this structure and include the mandatory AWS contribution clause:
```markdown
*Issue #, if available:*
Fixes #<issue_number>

*Description of changes:*
<Concise, technical summary of the fix or feature>

By submitting this pull request, I confirm that you can use, modify, copy, and redistribute this contribution, under the terms of your choice.
```

### PR Evidence & Verification Standards
- **Grounded Verification Reporting**: State concrete compiler flags (`cobc -std=ibm`), 80-column alignment checks, and IDCAMS catalog cross-references. Avoid vague "tested" claims.
- **Byte-Exact Layout Proof**: When modifying copybooks, `FD`s, or dataset structures, explicitly document that total record lengths and key offsets (IDCAMS `KEYS`) remain unchanged.
- **Runtime Dataset Simulation Reports**:
  - *When to Include*: Mandatory whenever a PR touches `FD`, `FILE-CONTROL`, file organization, copybooks defining record layouts, or IDCAMS JCL cluster definitions. Report execution environment (`DD_*` mapping with GnuCOBOL), target sample dataset (`app/data/EBCDIC/...`), record counts processed, exit code 0, and status 00.
  - *When to Omit*: Do not include dataset runtime reports for online CICS programs (`CO*.cbl`), BMS maps, copybook comment/whitespace cleanup, or pure internal procedural logic changes where file structures and dataset contracts are untouched.

### Anti-AI Triage Filtering Rules
- **No Emojis or Marketing Badges**: Ban all emojis (🚀, 📋, 🤖), decorative badges, or execution run IDs in PR titles, commit messages, and PR descriptions.
- **No Agent Signatures**: Omit automated attribution ("Generated by...", bot watermarks, LLM disclaimers).
- **Factual Mainframe Tone**: Terse, objective, and focused on compiler diagnostics, dataset contracts, and z/OS behavior without AI summary fluff.
