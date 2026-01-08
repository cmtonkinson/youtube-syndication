# Task 000: Architecture Bootstrap (Power Six)

## Objective
Establish the architectural foundation for this project by producing the minimum
viable set of the **Power Six** architecture artifacts required to safely and
productively generate implementation tasks leading to the successful
implementation of this project.

Your task is to empower the rest of the project team to complete their tasks
both successfully and independently by reducing uncertainty with respect to the
design of the solution. Every project team member will need to make decisions
about how to complete their tasks; reducing uncertainty helps ensure alignment
across across roles and tasks.

## Required Artifacts

### Power Six
These are the **"Power Six"** artifacts: a minimal and forgiving collection of
architectural documentation which together yields a comprehensive understanding
of a technical solution.

These are the **Power Six** artifacts:
1. **User Personas** (recommended)
2. **Architecturally Significant Requirements (ASRs)** (required)
3. **Wardley Map** (recommended)
4. **Architecture Overview (arc42)** (required)
5. **C4 Diagrams** (recommended)
6. **Architectural Decision Records (ADRs)** (required)

The artifacts are listed not in order of importance, but rather the recommended
_chronological order_ in which they should be formalized.

_Note: You SHOULD consider creating the optional artifacts, but MAY choose to
omit/skip if the scope or complexity of the project do not justify their
production._

## Artifact Rules
- All artifacts MUST use the templates provided in `_governator/templates/`
- All artifacts MUST be written in markdown
- All artifacts MUST be stored in the `_governator/docs` directory
- Sections may not be removed
- Empty sections must be explicitly marked as intentionally omitted, with an
  explanation as to why.
- No implementation detail is allowed unless architecturally significant

## ADR Emission
If any decision:
- materially constrains future implementation, or
- eliminates viable alternatives, or
- commits to a technology, pattern, or platform

An ADR MUST be created using the ADR template.

## Definition of Done
This task is complete when:
- Required artifacts exist and are filled out
- Optional artifacts are either present or explicitly skipped with justification
- All significant decisions are momorialized as ADRs
- No feature or implementation tasks have been created

## Assignment

2026-01-08T21:02:34Z [governator]: Assigned to architect.

## Change Summary
- Added Power Six artifacts in `_governator/docs` (personas, ASRs, wardley map,
  arc42 overview).
- Created ADRs for the bash CLI pipeline, external toolchain dependencies, and
  file-based JSON state.
- Assumed a single-machine CLI scope and noted C4 diagrams as intentionally
  omitted due to limited component surface.
- Follow-up concern: confirm configuration schema and logging format during
  implementation planning.

## Review Result

2026-01-08T21:09:11Z [reviewer]: Decision: reject
2026-01-08T21:09:11Z [reviewer]: Comments:
2026-01-08T21:09:11Z [reviewer]: - Must fix: The architecture artifacts omit the requirement that source copies of videos may not be kept and only destination copies should remain (GOVERNATOR.md). This needs to be captured as a constraint or ASR because it materially affects storage and pipeline behavior.
2026-01-08T21:09:11Z [reviewer]: - Must fix: The default skip behavior for shorts and livestreams (GOVERNATOR.md: 'should be skipped by default, if possible') is not reflected in ASRs or arc42 constraints. Please document this default behavior explicitly.
2026-01-08T21:09:11Z [reviewer]: - Optional: ADR related task references point to _governator/task-assigned/000-architecture-bootstrap-architect.md which does not exist; consider updating to the correct task location for traceability.

## Change Summary
- Added an ASR for single-copy storage and clarified default shorts/livestream
  skipping in ASRs.
- Updated arc42 constraints to reflect default skip behavior and no-source-copy
  retention.
- Updated ADR related task references to the task-worked path.
- Assumption: Default shorts/livestream detection relies on metadata surfaced
  by yt-dlp where available.
- Follow-up concern: confirm reliable shorts/livestream indicators during
  implementation planning.

## Review Result

2026-01-08T21:13:47Z [reviewer]: Decision: approve
2026-01-08T21:13:47Z [reviewer]: Comments:
2026-01-08T21:13:47Z [reviewer]: - ASRs and arc42 now explicitly capture default shorts/livestream skipping and the single-copy storage policy, aligning with GOVERNATOR.md constraints.
2026-01-08T21:13:47Z [reviewer]: - ADRs reference the correct task-worked path for traceability.
