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
- **Primary (Batch COBOL Syntax)**:
  `cobc -fsyntax-only -std=ibm -ftab-width=4 -I app/cpy -I app/cpy-bms app/cbl/<modified_program>.cbl`
- **Data-Path Runtime I/O (Mandatory for file/dataset changes)**:
  When modifying `FD` entries, `FILE-CONTROL`, `ORGANIZATION`, copybooks defining record structures, or dataset layouts, execute:
  `make test-runtime` (or `bash .archon/scripts/test-batch-runtime.sh`).
  Must exit code 0 with zero runtime abends or File Status errors.
- **Secondary (Online CICS COBOL)**:
  Verify column formatting (cols 8-72), copybook integrity in `app/cpy` and `app/cpy-bms`, and command syntax structure against CICS TS specifications.
- **Whole Suite Check**:
  Run `make check` (or direct batch verification loop when make is unavailable in host environment).

### Pass Criteria
- Zero syntax errors on modified batch COBOL programs.
- Exact fixed-format 80-column alignment preserved.
- Zero runtime abends or File Status errors under `make test-runtime` for file/dataset modifications.
- Zero untracked artifacts in git: all intermediate compilation outputs (`build/`, `*.o`, `*.so`), temporary files, and internal agent directories (`.yeti/`, `.archon/`) MUST be registered in `.git/info/exclude`.

## 4. Git & PR Authoring Discipline
- **Branch Naming**: `issue-<id>-<brief-slug>`
- **Commit Format**: Conventional Commits (`fix: ...`, `feat: ...`, `docs: ...`).
- **DCO / Signoff**: REQUIRED. All commits MUST include `Signed-off-by: Christopher Caldwell <Christopher.Caldwell@Atyeti.com>` (`git commit -s`). Contributor: Christopher Caldwell / Atyeti Inc.
- **License / Header**: Apache-2.0. Retain Amazon copyright headers on existing files; add Apache-2.0 SPDX header if introducing new files.
- **PR Target**: `origin` -> `main`.

## 5. Upstream PR & Reviewer Acceptance Protocol (aws-samples)
Maintainers are veteran AWS mainframe modernization engineers. PRs must adhere strictly to repository governance, pristine 80-column layout, and human engineering standards to prevent automated triage rejection.

### Mandatory PR Template & Legal Attribution
Every PR description MUST follow this structure and include the mandatory AWS contribution clause:
```markdown
*Issue #, if available:*
Fixes #<issue_number>

*Description of changes:*
<Concise, technical summary of the fix or feature>

By submitting this pull request, I confirm that you can use, modify, copy, and redistribute this contribution, under the terms of your choice.
```

### Mainframe Source & Diff Hygiene
- **IBM Fixed Layout Invariant**: Maintain strict 80-column fixed layout (Cols 1–6 sequence, Col 7 indicator, Cols 8–11 Area A, Cols 12–72 Area B). Never introduce tabs or free-form lines.
- **Surgical Scoping**: Zero gratuitous reformatting, cosmetic realignment, or whitespace churn on untouched lines. Diffs must be isolated solely to functional changes.
- **Fidelity Preservation**: Do not introduce off-target rewrites (e.g., converting COBOL/JCL to modern runtime wrappers) unless explicitly scoped.
- **Preserve Archaic Benchmark Idioms**: Do not refactor adjacent legacy constructs (e.g., `ALTER/GO TO`, complex `REDEFINES`). They are intentional parser test fixtures for migration tools.

### PR Evidence & Verification Standards
- **Byte-Exact Layout Proof**: When modifying copybooks, FDs, or dataset structures, the PR description must explicitly document that total record lengths and key offsets (e.g., IDCAMS `KEYS`) remain unchanged.
- **Grounded Verification Reporting**: State exact verification evidence in the PR body (e.g., specific `cobc -std=ibm` compiler flags, 80-column layout boundary checks, IDCAMS catalog cross-references). Avoid vague "fully tested" claims.
- **Runtime Dataset Verification Reporting (When & How to Include)**:
  - *When to Include*: Mandatory whenever a PR touches file descriptions (`FD`), `FILE-CONTROL`, file organization, copybooks defining record layouts, or IDCAMS JCL cluster definitions.
  - *Format*: Report exact, grounded simulation facts plainly without off-platform jargon or hand-waving:
    - Specify execution environment: Standalone binary execution via GnuCOBOL DD environment variable mapping (`DD_*`).
    - Specify target dataset: Shipped sample dataset path (e.g., `app/data/EBCDIC/AWS.M2.CARDDEMO.EXPORT.DATA.PS`).
    - Specify factual outcome: Exact record counts ingested/dispatched, exit code 0, and zero File Status errors.
  - *When NOT to Include*: Do NOT include dataset runtime reports for online CICS programs (`CO*.cbl`), BMS maps, copybook comment/whitespace cleanup, or pure internal arithmetic/procedural logic changes where file structures and dataset contracts are untouched.

### Anti-AI Filtering Rules
- **No Emojis or Marketing Badges**: Ban all emojis (🚀, 📋, 🤖), decorative icons, or run IDs in PR titles, commit messages, and PR bodies.
- **No Agent Signatures**: Omit automated attribution ("Generated by...", bot watermarks, LLM disclaimers).
- **Factual Mainframe Tone**: Keep PR prose terse, factual, and focused on compiler diagnostics, dataset contracts, and z/OS behavior without AI summary fluff.

