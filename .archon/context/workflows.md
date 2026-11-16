# Workflow Execution Context: aws-mainframe-modernization-carddemo

## 1. Boundary & Remotes Invariant
- **Git Remotes**: `origin` = `atyeti-inc/aws-mainframe-modernization-carddemo` (Workspace target). `upstream` = `aws-samples/aws-mainframe-modernization-carddemo`.
- **Zero-Leak Invariant**: Autonomous commands (`git push`, `gh pr create`) MUST target `origin` ONLY. Interacting with `upstream` beyond read-only fetching is strictly prohibited.
- **Permitted Languages**: COBOL (`.cbl`, `.CBL`), Copybooks (`.cpy`, `.CPY`), JCL (`.jcl`, `.JCL`, `.prc`), BMS (`.bms`), Assembler (`.asm`, `.mac`), Control files (`.ctl`, `.csd`, `.ca7`, `.controlm`), Shell (`.sh`), Markdown (`.md`).
- **Allowed Extensions**: `.cbl`, `.CBL`, `.cpy`, `.CPY`, `.jcl`, `.JCL`, `.prc`, `.bms`, `.asm`, `.mac`, `.ctl`, `.csd`, `.ca7`, `.controlm`, `.sh`, `.md`, `.txt`.
- **Prohibited Actions**: No synthetic throwaway test scripts (`.py`/`.sh`), no unrequested package managers, no ad-hoc build shims or non-mainframe runtime additions.

## 2. COBOL Architecture & Repository Layout

### Dialect & Toolchain
- **COBOL Dialect**: IBM Enterprise COBOL (target `IGYCRCTL` V6.3, simulated locally via GnuCOBOL 3.2.0 with `-std=ibm`).
- **Compiler / Runtimes**: GnuCOBOL 3.2.0 (`/usr/bin/cobc`), Bun 1.3.11 (`/usr/local/bin/bun`).
- **Formatting Standard**: IBM standard 80-column fixed format:
  - Columns 1-6: Sequence Number area
  - Column 7: Indicator area (`*` comment, `/` page eject, `-` continuation, `D` debugging)
  - Columns 8-11: Area A (division, section, paragraph headers, 01/77 levels)
  - Columns 12-72: Area B (statements, continuation, subordinate data levels)
  - Columns 73-80: Identification / Program-ID comment area
- **Required Compiler Flags**: `cobc -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms`
  - `-ftab-width=4` is mandatory: Prevents lines in copybooks containing tabs (e.g., `app/cpy/CUSTREC.cpy`) from being expanded beyond column 72 and truncated by fixed-format rules.

### Copybook Directories
- **Core CardDemo Copybooks**:
  - `app/cpy/`: Primary record layouts, common commareas (`COCOM01Y`), error messages (`CSMSG01Y`), date formats (`CSDAT01Y`), utility buffers.
  - `app/cpy-bms/`: Symbolic screen map copybooks generated from BMS source definitions (e.g., `COSGN00.CPY`, `COMEN01.CPY`, `COACTVW.CPY`).
- **Extension Module Copybooks**:
  - `app/app-authorization-ims-db2-mq/cpy/` and `cpy-bms/`: IMS PCBs, MQ buffers, authorization layouts, and BMS maps.
  - `app/app-transaction-type-db2/cpy/` and `cpy-bms/`: DB2 DCLGEN host structures (`CSDB2RPY`, `CSDB2RWY`) and BMS maps.

### Batch vs Online Module Classification
- **Batch COBOL Modules**:
  - Source patterns: `app/cbl/CB*.cbl`, `app/cbl/CB*.CBL`, `app/cbl/CSUTLDTC.cbl`, `app/cbl/COBSWAIT.cbl`, and `app/app-authorization-ims-db2-mq/cbl/*.CBL`.
  - Characteristics: Standard batch programs reading sequential or VSAM indexed files; callable via JCL; locally compilable with GnuCOBOL. Programs containing embedded SQL (`EXEC SQL`) or IMS DL/I calls (`EXEC DLI`) require external database precompilers and cannot be compiled standalone via standard `cobc`.
- **Online CICS COBOL Modules**:
  - Source patterns: `app/cbl/CO*.cbl` (except batch wait utility `COBSWAIT.cbl`) and sub-application online modules.
  - Characteristics: Transaction processing programs containing native `EXEC CICS` commands (`SEND`, `RECEIVE`, `RETURN`, `XCTL`, `WRITEQ`), referencing CICS system copybooks (`DFH*`) and runtime structures (`EIBCALEN`, `EIBAID`).
  - Compilation requirement: Requires IBM CICS preprocessor/translator (`CICS` option on `IGYCRCTL`) and CICS system libraries. Not compilable standalone via local `cobc`.

## 3. Validation Contract & Makefile Targets

### Root Makefile Specification
The repository root `Makefile` provides standardized targets for building and validating CardDemo COBOL assets:
- **`make all`**: Compiles all buildable batch COBOL modules into object files (`.o`) in `build/`.
- **`make check`**: Performs syntax and semantic validation across batch COBOL modules using `cobc -fsyntax-only -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms`.
- **`make test`**: Runs full validation suite: checks syntax, compiles modules, validates object binary creation, and verifies copybook integrity.
- **`make clean`**: Removes `build/` directory and any intermediate compilation artifacts.

### Verification Commands (Must exit code 0)
- **Primary (Batch COBOL)**:
  `cobc -fsyntax-only -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms app/cbl/<modified_program>.cbl`
- **Secondary (Online CICS COBOL)**:
  Verify column formatting (cols 8-72), copybook integrity in `app/cpy` and `app/cpy-bms`, and command syntax structure against CICS TS specifications.
- **Whole Suite Check**:
  Run `make check` (or direct batch verification loop when make is unavailable in host environment).

### Pass Criteria
- Zero syntax errors on modified batch COBOL programs.
- Exact fixed-format 80-column alignment preserved.
- Zero untracked artifacts in git: all intermediate compilation outputs (`build/`, `*.o`, `*.so`), temporary files, and internal agent directories (`.yeti/`, `.archon/`) MUST be registered in `.git/info/exclude`.

## 4. Git & PR Authoring Discipline
- **Branch Naming**: `issue-<id>-<brief-slug>`
- **Commit Format**: Conventional Commits (`fix: ...`, `feat: ...`, `docs: ...`).
- **DCO / Signoff**: REQUIRED. All commits MUST include `Signed-off-by: Christopher Caldwell <Christopher.Caldwell@Atyeti.com>` (`git commit -s`). Contributor: Christopher Caldwell / Atyeti Inc.
- **License / Header**: Apache-2.0. Retain Amazon copyright headers on existing files; add Apache-2.0 SPDX header if introducing new files.
- **PR Target**: `origin` -> `main`.
- **PR Body Requirements**:
  - Reference `Closes #<origin_issue_id>`. Upstream reference if applicable: `Upstream Ref: aws-samples/aws-mainframe-modernization-carddemo#<id>`.
  - Required Upstream Contribution Clause:
    `By submitting this pull request, I confirm that you can use, modify, copy, and redistribute this contribution, under the terms of your choice.`
