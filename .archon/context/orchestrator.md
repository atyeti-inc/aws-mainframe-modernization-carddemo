# Orchestrator Context: aws-mainframe-modernization-carddemo

## 1. Project Profile
- **Project**: aws-mainframe-modernization-carddemo
- **Type**: Mainframe Monolith Reference Application
- **Summary**: Enterprise credit card management monolith (batch COBOL, online CICS/BMS, IMS, DB2, MQ, VSAM, assembler, and JCL) serving as AWS Mainframe Modernization migration benchmark.

## 2. Repository Topology & Dispatch Boundaries
- **Mode**: FORK_TO_UPSTREAM
- **Target Workspace (origin)**: `atyeti-inc/aws-mainframe-modernization-carddemo`
- **Upstream Source (upstream)**: `aws-samples/aws-mainframe-modernization-carddemo`
- **Base Branch**: `main`
- **Issue Tracker**: All planned tasks, epics, and work orders MUST map to `atyeti-inc/aws-mainframe-modernization-carddemo` (origin). Upstream tracking items are read-only references.

## 3. Orchestration & Gate Policy
- **Execution Target**: Autonomous workflows dispatch exclusively against local checkout and origin fork.
- **Promotion Flow (Fork Mode)**:
  1. Autonomous runs open PRs strictly against `origin:main`.
  2. Upstream promotion (`origin:main` -> `upstream:main`) is human-gated outside autonomous execution.
- **Scope Boundary**: Refusals/Out-of-Scope: Preserve mainframe source fidelity (COBOL, JCL, BMS, ASM). Reject blanket rewrites to Java, Node, or Python unless explicitly scoped to modernization submodules. Maintain IBM 80-column fixed layout and dataset integrity.
