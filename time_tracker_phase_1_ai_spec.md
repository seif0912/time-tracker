# Time Tracker — Phase 1 Development Specification

> **Phase:** 1 — V0.1 Core Time Tracker  
> **Goal:** Build a reliable, functional local-first time tracker.  
> **UI rule:** Phase 1 uses minimal functional UI. The supplied reference screenshot represents the intended polished Phase 2 direction.

## AI Agent Rules

1. Inspect the existing codebase before changing anything.
2. Preserve the Phase 0 architecture unless a change is necessary.
3. Work phase-by-phase and feature-by-feature.
4. Do not implement Phase 2+ features unless explicitly requested.
5. Keep UI, controllers/state, business logic, repositories, and infrastructure separated.
6. Never access Drift directly from presentation widgets.
7. Use Riverpod consistently with the existing architecture.
8. Prefer local-first behavior.
9. Preserve historical session data.
10. Do not use duplicated totals as the primary source of truth; derive totals from sessions where practical.
11. The timer must be timestamp-based. `Timer.periodic()` is only a UI refresh mechanism.
12. Never allow more than one active timer.
13. Handle app lifecycle/backgrounding explicitly.
14. Add tests for important business logic, persistence, and timer behavior.
15. Run `flutter analyze` and relevant `flutter test` commands after meaningful changes.
16. Never manually edit generated Drift files; use migrations/regeneration when needed.
17. Avoid unnecessary dependencies.
18. Never expose API keys or secrets in the Flutter client.
19. Before completing a task, report changed files, implementation, tests, and remaining issues.
20. If this document and the code disagree, inspect the code first. Update the document when an intentional implementation change is made.

---

# 1. Product Definition

The core user loop is:

```text
Create Task → Start Timer → Work → Pause/Resume → Stop
→ Save Time Session → View Dashboard/History
```

Architecture:

```text
Flutter UI
    ↓
Riverpod Controllers / State
    ↓
Repositories / Services
    ↓
Drift / SQLite
```

Timer flow:

```text
Timer UI
   ↓
TimerController
   ↓
TimerState
   ↓
TimeEntryRepository
   ↓
TimeEntries
```

---

# 2. Authentication

## Goal

Allow account access while preserving a clear local/guest strategy.

### Checklist

- [ ] Sign up
- [ ] Login
- [ ] Logout
- [ ] Password reset
- [ ] Guest/local mode decision
- [ ] User profile

### User stories

- **Sign up:** As a new user, I want to create an account so that I have a persistent identity.
- **Login:** As an existing user, I want to log in so that I can access my account.
- **Logout:** As a user, I want to log out so that access to my account is protected.
- **Password reset:** As a user who forgot my password, I want to reset it so that I can regain access.
- **Guest/local mode:** As a user, I want to use core tracking without unnecessary account friction if local mode is supported.
- **Profile:** As a user, I want to view/edit basic profile information.

### Acceptance criteria

- Authentication state is centralized.
- Auth errors do not crash the app.
- Secrets are never stored in source code.
- Login/logout behavior for local data is explicitly defined.

---

# 3. Tasks

## Goal

Let users create, organize, and manage trackable tasks.

### Checklist

- [ ] Create task
- [ ] Edit task
- [ ] Delete task
- [ ] Archive task
- [ ] Restore task
- [ ] Task name
- [ ] Task icon
- [ ] Task color
- [ ] Task category
- [ ] Favorite task
- [ ] Task search
- [ ] Task sorting

### Architecture

```text
TasksScreen
    ↓
TaskController
    ↓
TaskRepository
    ↓
Drift / SQLite
    ↓
Tasks
```

### User stories

- **Create:** As a user, I want to create a task with a name so that I can track time against it.
- **Edit:** As a user, I want to edit task information so that it stays accurate.
- **Delete:** As a user, I want to delete a task I no longer need.
- **Archive:** As a user, I want to archive a task without losing its history.
- **Restore:** As a user, I want to restore an archived task.
- **Metadata:** As a user, I want icons, colors, and categories to distinguish tasks.
- **Favorite:** As a user, I want to favorite important tasks for quick access.
- **Search:** As a user, I want to search tasks quickly.
- **Sort:** As a user, I want to sort tasks according to my workflow.

### Acceptance criteria

- Task names cannot be empty.
- Tasks have stable IDs.
- Archived tasks are excluded from the normal active list.
- Editing task metadata does not alter historical time.
- Deletion behavior for historical sessions is explicitly defined.
- Search and sorting do not create duplicate records.

---

# 4. Timer

## Goal

Provide a reliable stopwatch for exactly one task at a time.

### Checklist

- [ ] Start timer
- [ ] Pause timer
- [ ] Resume timer
- [ ] Stop timer
- [ ] Switch between tasks
- [ ] Prevent multiple active timers
- [ ] Timer persistence
- [ ] Background timer
- [ ] App restart recovery
- [ ] Device sleep handling
- [ ] Timer accuracy testing
- [ ] Active timer notification
- [ ] Timer state synchronization

## Timer state

Conceptually:

```text
TimerState
├── status: idle | running | paused
├── taskId
├── sessionId
├── startedAt
├── currentSegmentStartedAt
├── accumulatedSeconds
└── currentElapsedSeconds
```

The exact implementation must follow the existing codebase.

## Critical rule

Elapsed time must be derived from timestamps:

```dart
DateTime.now().difference(segmentStartedAt)
```

Do **not** make this authoritative:

```dart
elapsedSeconds += 1;
```

A periodic timer can refresh the UI, but callback count is not the source of truth.

### Start — user story

> As a user, I want to start tracking a task so that the app records how long I work on it.

Acceptance:
- A task is required.
- Only one timer can run.
- Start timestamp is recorded.
- Elapsed time is accurate.

### Pause — user story

> As a user, I want to pause tracking so that paused time is not counted.

Behavior:

```text
RUNNING → calculate current segment → accumulate → PAUSED
```

### Resume — user story

> As a user, I want to resume a paused timer so that I can continue tracking the same task.

Behavior:

```text
PAUSED → new segment timestamp → RUNNING
```

### Stop — user story

> As a user, I want to stop tracking so that my completed work is saved as a time session.

Behavior:

```text
RUNNING/PAUSED
      ↓
calculate final duration
      ↓
create completed TimeEntry
      ↓
clear active timer
      ↓
refresh dependent state
```

A failed save must not silently lose tracked time.

### Switch task — user story

> As a user, I want to switch to another task without losing the time already tracked.

Recommended behavior:

```text
Task A running
      ↓
switch
      ↓
finalize Task A tracked segment/session
      ↓
start Task B
```

### Multiple timers

Invariant:

```text
activeTimerCount <= 1
```

This must be enforced in business logic, not only by UI button visibility.

---

# 5. Timer Persistence & Lifecycle

## Goal

Keep timer behavior accurate across app lifecycle changes.

### Checklist

- [ ] Timer persistence
- [ ] Background timer
- [ ] App restart recovery
- [ ] Device sleep handling
- [ ] Timer accuracy testing
- [ ] Timer state synchronization

### User stories

- **Persistence:** As a user, I want my active timer to survive temporary lifecycle changes.
- **Background:** As a user, I want tracking to remain accurate when the app is backgrounded.
- **Restart:** As a user, I want an active timer recovered after reopening the app.
- **Sleep:** As a user, I want device sleep to have no negative effect on elapsed-time accuracy.

### Acceptance criteria

Elapsed duration after lifecycle interruptions is calculated from timestamps, not timer ticks.

---

# 6. Time Sessions

## Goal

Persist completed tracking periods as historical records.

### Checklist

- [ ] Create session automatically
- [ ] Save start timestamp
- [ ] Save end timestamp
- [ ] Calculate duration
- [ ] Edit session
- [ ] Delete session
- [ ] Manual time entry
- [ ] Session history
- [ ] Session grouping by day

### Data concept

```text
TimeEntry
├── id
├── taskId
├── startedAt
├── endedAt
├── durationSeconds
├── manual
└── createdAt
```

### User stories

- **Automatic session:** As a user, I want stopping a timer to automatically save the tracked period.
- **Manual entry:** As a user, I want to enter time tracked outside the app.
- **Edit:** As a user, I want to correct an historical session.
- **Delete:** As a user, I want to remove an incorrect session.
- **History:** As a user, I want to see previous sessions.
- **Grouping:** As a user, I want sessions grouped by day.

### Acceptance criteria

- Duration is non-negative.
- End time cannot precede start time.
- Manual sessions are identifiable.
- Editing updates the existing record.
- Deletion updates derived totals correctly.

---

# 7. Dashboard

## Goal

Give users a basic overview of tracked time.

### Checklist

- [ ] Today's total
- [ ] Weekly total
- [ ] Today's tasks
- [ ] Recent sessions
- [ ] Task time totals
- [ ] Basic daily chart
- [ ] Active timer card

### User stories

- **Today's total:** As a user, I want to see how much time I tracked today.
- **Weekly total:** As a user, I want to see how much time I tracked this week.
- **Today's tasks:** As a user, I want to see what I worked on today.
- **Recent sessions:** As a user, I want quick access to recent sessions.
- **Task totals:** As a user, I want to know how much time I spent on each task.
- **Chart:** As a user, I want a simple visual representation of daily time.
- **Active timer:** As a user, I want the current timer visible from the dashboard.

### Architecture

```text
TimeEntries
    ↓
Queries / Aggregation
    ↓
Dashboard Controller
    ↓
Dashboard State
    ↓
Dashboard UI
```

Prefer deriving totals from TimeEntries rather than maintaining redundant totals.

---

# 8. History

## Goal

Let users inspect and correct previous tracked time.

### Checklist

- [ ] Daily history
- [ ] Weekly history
- [ ] Session details
- [ ] Date navigation
- [ ] Edit historical session

### User stories

- **Daily:** As a user, I want to inspect all tracked time for a day.
- **Weekly:** As a user, I want to review tracked time across a week.
- **Details:** As a user, I want to inspect one session.
- **Navigation:** As a user, I want to move between dates.
- **Edit:** As a user, I want to correct a previous session without creating a duplicate.

---

# 9. Notifications

## Goal

Keep users aware of timer state and provide basic reminders.

### Checklist

- [ ] Timer running notification
- [ ] Timer stop notification
- [ ] Basic reminder
- [ ] Notification permission handling

### User stories

- **Running notification:** As a user, I want to know when a timer is running so I don't leave it running accidentally.
- **Stop notification:** As a user, I want confirmation when tracking stops.
- **Reminder:** As a user, I want optional reminders to track time.
- **Permission:** As a user, I want to understand why notification permission is needed.

Notifications reflect timer state; they are never the source of truth.

---

# 10. Recommended Implementation Order

Do not implement Phase 1 randomly.

## Step 1 — Tasks

- [ ] Create task
- [ ] Task list
- [ ] Edit task
- [ ] Archive
- [ ] Restore
- [ ] Delete
- [ ] Metadata
- [ ] Favorite
- [ ] Search
- [ ] Sorting

## Step 2 — Timer foundation

- [ ] TimerState
- [ ] TimerController
- [ ] Start
- [ ] Pause
- [ ] Resume
- [ ] Stop
- [ ] Prevent multiple timers

## Step 3 — Session persistence

- [ ] TimeEntry creation
- [ ] Start/end timestamps
- [ ] Duration calculation
- [ ] History
- [ ] Manual entries
- [ ] Edit
- [ ] Delete

## Step 4 — Lifecycle reliability

- [ ] Active timer persistence
- [ ] Background behavior
- [ ] Restart recovery
- [ ] Sleep handling
- [ ] Accuracy tests

## Step 5 — Dashboard

- [ ] Today's total
- [ ] Weekly total
- [ ] Today's tasks
- [ ] Recent sessions
- [ ] Task totals
- [ ] Basic chart
- [ ] Active timer card

## Step 6 — History

- [ ] Daily history
- [ ] Weekly history
- [ ] Session details
- [ ] Date navigation
- [ ] Historical editing

## Step 7 — Notifications

- [ ] Permission handling
- [ ] Running notification
- [ ] Stop notification
- [ ] Basic reminders

## Step 8 — Authentication

Implement according to the selected local/guest/account strategy.

## Step 9 — Testing

- [ ] Unit tests
- [ ] Timer tests
- [ ] Database tests
- [ ] Repository tests
- [ ] Widget tests
- [ ] Integration tests

---

# 11. Phase 1 Definition of Done

A user must be able to:

```text
Create task
   ↓
Start
   ↓
Pause
   ↓
Resume
   ↓
Stop
   ↓
Session saved
   ↓
Close/reopen app
   ↓
History remains correct
   ↓
Dashboard totals remain correct
```

And:

- [ ] No overlapping active timers
- [ ] Accurate background/sleep behavior
- [ ] Active timer recovery after restart
- [ ] Persistent historical sessions
- [ ] Manual entries
- [ ] Session correction/deletion
- [ ] Correct daily/weekly totals
- [ ] Correct notifications
- [ ] Authentication works if included in V0.1
- [ ] Relevant tests pass
- [ ] `flutter analyze` passes

---

# 12. Out of Scope

Do not implement these in Phase 1 unless explicitly requested:

- Final visual redesign
- Glass/gradient visual polish
- Advanced animations
- Projects
- Project budgets/estimates
- Goals
- Advanced analytics
- Insight engine
- AI Time Coach
- AI chat/recommendations
- Payments/subscriptions/paywalls
- Full cloud synchronization
- External integrations
- Home-screen widgets
- Automation
- Idle detection
- Smart reminders

The reference screenshot is the **Phase 2 visual target**, not the Phase 1 implementation target.

---

# 13. AI Task Template

Use this template for individual implementation requests:

```text
PHASE:
Phase 1 — V0.1 Core Time Tracker

TASK:
[One feature]

GOAL:
[What the user should be able to do]

USER STORY:
As a [user], I want [action], so that [benefit].

REQUIREMENTS:
- [requirement]
- [requirement]

CONSTRAINTS:
- Preserve existing architecture.
- Do not modify unrelated features.
- Do not implement future-phase functionality.
- Keep UI functional and minimal.

IMPLEMENTATION PROCESS:
1. Inspect existing relevant files.
2. Identify affected state/controller/repository/database layers.
3. Implement the smallest coherent change.
4. Add/update tests.
5. Run flutter analyze.
6. Run relevant flutter tests.
7. Manually verify the affected flow.

REPORT:
- Files changed
- What was implemented
- Tests executed
- Remaining issues
```

---

# 14. Current Status

**Phase 0:** Completed  
**Phase 1:** In progress  
**Phase 2:** Planned

When an AI agent opens this document, it should inspect the repository and current checklist state before deciding what to implement.

**Never assume an unchecked item is completely unimplemented; verify the code first.**
