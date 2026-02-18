# Glance — Development Roadmap

Predefined tasks grouped by milestone. Work through tasks sequentially within each milestone. After completing all tasks in a milestone, commit to `dev` with a descriptive message. Do not skip ahead, generate new tasks, or modify this file.

**Reference:** `Glance_PRD.md` is the authoritative spec for all implementation details.

---

## Milestone 1: Foundation (Weeks 1–2)

**Goal:** All data entities, the repository layer, and the marker library are functional and fully tested. No UI yet.

### Task 1.1: Xcode Project Setup
- Create a new Xcode project named "Glance" targeting iOS 17+
- Set up the folder structure defined in CLAUDE.md / PRD Section 7
- Configure the project for SwiftData
- Add a placeholder `GlanceApp.swift` with SwiftData model container
- Portrait orientation only

### Task 1.2: SwiftData Models
- Implement all six persisted entities exactly as defined in PRD Section 6:
  - `Profile` (silent default — "Me")
  - `MarkerCategory` (display name, display order)
  - `MarkerDefinition` (display name, category, unit, reference ranges, plausible ranges, higherIsBetter, aliases, isSystemDefined)
  - `UserMarker` (links Profile → MarkerDefinition, custom reference overrides, display order)
  - `MarkerEntry` (value, unit, dateOfService, entryTimestamp, note, sourceType)
  - `Visit` (date, doctorName, visitType, visitTypeLabel, notes, entryTimestamp)
- Implement `VisitPrepInsight` as a plain struct (not persisted)
- All entities use UUID primary keys
- All relationships configured correctly in SwiftData

### Task 1.3: DataRepository Protocol
- Define the `DataRepository` protocol exactly as specified in PRD Section 6
- All method signatures for: markers (CRUD + reorder), entries (CRUD + query by date range + latest), visits (CRUD + last visit of type), library (browse + categories + add custom), search, export (JSON + CSV)

### Task 1.4: LocalDataRepository Implementation
- Implement `LocalDataRepository` conforming to `DataRepository`
- Backed by SwiftData `ModelContext`
- All CRUD operations for all entities
- Query support: entries by date range, entries sorted by dateOfService, visits sorted by date, latest entry per marker
- Export: JSON serialization of all data, CSV export of marker entries
- Search: query matching against `MarkerDefinition.displayName` and `MarkerDefinition.aliases`

### Task 1.5: MarkerData.json + MarkerLibrary Service
- Create `MarkerData.json` with ~30 predefined markers organized by category
- Categories: Heart, Metabolic, Liver, Kidney, Blood, Vitamins & Minerals, Thyroid, General
- Each marker entry includes: displayName, category, defaultUnit, defaultReferenceLow, defaultReferenceHigh, plausibleMin, plausibleMax, higherIsBetter, aliases
- Markers must include at minimum: HDL, LDL, Total Cholesterol, Triglycerides, A1C, Fasting Glucose, ALT, AST, GGT, Creatinine, eGFR, BUN, Hemoglobin, Hematocrit, WBC, Platelets, Vitamin D, Vitamin B12, Calcium, Iron, Ferritin, TSH, T4 Free, Systolic BP, Diastolic BP, Heart Rate, BMI, Weight
- Implement `MarkerLibrary` service that loads JSON and seeds SwiftData on first launch
- Seeding is idempotent — running it again does not create duplicates

### Task 1.6: Unit Tests — Models and Repository
- Unit tests for all repository CRUD operations (create, read, update, delete for each entity)
- Unit tests for query correctness (date range filtering, sorting, latest entry)
- Unit tests for export serialization (JSON round-trip: export → re-import produces identical data)
- Unit tests for MarkerLibrary seeding (correct count, idempotency, all fields populated)
- Unit tests for search (alias resolution — "good cholesterol" → HDL; partial match; case insensitivity)
- Target: ≥90% code coverage on Models, Repositories, Services

### Milestone 1 Completion Criteria
- [ ] All six persisted entities compile and relate correctly
- [ ] Repository protocol defined with all methods
- [ ] LocalDataRepository passes all unit tests
- [ ] MarkerData.json contains ~30 markers with complete data
- [ ] First launch seeds the store correctly
- [ ] Export round-trip test passes
- [ ] Search resolves aliases correctly
- [ ] All unit tests pass

**Commit message format:** `M1: Foundation — data models, repository, marker library, unit tests`

---

## Milestone 2: Core Markers Experience (Weeks 2–4)

**Goal:** A user can onboard, see their tracked markers, tap into detail with a trend chart, add a reading, and see it reflected.

### Task 2.1: Tab Navigation Shell
- Implement the root `TabView` with three tabs: Markers, Visits, Settings
- Each tab shows a placeholder view
- Tab icons and labels per PRD Section 5 (Navigation)
- Primary Blue for selected tab

### Task 2.2: Onboarding Flow
- First-launch detection (no UserMarkers exist for default Profile)
- Onboarding screen: browse marker library by category
- Search within the library (uses SearchService with alias support)
- Select/deselect markers to track (checkmark toggle)
- "Add Custom Marker" option: name, unit, optional reference range
- "Done" button creates UserMarker entities for all selected markers
- After onboarding, navigate to the populated Markers tab
- Onboarding only appears on first launch (or if all markers are removed)

### Task 2.3: Home Screen — Markers Tab
- `HomeViewModel` loads tracked markers via repository
- Scrollable list of `MarkerRow` components (compact single-row, per PRD Section 8)
- Each row shows: marker name (left), latest value + unit (right), trend arrow, status color accent
- If no entries exist for a marker, show "—" as value and no trend arrow
- Tapping a row navigates to Marker Detail View
- Floating "+" button for quick-add entry
- Empty state if no markers tracked (guide to onboarding)
- Pull-to-refresh not needed (local data, always fresh)

### Task 2.4: MarkerRow Component
- Compact single-row design (~48–56pt at default text size)
- Marker name left-aligned (`.headline` style)
- Value + unit right-aligned (`.body` style)
- Trend arrow next to value (up/down/flat, colored by context — see InsightsEngine logic)
- Status indicator: left-edge accent bar or dot (green/amber/red + icon)
- No trend arrow if fewer than 3 entries
- Accessible: VoiceOver label reads full context ("HDL Cholesterol, 89 mg/dL, trending down, within normal range")
- `#Preview` blocks for 9-combination matrix

### Task 2.5: Marker Detail View
- `MarkerDetailViewModel` loads entries for the selected UserMarker
- Hero area: `TrendChart` component (Swift Charts time series)
- Below chart: chronological list of all entries (newest first), each showing value, date, note
- Reference range band shown on chart (shaded area between low and high)
- Out-of-range points colored red on the chart
- Current status badge (normal/watch/high)
- "Add Entry" button
- Edit/delete accessible via explicit button on each entry row (not gesture-only)
- Empty states per PRD: 0 entries (encouraging prompt), 1 entry (single dot, "add another to see trend"), 2+ entries (full chart)
- `#Preview` blocks for matrix

### Task 2.6: TrendChart Component
- Swift Charts implementation: time-series with point-and-line
- Shaded reference range band (light green or blue tint between low/high)
- Out-of-range points: red fill
- Sparse data handling: 1 point = single dot, 2 points = connected dots, 3+ = full trend line
- Auto-scales x-axis with sensible date formatting (months for short range, years for long range)
- Auto-scales y-axis to data range (with padding)
- Handles outliers: use plausible range or statistical detection to prevent axis blowup
- Accessibility summary label for VoiceOver
- `#Preview` blocks for matrix (with sample data at various densities)

### Task 2.7: Quick-Add Entry Flow
- Bottom sheet or modal triggered from home screen "+" or detail view "Add Entry"
- Select marker (if triggered from home screen; pre-selected if from detail view)
- Large numeric input field with appropriate keyboard
- Unit display (read-only, from marker definition)
- Date picker defaulting to today (max = today for marker entries)
- Optional note field
- Save button — validates, creates MarkerEntry with sourceType "quickAdd"
- Validation: plausible range check with confirmation dialog, 10x outlier detection with "Did you mean X?", duplicate detection with soft warning
- Under 15 seconds for the full flow (design for speed)
- `#Preview` blocks for matrix

### Task 2.8: InsightsEngine — Core Logic
- Implement `InsightsEngine` as a service
- **Status calculation:** compare latest value against reference range (user override if set, else default)
  - Normal: within range → green
  - Watch: within 10% of boundary → amber
  - Out of range: outside range → red
- **Trend calculation:** from last 3+ entries, determine direction (up, down, flat)
  - Context-aware: if higherIsBetter is true, trending up = good (green arrow), trending down = concerning
  - If higherIsBetter is false, reverse
- **Visit prep insights:** generate VisitPrepInsight suggestions for markers that are out of range or trending toward boundary
  - Language: "Consider asking your doctor about..." — never diagnostic
- Unit tests for every flag condition, every trend scenario, edge cases (identical readings, single reading, no readings, boundary values)

### Milestone 2 Completion Criteria
- [ ] Three-tab navigation works
- [ ] First launch shows onboarding; subsequent launches skip it
- [ ] Markers tab shows all tracked markers with latest value and status
- [ ] Tapping a marker shows detail view with chart
- [ ] Quick-add creates an entry and it appears on home screen and detail view
- [ ] Chart renders correctly for 0, 1, 2, and 3+ data points
- [ ] Validation dialogs work (plausible range, 10x outlier, duplicate)
- [ ] InsightsEngine unit tests all pass
- [ ] All views have preview matrix blocks
- [ ] All unit tests pass

**Commit message format:** `M2: Core markers — onboarding, home screen, detail view, quick-add, charts, insights engine`

---

## Milestone 3: Batch Entry & Search (Weeks 4–5)

**Goal:** A user can enter a full lab panel efficiently and find any marker instantly.

### Task 3.1: Batch Entry Flow
- Accessible from home screen (separate from quick-add)
- Single date picker at the top (applies to all entries in batch)
- List of tracked markers, each with an input field for value
- User fills in values for the markers they received results for, leaves others empty
- Empty fields are not saved (no zero-value entries)
- Save creates MarkerEntry for each filled field with sourceType "batchEntry"
- Same validation logic as quick-add (plausible range, 10x outlier, duplicate) — per-field
- Target: under 90 seconds for 5–6 markers
- `#Preview` blocks for matrix

### Task 3.2: Global Search
- Search bar on the Markers tab (or accessible from a prominent position)
- `SearchService` queries MarkerDefinition.displayName and .aliases
- Results show both tracked markers and untracked library markers
- Tapping a tracked marker navigates to its detail view
- Tapping an untracked marker offers to add it to tracking
- Case-insensitive, partial match, alias resolution ("good cholesterol" → HDL)
- Fast — results appear as user types
- `#Preview` blocks for matrix

### Task 3.3: Settings Screen
- **Manage Markers:** list of tracked markers with ability to add/remove, reorder (drag or manual)
- **Edit Reference Ranges:** per-marker custom reference range override (with clear labels for what's being changed)
- **Biometric Lock:** toggle for Face ID / Touch ID (disabled by default)
- **Export Data:** buttons for JSON and CSV export with security notice ("This file contains your health information. Store it securely.")
- **About / Privacy Policy:** link to PrivacyPolicy.md content
- `#Preview` blocks for matrix

### Task 3.4: Reference Range Editing
- From Settings > Manage Markers or from Marker Detail View
- Edit custom low/high reference range for any tracked marker
- Clear indication of default range vs custom override
- Reset to default option
- When range is updated, historical entries are re-evaluated (status colors may change)

### Milestone 3 Completion Criteria
- [ ] Batch entry saves multiple markers in one flow with single date
- [ ] Empty fields in batch are not saved
- [ ] Validation works per-field in batch entry
- [ ] Search finds markers by name, alias, and partial match
- [ ] Search surfaces both tracked and untracked markers with appropriate actions
- [ ] Settings screen has marker management, reference editing, biometric toggle, export, privacy policy
- [ ] Reference range changes re-evaluate historical entries
- [ ] Export produces valid JSON and CSV
- [ ] All views have preview matrix blocks
- [ ] All unit tests pass

**Commit message format:** `M3: Batch entry, global search, settings, reference range editing, export`

---

## Milestone 4: Visits & AI Insights (Weeks 5–6)

**Goal:** Full app experience end to end — visits logging, AI-generated doctor discussion prompts, and status indicators on the home screen.

### Task 4.1: Visits Tab — Visit Logging
- `VisitsViewModel` loads visits via repository
- Add Visit flow: date picker, doctor name (free text), visit type (predefined enum: physical, dental, vision, specialist, labWork, imaging, other + free label), notes scratchpad
- Visit list: chronological (newest first), each showing date, doctor, visit type, truncated note preview
- Tap to expand/view full visit details
- Edit and delete with confirmation dialog
- Empty state: "Log your first visit after your next appointment" with add button + secondary text "You can also log past visits to build a richer history"
- "Last [visit type]" date display on visit cards where relevant
- `#Preview` blocks for matrix

### Task 4.2: VisitCard Component
- Card component for the visits list
- Shows: date (prominent), doctor name, visit type badge, truncated note preview
- Tappable to expand to full detail
- Edit/delete via explicit buttons (not gesture-only)
- `#Preview` blocks for matrix

### Task 4.3: Next Visit Prep Section
- Appears at the top of the Visits tab (above the visit list) when there are flagged insights
- InsightsEngine generates `VisitPrepInsight` items for:
  - Markers currently out of range
  - Markers trending toward boundary (3+ consecutive readings in one direction)
- Each insight renders as an `InsightCard`: light blue tinted background, suggestion text with marker name bolded, icon indicating it's a suggestion
- Language: "Consider asking your doctor about your [marker] — it has been [trending up/down] over your last [N] readings" or "Your [marker] is currently [above/below] the typical range"
- If no flags: section is not displayed (no empty card, no "everything looks good")
- Tapping an insight card navigates to that marker's detail view
- `#Preview` blocks for matrix

### Task 4.4: InsightCard Component
- Light blue tinted background (tied to brand)
- Suggestion text with marker name bolded
- Subtle icon indicating it's a suggestion (not a diagnosis)
- Visually distinct from VisitCards
- Tappable — navigates to the relevant marker detail view
- `#Preview` blocks for matrix

### Task 4.5: Status Indicators on Home Screen
- MarkerRow now shows live status from InsightsEngine:
  - Status dot/bar: green (normal), amber (watch), red (out of range)
  - Paired with icon: checkmark, triangle, exclamation
  - Trend arrow colored contextually (higherIsBetter logic)
- Only shows status if the marker has at least 1 entry (no status for empty markers)
- Status updates automatically when new entries are added or reference ranges change

### Milestone 4 Completion Criteria
- [ ] Visits tab shows chronological list of logged visits
- [ ] Add/edit/delete visit works with confirmation
- [ ] Visit cards display date, doctor, type, note preview
- [ ] Next Visit Prep section appears when insights exist
- [ ] Insight cards show correct, safely-worded suggestions
- [ ] Insight cards are tappable and navigate to marker detail
- [ ] No visit prep section when no flags (not an empty card)
- [ ] Home screen marker rows show live status indicators and trend arrows
- [ ] All AI-generated text follows language constraints (no "diagnosis," "treatment," "you should")
- [ ] All views have preview matrix blocks
- [ ] All unit tests pass

**Commit message format:** `M4: Visits tab, AI visit prep insights, status indicators, insight cards`

---

## Milestone 5: Polish & Edge Cases (Week 6)

**Goal:** Shippable MVP. All edge cases handled, accessibility audited, all tests passing.

### Task 5.1: Empty States for All Screens
- Verify and polish empty states per PRD Section 8:
  - Markers tab (no markers tracked): guide to onboarding
  - Marker detail (0 entries): encouraging prompt to add first reading
  - Marker detail (1 entry): single dot on chart, "Add another reading to start seeing your trend"
  - Visits tab (no visits): "Log your first visit..." message with add button
  - Search (no results): helpful message
- All empty states: warm tone, encouraging, not blank or technical

### Task 5.2: Validation Dialogs
- Plausible range warning: "You entered [marker] of [value]. This seems unusual — would you like to double-check?"
- 10x outlier suggestion: "Did you mean [suggested value]?" — only when user has existing entries to compare against
- Duplicate detection: "You already have a [marker] entry of [value] for this date. Add anyway?"
- Future date prevention: date picker maxes at today for marker entries (visits can have future dates)
- Custom markers skip plausible range and 10x checks (no reference data)
- All dialogs have clear Cancel and Confirm actions

### Task 5.3: Edit and Delete Safeguards
- Editing an entry shows previous value for comparison
- Delete confirmation: "Delete [marker] reading of [value] from [date]?" with clear Cancel
- No swipe-to-delete without confirmation
- Edit and delete buttons always accessible via explicit button (not gesture-only)
- Delete a tracked marker from Settings shows warning about losing all entries

### Task 5.4: Export / Backup
- JSON export: full data dump (all profiles, markers, entries, visits) — machine-readable
- CSV export: marker entries in tabular format (marker name, value, unit, date, note)
- Security notice before export: "This file contains your health information. Store it securely."
- Uses iOS share sheet for output
- Unit test: export round-trip (JSON export → import produces identical data)

### Task 5.5: Biometric Lock
- Optional Face ID / Touch ID lock via LocalAuthentication framework
- Toggle in Settings (off by default)
- When enabled: app shows auth prompt on launch and when returning from background
- Graceful fallback if biometric unavailable (show passcode option or skip)

### Task 5.6: Accessibility Audit
- Run through every screen with VoiceOver enabled
- Verify all `.accessibilityLabel()` values are meaningful and descriptive
- Verify all interactive elements are reachable via VoiceOver
- Verify Dynamic Type at all three test sizes renders correctly across all screens
- Scan the full 9-combination preview matrix in Xcode for every view
- Fix any layout breakage, clipped text, or overlapping elements
- Verify color-only indicators all have icon pairing

### Task 5.7: UI Tests
- Write and run XCTest UI tests for all critical flows defined in CLAUDE.md Testing section:
  - Onboarding → select markers → home screen
  - Quick-add → enter value → save → verify on home
  - Batch entry → fill multiple → save → verify all appear
  - Tab navigation between all three tabs
  - Visit logging → save → verify in list
  - Search → verify correct results
- All UI tests pass in simulator

### Task 5.8: Final Review and README
- Generate README with: project overview, tech stack, build/run instructions, folder structure, test commands
- Generate `PrivacyPolicy.md`: "We collect no data. We transmit no data. Everything stays on your device."
- Verify all unit tests pass
- Verify all UI tests pass
- Verify no warnings or errors in Xcode build
- Clean up any TODO comments or placeholder code

### Milestone 5 Completion Criteria
- [ ] All empty states implemented and match PRD
- [ ] All validation dialogs work correctly
- [ ] Edit/delete flows have proper safeguards
- [ ] JSON and CSV export work with security notice
- [ ] Biometric lock works when enabled
- [ ] Accessibility audit complete — VoiceOver, Dynamic Type, contrast all pass
- [ ] All 9-combination preview matrices render without breakage
- [ ] All UI tests pass
- [ ] All unit tests pass
- [ ] README and Privacy Policy generated
- [ ] Clean build with no warnings

**Commit message format:** `M5: Polish — empty states, validation, export, biometric lock, accessibility audit, UI tests`

---

## Post-MVP

After M5 is complete and committed, the app is ready for user testing. Future work (not for Claude Code to build now):

- `option-a-layout` branch: experiment with full-card layout vs compact rows
- User testing with 5–8 seniors
- Iterate based on feedback
- Plan V2 features (multi-profile, FHIR, OCR, cloud sync)