# CLAUDE.md — Glance Development Guide

This file is read by Claude Code at the start of every session. It contains everything needed to build Glance correctly without re-reading the full PRD each time. When in doubt, this file is your operating manual. When this file and the PRD conflict, the PRD wins.

---

## What is Glance?

A native iOS app that lets health-active adults (primarily 50–75) enter, retrieve, and visualize their health markers faster than any existing workaround. The user should be able to look up any health number in under 10 seconds. The app is local-only (no backend, no cloud), senior-first in design, and privacy-forward.

**Core loop:** User enters health data after appointments → reviews trends and AI-generated doctor questions before the next appointment. Entry creates the data. Retrieval before a visit proves the value.

---

## Key Files and Where to Find Them

| File | Purpose | How to use it |
|------|---------|---------------|
| `Glance_PRD.md` | **Authoritative specification.** All product requirements, data model, design system, accessibility rules, testing strategy. | The single source of truth for what to build. If a question isn't answered here in CLAUDE.md, check the PRD. |
| `roadmap.md` | **Predefined development tasks** grouped by milestone with completion criteria. | Work through tasks sequentially. Do not skip ahead, generate new tasks, or modify this file. |
| `/context/` folder | Original UX research interview transcripts, competitive analysis, and insights that informed the PRD. | Reference **only** if you need clarification on user intent, tone, or the reasoning behind a specific product decision. Do not read these routinely — they burn context window for information already distilled into the PRD. |

---

## Architecture

### Pattern: MVVM with Repository Layer

```
Views (SwiftUI) → ViewModels → DataRepository (protocol) → LocalDataRepository (SwiftData)
                                                         → Services (InsightsEngine, SearchService, MarkerLibrary)
```

**Hard rule:** Views never access SwiftData directly. Always go through the Repository via a ViewModel.

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Platform | Native iOS, iOS 17+ minimum |
| UI | SwiftUI |
| Persistence | SwiftData |
| Charts | Swift Charts |
| Auth | LocalAuthentication (optional biometric lock) |
| Dependencies | **None.** Zero external packages. No CocoaPods, no SPM. Apple-native only. |

### Project Structure

```
Glance/
├── App/
│   └── GlanceApp.swift
├── Models/
│   ├── Profile.swift
│   ├── MarkerDefinition.swift
│   ├── MarkerCategory.swift
│   ├── UserMarker.swift
│   ├── MarkerEntry.swift
│   ├── Visit.swift
│   └── VisitPrepInsight.swift          (struct, not persisted)
├── Repositories/
│   ├── DataRepository.swift             (protocol)
│   └── LocalDataRepository.swift        (SwiftData implementation)
├── Services/
│   ├── InsightsEngine.swift
│   ├── SearchService.swift
│   └── MarkerLibrary.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── HomeViewModel.swift
│   ├── MarkerDetailViewModel.swift
│   ├── EntryViewModel.swift
│   ├── VisitsViewModel.swift
│   └── SettingsViewModel.swift
├── Views/
│   ├── Onboarding/
│   ├── Home/
│   ├── MarkerDetail/
│   ├── Entry/
│   ├── Visits/
│   ├── Settings/
│   └── Components/                      (MarkerRow, TrendChart, StatusBadge, VisitCard, InsightCard, etc.)
├── Resources/
│   ├── Assets.xcassets
│   ├── MarkerData.json
│   └── PrivacyPolicy.md
└── Extensions/
```

---

## Data Model Summary

Six persisted entities (SwiftData) + one computed struct. Full field definitions are in PRD Section 6. Do not deviate from those definitions.

| Entity | Key Facts |
|--------|-----------|
| `Profile` | Silent default ("Me"). User never sees it in V1. Exists for V2 multi-profile migration. |
| `MarkerCategory` | Groups markers (Heart, Metabolic, Liver, etc.). Display order field for sorting. |
| `MarkerDefinition` | The ~30 predefined markers + user-created custom ones. Seeded from `MarkerData.json`. Has aliases for search, plausible ranges for validation, higherIsBetter for contextual trend coloring. |
| `UserMarker` | "I chose to track this marker." Links Profile → MarkerDefinition. Holds custom reference range overrides and display order. |
| `MarkerEntry` | Every recorded health value. value, unit, dateOfService, entryTimestamp, note, sourceType ("quickAdd" or "batchEntry"). |
| `Visit` | Doctor visits. date, doctorName, visitType (enum string), visitTypeLabel (for "other"), notes, entryTimestamp. |
| `VisitPrepInsight` | **Not persisted.** Computed at runtime by InsightsEngine. Deterministic. |

**Key decisions already made:**
- All entities use UUID primary keys
- Reference ranges re-evaluate historical entries when changed (no freezing old evaluations)
- sourceType is an extensible string enum (V1 uses "quickAdd" and "batchEntry" only)
- Every entity references Profile for future multi-profile support

---

## Design System Quick Reference

Full spec is in PRD Section 8. These are the rules you'll reference most often.

### Colors

| Token | Usage |
|-------|-------|
| Primary Blue | Tab selection, primary buttons, chart lines, brand accents (from the Glance stethoscope logo) |
| Status Green | Normal range — always paired with checkmark icon |
| Status Amber | Watch/approaching boundary — always paired with warning triangle icon |
| Status Red | Out of range — always paired with exclamation mark icon |
| Background | Off-white / warm light gray (not pure white) |
| Card Background | White |
| Insight Card BG | Light blue tint |

### Typography

System font (SF Pro) only. **Never hardcode font sizes.** Always use SwiftUI semantic text styles.

| Style | Usage |
|-------|-------|
| `.largeTitle` | Screen headers |
| `.headline` | Marker names on rows |
| `.body` | Values, dates, general text |
| `.caption` | Timestamps, reference labels |

Use `@ScaledMetric` for spacing values that should scale with Dynamic Type.

### Layout Rules

- Single-column layout, portrait only
- Minimum 16pt padding on screen edges
- Minimum 12pt spacing between rows/cards
- 12–14pt corner radius on cards
- **44x44pt minimum touch targets** on all interactive elements (non-negotiable)

---

## Accessibility Requirements (Non-Negotiable)

These are not "nice to haves." The app is designed for seniors. Accessibility failures are bugs.

1. **Dynamic Type:** Every text element uses semantic SwiftUI text styles. No hardcoded sizes. App must be fully functional at `.accessibilityExtraExtraExtraLarge`. Cards/rows grow — never truncate.
2. **Color + Icon:** Color is never the only signifier. Green/amber/red always paired with checkmark/triangle/exclamation icons.
3. **Contrast:** WCAG AA minimum (4.5:1 body text, 3:1 large text). Status colors as accents, not text colors.
4. **VoiceOver:** Every interactive element has a meaningful `.accessibilityLabel()`. MarkerRow reads: "HDL Cholesterol, 89 milligrams per deciliter, trending down, within normal range."
5. **No hidden gestures:** Every action reachable via visible button. Swipe-to-delete is a shortcut only — explicit edit/delete buttons must exist.
6. **Touch targets:** 44x44pt minimum. Especially critical for stacked batch entry fields.

---

## AI / Insights Constraints

The InsightsEngine is deterministic — threshold math and trend detection. No LLM calls, no external API calls.

### Language Rules (Hard Constraints)

**Never use:** "diagnosis," "treatment," "medication," "you should," "this means," risk scores, severity ratings, medical terminology beyond marker names.

**Always use:** "Consider asking your doctor about..." or "Your [marker] has been [trending direction] over your last [N] readings."

### InsightsEngine Logic

- **Status:** Compare latest value to reference range (user override > default). Normal = within range (green). Watch = within 10% of boundary (amber). Out of range = outside range (red).
- **Trend:** From last 3+ entries, determine direction. If higherIsBetter is true, trending up = good (green arrow). If false, reverse.
- **Visit prep insights:** Generated for markers that are out of range or trending toward boundary. Displayed on Visits tab only.

---

## Validation Rules

Every entry flow (quick-add and batch) must enforce these:

1. **Plausible range check:** If value is outside the marker's physiological min/max, show confirmation: "You entered [marker] of [value]. This seems unusual — would you like to double-check?"
2. **10x outlier detection:** If value is ~10x off from the user's typical range for that marker, suggest: "Did you mean [suggested value]?"
3. **Duplicate detection:** Same marker + same value + same date → soft warning: "You already have an [marker] entry of [value] for this date. Add anyway?"
4. **Future date prevention:** Date picker maxes at today for marker entries. Visits can have future dates.
5. **Custom markers:** Skip plausible range and 10x checks (no reference data available).

---

## Testing Requirements

### Unit Tests (Tier 1 — Failures Block Progress)

Target: ≥90% code coverage on Models, Repositories, and Services.

**InsightsEngine (safety-sensitive — test exhaustively):**
- Every flag condition (out of range high/low, at boundary, within range)
- Every trend calculation (3 up, 3 down, mixed, fewer than 3)
- Contextual interpretation (higherIsBetter true vs false)
- Edge cases: identical readings, single reading, no readings, boundary values

**Validation logic:**
- Plausible range boundaries for every predefined marker
- 10x outlier detection
- Duplicate entry detection
- Future date rejection

**Repository layer:**
- All CRUD operations for all entities
- Query correctness (date range, sorting, latest entry)
- Export round-trip (JSON export → re-import produces identical data)

**Search:**
- Alias resolution ("good cholesterol" → HDL)
- Partial match, case insensitivity
- Custom marker search

### UI Tests (Tier 2 — XCTest in Simulator)

Critical user flows:
- Onboarding → select markers → home screen populated
- Quick-add → enter value → save → verify on home screen
- Batch entry → fill multiple → save → verify all appear
- Tab navigation across all three tabs
- Visit logging → save → verify in list
- Search → verify correct results

### Preview Matrix (Tier 3 — Visual Review)

Every view file includes `#Preview` blocks for a 9-combination matrix:

**Devices:** iPhone SE (3rd gen), iPhone 15, iPhone 16 Plus
**Text sizes:** Default, Large, Accessibility Extra Extra Extra Large

Generate these once per view file. Scan visually in Xcode for layout breakage, clipped text, or overlapping elements before marking a task complete.

---

## Workflow Rules

### How to Work Through the Roadmap

1. Open `roadmap.md` and find the current milestone and task.
2. Complete tasks **sequentially** within each milestone. Do not skip ahead.
3. After completing **all tasks in a milestone**, commit to `dev` with the commit message format specified in the roadmap.
4. Do not generate new tasks, modify the roadmap, or reinterpret scope.
5. If a task is blocked or the PRD is ambiguous on a specific point, **stop and ask** rather than improvising.

### Git Conventions

- `main` — latest stable state. Merge from `dev` at milestone completion.
- `dev` — active development branch. All work happens here.
- Feature branches off `dev` only if needed for isolated work (e.g., `feature/batch-entry`).
- Commit after each completed milestone, not after each task.
- Commit message format is specified at the bottom of each milestone in the roadmap.

### When Something Isn't Specified

1. Check the PRD first (Sections 5–10 cover most implementation details).
2. If still ambiguous, follow the product principles in PRD Section 4:
   - Speed over completeness
   - Visual over tabular
   - Empower, don't diagnose
   - Senior-first, not senior-only
3. If still unclear, ask. Do not guess.

---

## Explicit Non-Scope — Do NOT Build

This list is absolute. Do not build, stub, or scaffold any of these in V1, even if they seem easy or helpful:

- No FHIR integration or portal connections
- No document upload or OCR
- No chatbot or conversational AI (InsightsEngine is deterministic, not LLM-based)
- No medication tracking
- No multi-profile or caregiver access (Profile entity exists silently — do not expose it in UI)
- No cloud sync or backend services
- No user accounts or authentication (except optional biometric app lock)
- No notifications, reminders, or scheduling
- No Apple Health or wearable integration
- No dark mode
- No landscape orientation
- No in-app purchases or paywall logic
- No analytics or third-party SDKs of any kind
- No social features or sharing (except raw data export)
- No third-party dependencies — zero CocoaPods, zero SPM packages

---

## Common Pitfalls to Avoid

- **Don't over-engineer the Profile entity.** It's a silent default. No UI for switching profiles, no settings for profile management. It exists solely so V2 migration is trivial.
- **Don't make the InsightsEngine smarter than specified.** It does threshold math and trend detection. No NLP, no ML, no pattern recognition beyond "3+ consecutive readings in one direction."
- **Don't create empty state cards that say "Everything looks good!"** If there are no insights, the Next Visit Prep section simply doesn't appear. No empty card.
- **Don't use swipe-to-delete as the only delete path.** Always provide an explicit button. Swipe is a shortcut, not the primary mechanism.
- **Don't forget the unit on entry display.** Every value shown to the user must include its unit. "89" means nothing. "89 mg/dL" is useful.
- **Don't hardcode any font sizes or fixed-height containers.** Dynamic Type compliance is mandatory, not aspirational.
- **Don't log health values to the console.** Not in debug, not in production. Health data stays in SwiftData only.
- **Don't store anything in UserDefaults.** Health data lives exclusively in SwiftData.

---

## Quick Decision Reference

| Situation | Decision |
|-----------|----------|
| "Should I add a loading spinner?" | No. Local data, instant access. If it's slow, optimize — don't add spinners. |
| "Should this be a full-screen view or a sheet?" | Entry flows → sheet/modal. Detail views → full-screen navigation. |
| "How should I handle a marker with no entries?" | Show "—" for value, no trend arrow, no status indicator. Empty state in detail view. |
| "Trend arrow with fewer than 3 entries?" | No trend arrow. Only show with 3+ entries. |
| "User changes reference range — what about old entries?" | Re-evaluate all historical entries against the new range. |
| "Should batch entry create entries for empty fields?" | No. Skip empty fields. No zero-value entries. |
| "Where do AI suggestions appear?" | Visits tab only (Next Visit Prep section). Never on the home screen. |
| "Date picker — how far back?" | No limit going back. Max is today for marker entries. Visits can have future dates. |

---

*CLAUDE.md Version 1.0 — February 18, 2026*
*Companion to Glance_PRD.md and roadmap.md*
