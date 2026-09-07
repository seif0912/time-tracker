# Time Tracker — AI Development Checklist

> **Purpose:** This document is the source of truth for developing the Time Tracker app phase by phase. It is written so an AI coding agent can understand the product roadmap, current progress, architectural intent, and implementation boundaries.
>
> **Current stack:** Flutter/Dart, Riverpod, Drift/SQLite for local data, Firebase where needed.
>
> **Important development rule:** Build functionality first and keep Phase 1 UI minimal. The polished visual/UI work belongs to Phase 2. Do not spend time making Phase 1 screens visually complete when the functionality is not finished.

---

## 0. AI Agent Instructions

When working on this project:

1. **Work phase by phase.** Do not implement future phases unless explicitly requested.
2. **Respect completed work.** Do not unnecessarily rewrite working architecture or functionality.
3. **Inspect the existing code first.** Before changing a file, understand its current implementation and dependencies.
4. **Prefer incremental changes.** Extend the existing architecture rather than replacing it without a strong reason.
5. **Keep concerns separated:**
   - Presentation/UI
   - Riverpod state/controllers
   - Domain/business logic
   - Repositories
   - Database/infrastructure
6. **Do not put database access directly in widgets.**
7. **Do not put business logic directly in widgets.**
8. **Use repositories/services for external or persistent data access.**
9. **Keep the timer timestamp-based.** A periodic timer should refresh the UI, not be the source of truth for elapsed time.
10. **Preserve offline/local functionality.** The app should be usable locally before cloud synchronization is introduced.
11. **Do not redesign the UI during Phase 1.** Use simple functional UI only.
12. **Before moving to another phase:**
    - run `flutter analyze`
    - run relevant tests
    - manually test the affected user flow
    - fix regressions
13. **Do not add unnecessary dependencies.** Explain why a new package is needed before introducing it.
14. **Never expose API keys/secrets in the Flutter client.**
15. **For migrations, never manually edit generated Drift files.**
16. **When a generated file needs updating, regenerate it with the appropriate build command.**
17. **If an implementation decision affects future Pro/AI functionality, prefer a data model that preserves historical data and makes aggregation possible.**

---

# 🟢 Phase 0 — Project Setup

## Status

**Completed**

- [x] Create Flutter project
- [x] Set up Git repository
- [x] Set up project architecture
- [x] Configure environments
- [x] Set up dependency management
- [x] Set up routing/navigation
- [x] Set up theme system
- [x] Set up light/dark mode
- [x] Create reusable UI components
- [x] Set up local database
- [x] Define database models
- [x] Define repository/service layers
- [x] Set up error handling
- [x] Set up logging
- [x] Set up analytics/crash reporting

## Architecture established

```text
Flutter UI
    ↓
Riverpod
    ↓
Controllers / Business Logic
    ↓
Repositories / Services
    ↓
Drift / SQLite
```

Firebase is available for services such as analytics/crash reporting and can be expanded later where appropriate.

## Current database concepts

### Tasks

```text
Task
├── id
├── name
├── description
├── icon
├── colorValue
├── category
├── favorite
├── archived
├── createdAt
└── updatedAt
```

### Time Entries

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

> **Note:** The exact implementation in the repository is authoritative. If this document and the code disagree, inspect the code and update this checklist/document when the implementation is intentionally changed.

---

# 🚀 Phase 1 — V0.1 Core Time Tracker

## Goal

Build a fully functional local-first time tracker.

The Phase 1 UI should be minimal and functional. Do not focus on visual polish.

---

## Authentication

- [ ] Sign up
- [ ] Login
- [ ] Logout
- [ ] Password reset
- [ ] Guest/local mode decision
- [ ] User profile

### Agent notes

Authentication should not unnecessarily block local time tracking. Decide and document how guest/local data behaves when an account is later created.

---

## Tasks

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

### Expected architecture

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

### Requirements

- Tasks must have stable IDs.
- Archived tasks should not appear in the normal active task list.
- Deleting a task must consider what happens to its historical time sessions.
- Favoriting must not modify historical time data.
- Search and sorting should operate on task data, not duplicate task records.

---

## Timer

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

### Timer architecture

```text
User
 ↓
TimerController
 ↓
TimerState
 ↓
TimeEntryRepository
 ↓
Drift / SQLite
```

### Critical timer rule

The timer must be **timestamp-based**.

Do NOT use:

```text
seconds = seconds + 1
```

as the authoritative elapsed-time calculation.

Instead use timestamps:

```text
elapsed = DateTime.now() - segmentStartedAt
```

A periodic Dart `Timer` may refresh the UI every second, but elapsed time must be derived from timestamps.

### Timer state

Conceptually:

```text
TimerState
├── status
│   ├── idle
│   ├── running
│   └── paused
├── taskId
├── sessionId
├── startedAt
├── currentSegmentStartedAt
├── accumulatedSeconds
└── currentElapsedSeconds
```

### Timer invariants

The implementation must guarantee:

- Only one timer can be active at a time.
- A running timer always has a task.
- A running timer has a valid start/segment timestamp.
- Pausing stops active ticking but preserves accumulated time.
- Resuming starts a new timing segment.
- Stopping creates a completed session.
- Restarting the app must be able to recover the active timer state.
- Device sleep/backgrounding must not cause elapsed time to become inaccurate.

---

## Time Sessions

- [ ] Create session automatically
- [ ] Save start timestamp
- [ ] Save end timestamp
- [ ] Calculate duration
- [ ] Edit session
- [ ] Delete session
- [ ] Manual time entry
- [ ] Session history
- [ ] Session grouping by day

### Session model

```text
TimeEntry
├── taskId
├── startedAt
├── endedAt
├── durationSeconds
├── manual
└── createdAt
```

### Requirements

Every completed timer should produce a persistent time session.

Historical time should be represented by sessions rather than storing a single accumulated total on the task.

This enables future:

- project analytics
- goals
- comparisons
- productivity metrics
- AI analysis

---

## Dashboard

- [ ] Today's total
- [ ] Weekly total
- [ ] Today's tasks
- [ ] Recent sessions
- [ ] Task time totals
- [ ] Basic daily chart
- [ ] Active timer card

### Data flow

```text
TimeEntries
    ↓
Aggregation / queries
    ↓
DashboardController
    ↓
Dashboard UI
```

Do not duplicate totals unnecessarily in the database if they can reliably be calculated from session data.

---

## History

- [ ] Daily history
- [ ] Weekly history
- [ ] Session details
- [ ] Date navigation
- [ ] Edit historical session

### Requirements

History should be derived from persistent time sessions.

Date filtering should use the session timestamps.

Historical edits must update the underlying session rather than creating duplicate historical records.

---

## Notifications

- [ ] Timer running notification
- [ ] Timer stop notification
- [ ] Basic reminder
- [ ] Notification permission handling

### Requirements

Notifications must reflect the actual timer state.

A notification must never be treated as the source of truth for timer state.

---

# 🟢 Phase 2 — V0.1 Polish

## Goal

Redesign the application UI/UX after the core functionality works.

> **Important:** The visual design may be substantially changed here. Phase 1 screens are functional prototypes only.

---

## UX

- [ ] Empty states
- [ ] Loading states
- [ ] Error states
- [ ] Offline states
- [ ] Confirmation dialogs
- [ ] Undo actions
- [ ] Pull-to-refresh
- [ ] Haptic feedback
- [ ] Animations
- [ ] Page transitions
- [ ] Timer animations

## Data

- [ ] Offline-first behavior
- [ ] Local persistence
- [ ] Cloud synchronization
- [ ] Conflict handling
- [ ] Backup
- [ ] Data recovery

## Settings

- [ ] Account settings
- [ ] Notification settings
- [ ] Appearance settings
- [ ] Time format
- [ ] Week-start preference
- [ ] Data management
- [ ] Delete account

## Quality

- [ ] Unit tests
- [ ] Timer tests
- [ ] Database tests
- [ ] Repository tests
- [ ] Widget tests
- [ ] Integration tests
- [ ] Android testing
- [ ] iOS testing
- [ ] Different screen sizes
- [ ] Offline testing
- [ ] Background timer testing

---

# ⭐ Phase 3 — V0.5 Pro Projects

## Goal

Turn the simple task tracker into a project-oriented time-management product.

## Projects

- [ ] Create project
- [ ] Edit project
- [ ] Archive project
- [ ] Delete project
- [ ] Project icon
- [ ] Project color
- [ ] Project description
- [ ] Project deadline
- [ ] Project status
- [ ] Project categories

## Project → Tasks

- [ ] Assign task to project
- [ ] Move task between projects
- [ ] Project task list
- [ ] Project task filtering
- [ ] Project task sorting
- [ ] Project total time

## Estimates

- [ ] Estimated task duration
- [ ] Actual task duration
- [ ] Estimated vs actual
- [ ] Project estimated time
- [ ] Project actual time
- [ ] Over-budget indicator

## Project Dashboard

- [ ] Total project time
- [ ] Time by category
- [ ] Time by task
- [ ] Project progress
- [ ] Deadline indicator
- [ ] Estimated vs actual chart

---

# 🎯 Phase 4 — Pro Goals

## Goals

- [ ] Create goal
- [ ] Edit goal
- [ ] Delete goal
- [ ] Daily goal
- [ ] Weekly goal
- [ ] Monthly goal
- [ ] Project goal
- [ ] Task goal

## Progress

- [ ] Goal progress calculation
- [ ] Progress visualization
- [ ] Goal completion
- [ ] Goal history
- [ ] Streak calculation
- [ ] Goal notifications
- [ ] Goal reminders

### Example

```text
Development

14h 32m / 20h

████████████░░░░

72.6%
```

---

# 📊 Phase 5 — Pro Analytics

## Time Analytics

- [ ] Time by day
- [ ] Time by week
- [ ] Time by month
- [ ] Time by project
- [ ] Time by task
- [ ] Time by category
- [ ] Time by weekday
- [ ] Time by hour

## Productivity Metrics

- [ ] Average session duration
- [ ] Longest session
- [ ] Number of sessions
- [ ] Average daily time
- [ ] Focus time
- [ ] Most productive day
- [ ] Most productive hour
- [ ] Task completion time

## Comparisons

- [ ] Today vs yesterday
- [ ] This week vs last week
- [ ] This month vs last month
- [ ] Project comparisons
- [ ] Category comparisons
- [ ] Productivity trends

## Insights Engine

- [ ] Detect time increases
- [ ] Detect time decreases
- [ ] Detect unusual patterns
- [ ] Detect over-budget projects
- [ ] Detect productivity trends
- [ ] Generate insight cards

---

# 🧠 Phase 6 — AI Time Coach

## Goal

Use historical time data to provide useful explanations, summaries, comparisons, and recommendations.

## AI Infrastructure

- [ ] AI service/API
- [ ] Secure API architecture
- [ ] Usage limits
- [ ] Token/cost monitoring
- [ ] AI error handling
- [ ] Privacy controls

## AI Context

- [ ] Daily time data
- [ ] Weekly time data
- [ ] Monthly time data
- [ ] Project data
- [ ] Task data
- [ ] Goal data
- [ ] Historical comparisons

## AI Features

- [ ] Weekly AI summary
- [ ] Monthly AI summary
- [ ] Productivity analysis
- [ ] Project analysis
- [ ] Goal analysis
- [ ] Recommendations
- [ ] Ask-your-time chat

### Example questions

```text
Where did my time go this week?
What did I spend the most time on?
Which project is taking the longest?
Am I improving?
What changed compared to last week?
Which tasks are taking longer than expected?
```

### AI architecture principle

Do not send raw, unnecessary personal data to the AI service.

Prefer a controlled context pipeline:

```text
Local / Cloud Data
       ↓
Analytics / Aggregation
       ↓
AI Context Builder
       ↓
Secure Backend / AI Service
       ↓
AI Response
       ↓
App
```

---

# 💳 Phase 7 — Freemium & Payments

## Free/Pro System

- [ ] Define feature entitlements
- [ ] Free user state
- [ ] Pro user state
- [ ] Trial state
- [ ] Expired subscription state
- [ ] Restore purchases

## Subscription

- [ ] Monthly subscription
- [ ] Annual subscription
- [ ] 7-day Pro trial
- [ ] Subscription screen
- [ ] Upgrade flow
- [ ] Cancel flow
- [ ] Restore purchase
- [ ] Payment failure handling
- [ ] Subscription expiration handling

## Paywalls

- [ ] Project paywall
- [ ] Advanced analytics paywall
- [ ] Goals paywall
- [ ] AI paywall
- [ ] Export paywall
- [ ] Pro feature preview

> **Product principle:** Do not make paywalls annoying. Let users experience enough value to understand why Pro is useful.

---

# ☁️ Phase 8 — Sync & Account Infrastructure

- [ ] Cloud database
- [ ] User authentication
- [ ] Device synchronization
- [ ] Session synchronization
- [ ] Task synchronization
- [ ] Project synchronization
- [ ] Goal synchronization
- [ ] Conflict resolution
- [ ] Offline queue
- [ ] Data backup
- [ ] Account deletion
- [ ] Data export

### Sync architecture

```text
Local Database
      ↕
Sync Engine
      ↕
Cloud Database
```

Local data should remain usable when offline.

---

# 📤 Phase 9 — Export & Integrations

## Export

- [ ] CSV export
- [ ] PDF reports
- [ ] Project reports
- [ ] Weekly report
- [ ] Monthly report

## Future integrations

- [ ] Google Calendar
- [ ] Apple Calendar
- [ ] Notion
- [ ] Todoist
- [ ] GitHub
- [ ] Slack

> These integrations are intentionally deferred and should not block the first MVP.

---

# 📱 Phase 10 — Widgets & Automation

- [ ] Home-screen widget
- [ ] Quick-start task
- [ ] Quick-stop timer
- [ ] Lock-screen timer
- [ ] Dynamic timer notification
- [ ] Recurring tasks
- [ ] Scheduled tasks
- [ ] Smart reminders
- [ ] Idle detection
- [ ] Automatic timer suggestions

---

# 🧪 Phase 11 — Pre-Launch QA

## Functional

- [ ] Test every user flow
- [ ] Test timer accuracy
- [ ] Test background behavior
- [ ] Test offline mode
- [ ] Test synchronization
- [ ] Test subscription states
- [ ] Test trial expiration
- [ ] Test data deletion
- [ ] Test account recovery

## Performance

- [ ] Startup performance
- [ ] Database performance
- [ ] Large history performance
- [ ] Analytics performance
- [ ] AI response performance
- [ ] Battery consumption

## Security

- [ ] Secure authentication
- [ ] Secure API
- [ ] Validate user permissions
- [ ] Protect subscription endpoints
- [ ] Protect AI endpoints
- [ ] Don't expose API secrets
- [ ] Test unauthorized requests

---

# 🚀 Phase 12 — Launch

## App Store

- [ ] App icon
- [ ] Screenshots
- [ ] App description
- [ ] Keywords
- [ ] Privacy policy
- [ ] Terms of service
- [ ] Support page
- [ ] Pricing
- [ ] Subscription disclosures

## Analytics

Track:

- [ ] Install
- [ ] Account creation
- [ ] First task
- [ ] First timer start
- [ ] First completed session
- [ ] First day retention
- [ ] 7-day retention
- [ ] 30-day retention
- [ ] Sessions per user
- [ ] Time tracked per user
- [ ] Pro trial started
- [ ] Trial → paid
- [ ] Free → paid
- [ ] Subscription cancellation

---

# 🎯 Development Milestones

Do not treat the entire checklist as one linear development task.

## V0.1 — First usable product

Prioritize:

- [ ] Project setup
- [ ] Authentication
- [ ] Task creation
- [ ] Task list
- [ ] Start timer
- [ ] Pause timer
- [ ] Stop timer
- [ ] Background timer
- [ ] Session storage
- [ ] Manual time entry
- [ ] History
- [ ] Daily total
- [ ] Weekly total
- [ ] Basic dashboard
- [ ] Notifications
- [ ] Basic settings
- [ ] Testing

**Goal:** A real user can track time reliably from start to finish.

## V0.5 — Project productivity

Add:

- Projects
- Task/project relationships
- Estimates
- Goals
- Advanced analytics

## V1.0 — Intelligent time tracking

Add:

- AI Time Coach
- AI summaries
- AI insights
- Recommendations
- Advanced analytics
- Automation
- Mature synchronization

---

# 🧭 Current Development Position

**Current phase:** Phase 0 completed → Phase 1 in progress.

**Immediate priority:** Build the V0.1 core functionality.

**Do not jump ahead to:**

- Pro projects
- Advanced analytics
- AI
- Payments
- Integrations
- Final visual design

until the required earlier phase is complete.

---

# 🤖 How an AI Coding Agent Should Work on a Task

When given a task such as:

> "Implement pause/resume for the timer."

The agent should:

1. Identify the relevant existing files.
2. Inspect the current TimerState.
3. Inspect TimerController.
4. Inspect TimeEntryRepository and database schema.
5. Determine which existing architecture should be extended.
6. Implement the smallest coherent change.
7. Update providers/models if required.
8. Add or update tests.
9. Run:
   ```bash
   flutter analyze
   flutter test
   ```
10. Report:
    - files changed
    - functionality implemented
    - tests run
    - remaining issues
11. Do not redesign unrelated UI or implement future-phase features.

---

# 📌 Product Principles

1. **Reliable time tracking comes first.**
2. **Historical session data is valuable.**
3. **The timer must remain accurate across backgrounding, sleep, and restarts.**
4. **Local-first functionality should work before cloud sync.**
5. **Free should be genuinely useful.**
6. **Pro should focus on projects, goals, analytics, and understanding time.**
7. **AI should explain and help users understand their time, not simply add a chatbot.**
8. **UI polish is separate from core functionality.**
9. **Data models should support future analytics and AI without unnecessary duplication.**
10. **Keep the architecture maintainable as features grow.**
