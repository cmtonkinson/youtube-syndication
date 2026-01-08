# Task 000: Blocked Task Analysis (Planner)

## Objective
Review blocked tasks for additional context, clarification, or disambiguation.
If a task can be unblocked, requeue it with a clear note. If it cannot, leave
it blocked and record your analysis.

## Input
- Blocked tasks in `_governator/task-blocked/`
- Any relevant artifacts in `_governator/docs/`

## Output
For each blocked task (skip tasks that already include an "Unblock Note" or
"Unblock Analysis" section):
1. If you can resolve the block:
   - Move the task to `_governator/task-backlog/`
   - Add an `## Unblock Note` section to the task
   - Explain what changed, or what new information, led to the unblocking
2. If you cannot resolve the block:
   - Append an `## Unblock Analysis` section to the blocked task explaining why
     it should remain blocked and what information is missing.
   - Do not unblock the task

Only one unblock attempt is allowed per task. If a task is re-blocked after an
unblock, leave it blocked.

## Rules
- You MAY make appropriate and minimal adjustments to the scope, requirements,
  or parameters of a task in order to unblock it.
- You MAY make appropriate and minimal modifications to project documentation
  (including architectural documentation, milestones or epics) in order to
  unblock a task, so long as they are not major/sweeping/thematic changes and do
  not materially alter the nature of the task.
- Your job is to unblock the task by any reasonable means, so long as those
  means do not violate the overall governance of the project or sacrifice any
  key goals of the project.

## Assignment

2026-01-08T21:41:51Z [governator]: Assigned to planner.

## Blocked Tasks

2026-01-08T21:41:51Z [governator]: - 004-config-loading-generalist: 2026-01-08T21:41:45Z [governator]: Missing worker branch origin/worker/generalist/004-config-loading-generalist for 004-config-loading-generalist.
2026-01-08T21:41:51Z [governator]: - 008-serialized-download-generalist: reason unavailable

## Change Summary

- Requeued tasks 004 and 011 with unblock notes after confirming they were
  blocked only by missing worker branches.
- Documented missing review rationale for task 008 and left it blocked.
