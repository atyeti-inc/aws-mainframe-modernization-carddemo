# Orchestrator Context: aws-mainframe-modernization-carddemo

## 1. Project Profile & Mission
- **Project**: aws-mainframe-modernization-carddemo
- **Type**: Mainframe Migration Benchmark & Stress-Test Corpus
- **Mission**: Enterprise credit card management monolith (batch COBOL, online CICS/BMS, IMS, DB2, MQ, VSAM, Assembler, and JCL) whose explicit purpose is to stress-test and benchmark AWS and partner mainframe migration tools (e.g., AWS Blu Age, Micro Focus, OpenFrame). It is a test corpus, NOT a conventional evolving application.

## 2. Repository Topology & Upstream Dynamics
- **Mode**: FORK_TO_UPSTREAM
- **Target Workspace (origin)**: `atyeti-inc/aws-mainframe-modernization-carddemo`
- **Upstream Source (upstream)**: `aws-samples/aws-mainframe-modernization-carddemo`
- **Base Branch**: `main`
- **Issue Intake Policy**: Autonomous work is strictly restricted to addressing verified issues posted by AWS maintainers (`aws-samples`). Self-invented bugs, unprompted cosmetic cleanup, or uncommissioned enhancements are out of scope.
- **Upstream Reality**: `aws-samples` has merged only 7 PRs lifetime (last in late 2022) and is inundated with 25+ unreviewed automated AI spam PRs proposing Spring Boot/React rewrites. Maintainers instantly close or ignore unsolicited rewrites, cosmetic churn, and AI-generated noise.
- **Upstream Viability Mandate**: While autonomous execution runs strictly target `origin:main`, every PR must be engineered to the rigorous standard of an upstream contribution. We must take our absolute best shot at upstream acceptance by ensuring all work is surgical, pristine, byte-exact, and indistinguishable from expert human mainframe systems engineering.

## 3. Orchestration Boundaries & Scope Refusals
- **Execution Target**: Autonomous workflows dispatch exclusively against local checkout and `origin:main`. Upstream promotion (`origin:main` -> `upstream:main`) is human-gated outside autonomous loops.
- **Identifier & Schema Immutability**:
  - Mainframe copybooks and COBOL structures define byte-precise fixed-width records for VSAM datasets and downstream migration parsers.
  - Variable names, copybook identifiers, and schema tokens—including apparent typos (e.g., `EXPIRAION`)—are frozen API contracts. Autonomous tasks MUST REFUSE renaming identifiers or "fixing typos" unless specifically and explicitly requested by an AWS-posted issue work item. Unsolicited renaming is strictly prohibited.
- **Benchmark Corpus Preservation**:
  - Archaic legacy idioms (`ALTER/GO TO`, complex `REDEFINES`, unusual control flow) are deliberate migration test fixtures. Refuse refactoring working legacy code.
  - Work is strictly limited to resolving verified compile/runtime blockers or explicitly scoped benchmark enhancements.
- **Language & Runtime Refusals**:
  - Reject all blanket rewrites to Java, Node, Python, Spring Boot, or modern web frameworks.
  - Strictly preserve IBM 80-column fixed layout, dataset integrity, and original mainframe runtime semantics.

## 4. Mainframe Systems Investigation & Root Cause Protocol

### Contract Authority Hierarchy
Declarative infrastructure (JCL, IDCAMS, DDL, CSD) and schema definitions are higher-order authorities than raw repository seed files (`.PS`) or local runner harnesses. When components disagree, subordinate artifacts must be reconciled to the infrastructure contract—never degrade the system contract to fit local test mocks.

### The Mainframe Triangulation Mandate (COBOL ↔ JCL ↔ Dataset)
Mainframe programs cannot be diagnosed by inspecting COBOL source in isolation. Every investigation touching files, datasets, or compilation errors MUST triangulate across all three surfaces before forming a hypothesis:
1. **COBOL Definition**: `SELECT ... ORGANIZATION`, `ACCESS MODE`, `RECORD KEY`, and `FD` record descriptions.
2. **JCL & IDCAMS Catalog**: The job stream (`app/jcl/<name>.jcl`), IDCAMS `DEFINE CLUSTER` parameters (`INDEXED`, `KEYS(len, offset)`, `RECORDSIZE`), and all allocated DD statements.
3. **Dataset Topology**: How the dataset is structured on disk vs. how seed data is staged.

### The Mainframe Repository Seed Rule (.PS vs. VSAM)
- Git cannot store native mainframe VSAM clusters (which consist of dual data/index components and VTOC metadata).
- ALL raw test datasets in `app/data/EBCDIC/` are distributed as Physical Sequential (`.PS`) flat files.
- On z/OS, IDCAMS `REPRO` unpacks `.PS` sequential files into indexed VSAM (`.KSDS`) clusters defined by JCL.
- **NEVER** infer that a COBOL program's `ORGANIZATION` should be `SEQUENTIAL` simply because the repository data file has a `.PS` extension. Always verify the IDCAMS cluster definition in JCL.

### Anti-Symptom-Treating Invariant (No Feature-Stripping)
When a compiler or preprocessor complains about an indexed key (e.g., `'KEY-NAME' is not defined`), assistants MUST NOT "fix" the error by removing `ORGANIZATION IS INDEXED` and demoting the file to `SEQUENTIAL`. Assistants must locate the structural error (e.g., key declared in `WORKING-STORAGE` instead of within the `FD` record description).

