# Glance — Product Requirements Document (PRD)

**Version:** 1.0
**Date:** February 18, 2026
**Authors:** Julian Baumann (Founder), Claude (CPO/Design Lead/CTO)
**Status:** MVP Specification — Ready for Development

---

## 1. Product Summary

### Target Users

Health-active adults (primarily 50–75, designed senior-first) who currently manage their own health markers using manual workarounds — spreadsheets, paper files, memory, or scattered PDFs. These are people who are already tracking their health and are motivated to be active participants in their care but are underserved by existing tools.

The defining trait is not age — it is that **they have already tried to solve this problem themselves and failed due to tooling, not motivation.**

We design for a 68-year-old using their phone in a bright doctor's office waiting room. If it works for them, it works for everyone. The reverse is not true. Younger adults (30s–40s) who begin tracking health markers after a wake-up call will benefit from the same tool, but we do not compromise senior-first UX to appeal to them.

**We are explicitly NOT designing for:** the tech-averse senior who doesn't use smartphone apps, the caregiver managing someone else's health (V2), the quantified-self biohacker wanting wearable integration, or the person who wants a full medical records vault.

### Problems We're Solving (Ranked)

1. **Retrieval friction** — Users cannot get a specific health number in under 10 seconds when they need it (doctor's office, casual conversation, self-monitoring). Current workarounds (spreadsheets on mobile, Google Drive, memory) take 3–4 minutes or fail entirely.

2. **Invisible trends** — No way to see if a marker is improving or declining over time without printing stacks of paper from multiple labs and manually comparing numbers across years.

3. **Input friction** — Entering health data is so cumbersome that people skip it, creating gaps. Existing workarounds (Google Forms → Sheets) punish the user for trying.

4. **No actionable preparation** — Patients show up to appointments without questions or context, so doctors drive the entire conversation. Patients are passive because they don't know what to ask.

### Key Insight

Patients don't need another place to store documents. They need their numbers at their fingertips so they can own the conversation with their doctor.

The problem isn't storage — it's **recall + context + agency.** This reframes the product from "health record storage" to "empowering patients to co-pilot their care."

> *"If I have the numbers at my fingertips, I can be informed and we can make the decision together. But if I don't know, then he makes the decision by himself and I can't do anything... it's about health ownership."*
> — Discovery interview participant

### MVP Thesis

If we give health-active adults a mobile tool that makes entering and retrieving health markers 10x faster than their current workaround, they will build a habit of recording after appointments and reviewing before them — turning passive patients into prepared ones.

**The falsifiable behavior:** A user who enters data at least twice returns to view it before their next appointment. Entry creates the data. Retrieval before a visit proves the value. If that loop doesn't happen, the product isn't working regardless of how the charts look.

---

## 2. MVP Goals & Success Metrics

### Primary Goals

1. **Reduce health marker lookup time from minutes to seconds** — with an easy-to-navigate, delightful, senior-first design. The 10-second benchmark is the north star. Everything we build should serve this.

2. **Reduce friction of adding data** — Quick-add for single markers (under 15 seconds) and batch entry for lab panels (under 90 seconds for 5–6 markers). This should feel effortless, not like homework.

3. **Visualize trends with charts and graphs over time** — Chart-first detail views that make direction obvious at a glance. Seniors process visual patterns faster than data tables.

4. **Enable visit preparation and post-visit capture** — AI-generated doctor questions based on flagged trends (on the Visits tab), plus a simple post-visit notes scratchpad tied to a date and doctor.

### Primary Success Metrics

- Marker lookup completes in **under 10 seconds** (task timing in usability tests)
- New single-marker entry completes in **under 15 seconds**
- Batch entry of 5–6 markers completes in **under 90 seconds**
- **≥60%** of active users view their data in the week before a doctor appointment
- AI-generated doctor questions rated "useful" by **≥70%** of testers

### Secondary Success Signals

- Users enter data within 48 hours of receiving results
- Users who enter 5+ markers return to the app at least weekly
- Users log post-visit notes for ≥50% of their appointments

### Non-Goals for V1

- We are not trying to replace patient portals
- We are not trying to achieve comprehensive medical records
- We are not optimizing for user acquisition or virality — this is a depth-of-value play, not a growth play
- We are not building a backend or cloud service

### Deferred to Future Phases

- EHR/portal connections and FHIR integration
- Document upload and OCR scanning of PDFs/photos
- Medication tracking and management
- Multi-profile and caregiver access with permissions
- Conversational AI or medical advice chatbot
- Calendar sync, appointment reminders, and notifications
- Integration with wearables or Apple Health
- Configurable visit eligibility rules and "due soon" dashboard
- Custom marker groups/bundles for batch entry
- Integrated visit-marker timeline visualization
- Export/share formatted visit briefs for clinicians
- Dark mode
- Landscape orientation

---

## 3. Target Users & Jobs to Be Done

### Primary Persona — "The Health-Active Tracker"

Mid-50s to mid-70s, managing 1–3 chronic conditions (cholesterol, liver, pre-diabetes, blood pressure). Already tracking their health using bad tools. Has multiple providers. Goes to the doctor several times a year between specialists and primary care. Motivated, not passive. Technically capable enough to use a smartphone daily but frustrated by spreadsheets on mobile.

They've already engineered workarounds — Google Forms feeding into multi-tab spreadsheets, printed lab stacks, handwritten notes. The pain is severe enough to drive action. Our job is to replace that entire system with something that takes 10% of the effort.

### Jobs to Be Done (Ranked)

**JTBD #1: "Tell me my number right now."**
Trigger: doctor visit, conversation with friend, self-monitoring moment. They need a specific marker value in under 10 seconds. This is the job Glance is named after. If we don't nail this, nothing else matters.

**JTBD #2: "Help me see if I'm getting better or worse."**
Trigger: got new lab results, want to compare to 6 months ago or 2 years ago. They need a trend visualization — a chart that tells a story, not a spreadsheet of raw numbers. Seeing your HDL improve after a diet change is the emotional payoff.

**JTBD #3: "Make it painless to record my numbers."**
Trigger: just left the doctor, sitting in the car, have 5 minutes. They need to enter data before they forget, without it feeling like work. Quick-add for one-offs, batch entry for lab panels. Two entry patterns for two distinct moments.

**JTBD #4: "Tell me what to talk about at my next appointment."**
Trigger: appointment coming up, not sure what to ask. They need AI-generated prompts based on their flagged trends. This is the health ownership moment — the transition from passive patient to prepared advocate.

**JTBD #5: "Let me capture what the doctor said before I forget."**
Trigger: just walked out of the appointment, doctor rattled off advice and a medication name. They need a fast scratchpad tied to the visit so they can reference it later. Simple free text — no templates, no structure, just capture.

**JTBD #6: "Tell me when my last visit of this type was."**
Trigger: scheduling a follow-up appointment and needing to ensure insurance coverage intervals are met (e.g., dental cleanings must be 12+ months apart). They need fast access to the date of their last visit by type. The app shows "Last dental cleaning: 8 months ago" — the user does the eligibility math themselves.

---

## 4. Product Principles

These are the decision-making rules that govern every feature, design, and prioritization call. When stuck on a tradeoff, reference these. They also serve as guardrails for development — when a judgment call is needed about implementation, these indicate which direction to lean.

### Principle 1: "At a Glance" — Speed over completeness
The app optimizes for fast retrieval and fast entry above all else. If a feature makes the app more comprehensive but slower to navigate, cut it or defer it. The 10-second lookup benchmark is sacred. Every screen answers a question within seconds. No deep nesting, no multi-step navigation to reach core data, no loading screens between the user and their numbers.

### Principle 2: "Show, don't list" — Visual over tabular
Wherever possible, communicate through charts, color, and visual hierarchy rather than tables, lists, or raw text. A trend chart beats a column of numbers. A color-coded status indicator beats a reference range footnote. Visuals are always the primary communication layer.

### Principle 3: "Empower, don't diagnose" — Guidance, not medical advice
AI features suggest questions and highlight trends. They never diagnose, recommend treatments, or tell the user what to do. The language is always "Consider asking your doctor about X" — never "You should take Y" or "This means Z." This is both a product philosophy and a regulatory boundary.

### Principle 4: "Senior-first, not senior-only" — Accessible by default
Large tap targets, high contrast, readable type, minimal cognitive load. Design for a 68-year-old using their phone in a bright doctor's office waiting room. If it works for them, it works for everyone. Never sacrifice accessibility for aesthetics.

---

## 5. MVP Feature Requirements

### 5.1 Navigation Structure

Three-tab bar at the bottom of the screen:
1. **Markers** — Your health numbers (home screen)
2. **Visits** — Doctor visits and next-visit preparation
3. **Settings** — Marker management, reference ranges, export, about

### 5.2 Onboarding

- Welcome flow introducing Glance's purpose (2–3 screens maximum — seniors abandon long onboarding)
- Marker selection screen: browse a predefined library of ~30 common markers, grouped by category (Heart, Metabolic, Liver, General, etc.)
- Search within the library for quick lookup (type-ahead with synonym support — e.g., "good cholesterol" finds HDL)
- "Add Custom Marker" option at the bottom of the library and as a fallback when search returns no results
- All selected markers appear on the home screen with equal priority
- No account creation, no tutorials, no permissions requests. Get to value as fast as possible.

### 5.3 Markers Tab (Home Screen)

- All tracked markers displayed as **compact single-column rows** (Option B layout): marker name on the left, latest value with unit on the right, trend arrow next to value, status color as left-edge accent bar or dot
- Approximately 6–8 markers visible on screen without scrolling at standard text sizes
- **Trend arrow logic:** Based on the last 3 entries. Consistent increase = up arrow, consistent decrease = down arrow, mixed or fewer than 3 entries = no arrow. Arrow color is contextual (up arrow on HDL is green because higher is better; up arrow on LDL is amber/red because lower is better)
- **Status indicator:** Green (normal), amber (approaching range boundary), red (out of range). Communicated via color AND icon (checkmark, warning triangle, exclamation mark) for colorblind accessibility
- Tapping any marker row navigates to the Marker Detail View
- **Global search bar** at the top, searching across marker names, synonyms, visit notes, and doctor names
- Entry points for Quick-Add and Batch Entry (e.g., "+" floating action button or prominent add button)

### 5.4 Marker Detail View

- **Time-series chart as the hero element** — not a list of values. This is a hard design rule.
- Data points displayed as dots connected by lines using Swift Charts
- Reference range band visible as a shaded horizontal zone on the chart
- Out-of-range points flagged visually (red or amber coloring)
- Chart auto-scales x-axis to data range with sensible date formatting (years for multi-year spans, months for within-a-year, specific dates for recent clusters)
- Below the chart: chronological list of all entries with value, unit, date, and any notes
- Ability to add a new value from this screen
- Ability to edit or delete a past entry (with confirmation dialog for deletes)

### 5.5 Quick-Add Flow

- Tap "+" → select a marker from tracked list → enter value → date defaults to today with option to change → optional note → save
- **Target: complete in under 15 seconds**
- Single-marker, single-value entry optimized for the casual moment

### 5.6 Batch Entry Flow

- Tap "Add Lab Results" → enter date once → scrollable list of all tracked markers with input fields → fill in what you have, skip what you don't → save all at once
- **Target: complete 5–6 markers in under 90 seconds**
- The date entered once applies to all markers in the batch
- Designed for the post-lab-work moment when the user has a sheet with multiple values

### 5.7 Visits Tab

**"Next Visit Prep" section** at the top of the tab:
- Visually distinct from visit cards (light blue tinted background card, tied to the Glance brand)
- Shows AI-generated suggestions based on flagged trends, e.g., "Your LDL has increased across your last 3 readings. Consider asking your doctor whether any changes are recommended."
- Only appears when there are flagged markers. If all markers are normal and no concerning trends exist, this section is simply not displayed.
- Recalculates whenever new marker data is entered (deterministic, instant — no API calls)
- Persistent — does not need to be dismissed. Always visible on the Visits tab when relevant.

**Chronological visit list** below the prep section:
- Most recent visits first
- Each visit card shows: date, doctor name, visit type, and a truncated preview of notes
- Tap into a visit to see full notes
- **"Last [visit type]" display** showing how long ago each type of visit was (e.g., "Last dental cleaning: 8 months ago") — the Level 1 insurance date feature

**Add Visit flow:**
- Date, doctor name (free text), visit type (predefined dropdown: Physical/Annual, Dental, Vision, Specialist, Lab Work, Imaging, Other with free text label), notes (free text scratchpad)
- The visit form is always the same regardless of past or future date

**Empty state** when no visits are logged:
- Warm, encouraging message: "Log your first visit after your next appointment" with a clear add button
- Secondary suggestion: "You can also log past visits to build a richer history"

### 5.8 AI Features (Guardrailed)

All AI features in V1 are **deterministic** — threshold math and trend detection. No LLM calls, no external API calls.

- **Threshold flagging:** When a marker value crosses its reference range boundary (high or low), flag it with a visual indicator (amber/red) on the marker card
- **Trend detection:** When 3+ consecutive readings show a sustained trend in a concerning direction, generate a flag. "Concerning" is contextual — increasing LDL is concerning, increasing HDL is not
- **Doctor question generation:** Translates flags into plain-language suggestions displayed in the "Next Visit Prep" section on the Visits tab
- Language rules: always "Consider asking your doctor about..." or "Your [marker] has been [trending direction] over your last [N] readings." Never "You should," never "This means," never diagnosis/treatment/medication language

### 5.9 Settings

- **Manage Tracked Markers:** Add/remove markers from the predefined library or add custom markers. Reorder display order.
- **Edit Reference Ranges:** Per-marker override of default reference ranges. Framed as "your target ranges," not "medical reference ranges."
- **Export Data:** JSON and CSV backup of all data. Shows a brief notice: "This file contains your health information. Store it securely."
- **Biometric Lock:** Optional Face ID/Touch ID app lock, off by default.
- **About / Legal:** App version, privacy policy link.

### 5.10 Marker Library

The predefined library of ~30 common health markers is a first-class data asset shipped with the app as `MarkerData.json`. Each marker includes:

- Display name (e.g., "HDL Cholesterol")
- Category (Heart, Metabolic, Liver, General, etc.)
- Default unit (e.g., mg/dL)
- Default reference range (low and high boundaries)
- Plausible range (physiological min/max for validation)
- Search aliases/synonyms (e.g., HDL → "good cholesterol," "HDL-C," "high-density lipoprotein")
- Whether higher is better or lower is better (for contextual trend arrow coloring)

This single data asset powers onboarding browsing, search, entry validation, AI flagging logic, and unit display.

---

## 6. Data Model

### Entity Relationship Overview

```
Profile (1) ──── has many ──── UserMarker (many)
                                    │
                                    │ references
                                    ▼
                              MarkerDefinition ──── belongs to ──── MarkerCategory
                                    │
                                    │ (via UserMarker)
                                    ▼
                              MarkerEntry (many)

Visit (standalone, linked to Profile)

VisitPrepInsight (computed at runtime, not persisted)
```

### Entity Definitions

#### Profile
A silent default entity in V1. The user never sees or interacts with it. Exists so that when multi-profile is added in V2, every entity already hangs off a profile ID and migration is trivial.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| name | String | Default: "Me" |
| createdAt | Date | Timestamp of profile creation |

#### MarkerCategory
Groupings for the marker library, used in onboarding browsing and organization.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| name | String | e.g., "Heart," "Metabolic," "Liver," "General" |
| displayOrder | Int | Sort order for category display |

#### MarkerDefinition
The predefined catalog of ~30 markers plus user-created custom markers. Seeded from `MarkerData.json` on first launch.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| displayName | String | e.g., "HDL Cholesterol" |
| category | MarkerCategory | Relationship to category |
| defaultUnit | String | e.g., "mg/dL" |
| defaultReferenceLow | Double? | Lower bound of normal range (nullable for custom markers) |
| defaultReferenceHigh | Double? | Upper bound of normal range (nullable for custom markers) |
| plausibleMin | Double? | Physiological minimum for validation (nullable for custom) |
| plausibleMax | Double? | Physiological maximum for validation (nullable for custom) |
| higherIsBetter | Bool | Determines contextual trend arrow coloring |
| aliases | [String] | Search synonyms, stored as JSON array |
| isSystemDefined | Bool | true for predefined, false for user-created custom |

#### UserMarker
Represents "I chose to track this marker." Personal configuration layer linking a Profile to a MarkerDefinition.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| profile | Profile | Relationship to profile |
| markerDefinition | MarkerDefinition | Relationship to the library marker |
| customReferenceLow | Double? | User override (nullable — if null, use MarkerDefinition defaults) |
| customReferenceHigh | Double? | User override (nullable — if null, use MarkerDefinition defaults) |
| displayOrder | Int | Position on home screen |
| addedAt | Date | When the user started tracking this marker |

#### MarkerEntry
The core data — every recorded health value. Powers charts, trends, and flagging.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| userMarker | UserMarker | Relationship to tracked marker |
| value | Double | The recorded numeric value |
| unit | String | Stored explicitly (usually matches default — future-proofs for unit conversion) |
| dateOfService | Date | When the lab was drawn or measurement taken |
| entryTimestamp | Date | When the user entered it into the app |
| note | String? | Optional free-text note |
| sourceType | String | Enum: "quickAdd", "batchEntry" (extensible for future: "fhirImport", "ocrScan") |

#### Visit
Standalone entity for doctor visit logging.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Primary key |
| profile | Profile | Relationship to profile |
| date | Date | Date of the visit |
| doctorName | String | Free text |
| visitType | String | Predefined enum: "physical", "dental", "vision", "specialist", "labWork", "imaging", "other" |
| visitTypeLabel | String? | Free text label when visitType is "other" |
| notes | String? | Free text scratchpad |
| entryTimestamp | Date | When the user logged this visit |

#### VisitPrepInsight (Computed — Not Persisted)
Generated at runtime by the InsightsEngine. Displayed in the "Next Visit Prep" section.

| Field | Type | Notes |
|-------|------|-------|
| id | UUID | Runtime identifier |
| userMarker | UserMarker | The marker that triggered the insight |
| insightType | String | Enum: "outOfRange", "trendingUp", "trendingDown" |
| suggestionText | String | Plain-language doctor question |
| triggeringValues | [MarkerEntry] | The entries that triggered this insight (for provenance) |
| generatedAt | Date | Timestamp of computation |

### Key Data Model Decisions

- **Reference ranges are always evaluated against current values.** If a user changes their target range, historical entries are re-evaluated against the new range. Simpler implementation, and the user likely *wants* old entries re-evaluated when they update their targets.
- **Profile entity exists in V1 as a silent default.** The user never interacts with it. All entities reference it. Multi-profile migration in V2 is trivial.
- **VisitPrepInsights are computed on the fly**, not persisted. The logic is deterministic and instant with local data. No staleness risk, no storage overhead.
- **sourceType on MarkerEntry is an extensible string enum.** V1 only uses "quickAdd" and "batchEntry," but the field is ready for future import sources.
- **Every entity has a UUID primary key** for clean future sync and export.

### Repository Pattern (Critical Architecture Decision)

All data access goes through a `DataRepository` protocol. No view or view model ever accesses SwiftData directly.

```
protocol DataRepository {
    // Markers
    func getTrackedMarkers() -> [UserMarker]
    func addTrackedMarker(_ definition: MarkerDefinition) -> UserMarker
    func removeTrackedMarker(_ marker: UserMarker)
    func updateMarkerOrder(_ markers: [UserMarker])

    // Entries
    func getEntries(for marker: UserMarker, in dateRange: DateRange?) -> [MarkerEntry]
    func getLatestEntry(for marker: UserMarker) -> MarkerEntry?
    func addEntry(_ entry: MarkerEntry)
    func updateEntry(_ entry: MarkerEntry)
    func deleteEntry(_ entry: MarkerEntry)

    // Visits
    func getVisits(limit: Int?) -> [Visit]
    func getLastVisit(ofType: String) -> Visit?
    func addVisit(_ visit: Visit)
    func updateVisit(_ visit: Visit)
    func deleteVisit(_ visit: Visit)

    // Library
    func getMarkerLibrary() -> [MarkerDefinition]
    func getCategories() -> [MarkerCategory]
    func addCustomMarker(_ definition: MarkerDefinition) -> MarkerDefinition

    // Search
    func search(query: String) -> SearchResults

    // Export
    func exportAllData() -> Data  // JSON
    func exportAsCSV() -> Data
}
```

V1 implementation: `LocalDataRepository` backed by SwiftData.
V2 implementation: `SyncedDataRepository` backed by cloud API — the entire UI layer remains unchanged.

---

## 7. Tech Stack & Architecture

### Platform & Frameworks

| Layer | Technology | Rationale |
|-------|-----------|-----------|
| Platform | Native iOS | Senior-first; best accessibility support |
| UI Framework | SwiftUI | Declarative, composable; Claude Code produces it well; native Dynamic Type and accessibility |
| Persistence | SwiftData | Modern Apple-native; integrates with SwiftUI observation; less boilerplate than Core Data |
| Charts | Swift Charts | Native; supports time-series, area charts, rule marks for reference bands; accessible by default |
| Authentication | LocalAuthentication | Optional biometric app lock (Face ID / Touch ID) |
| Min Deployment Target | iOS 17 | Required for SwiftData; Swift Charts selection features; high adoption among target demographic |

### Architecture: MVVM with Repository Layer

```
┌─────────────────────────────────────────┐
│                 Views                    │
│  (SwiftUI — layout and binding only)    │
└────────────────┬────────────────────────┘
                 │ observes
┌────────────────▼────────────────────────┐
│              ViewModels                  │
│  (screen state, logic, calls Repository) │
└────────────────┬────────────────────────┘
                 │ calls
┌────────────────▼────────────────────────┐
│         DataRepository (protocol)        │
│  ┌─────────────────────────────────┐    │
│  │  LocalDataRepository (SwiftData) │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│              Services                    │
│  InsightsEngine │ SearchService │ Library │
└─────────────────────────────────────────┘
```

**Hard rule:** Views never access SwiftData directly. Always go through the Repository via a ViewModel.

### Project Structure

```
Glance/
├── App/
│   └── GlanceApp.swift
├── Models/
│   ├── Profile.swift
│   ├── MarkerDefinition.swift
│   ├── UserMarker.swift
│   ├── MarkerEntry.swift
│   ├── Visit.swift
│   ├── MarkerCategory.swift
│   └── VisitPrepInsight.swift          (struct, not persisted)
├── Repositories/
│   ├── DataRepository.swift             (protocol)
│   └── LocalDataRepository.swift        (SwiftData implementation)
├── Services/
│   ├── InsightsEngine.swift
│   ├── SearchService.swift
│   └── MarkerLibrary.swift              (loads and manages MarkerData.json)
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
│   ├── MarkerData.json                  (predefined ~30 markers with categories, units, ranges, synonyms)
│   └── PrivacyPolicy.md
└── Extensions/
```

### Dependencies

**Zero external packages for V1.** Everything uses Apple-native frameworks. No CocoaPods, no SPM packages. This keeps the build simple, reduces failure modes, and avoids third-party breaking changes.

### Marker Library Data (`MarkerData.json`)

Shipped as a bundled JSON file. On first launch, the app reads this file and seeds the SwiftData store with MarkerDefinition and MarkerCategory entities. This file powers onboarding, search, entry validation, and AI flagging.

Each entry in the JSON includes: display name, category, default unit, default reference range (low/high), plausible range (min/max), whether higher is better, and an array of search aliases/synonyms.

---

## 8. Design System & UI Spec

### Brand Colors

| Token | Usage | Description |
|-------|-------|-------------|
| Primary Blue | Tab bar selection, primary buttons, chart lines, brand accents | Calm medical blue pulled from the Glance stethoscope logo |
| Status Green | Normal/healthy range indicators | Paired with checkmark icon |
| Status Amber | Watch/approaching range boundary | Paired with warning triangle icon |
| Status Red | Out of range / concerning | Paired with exclamation mark icon |
| Background | App background | Off-white / warm light gray (not pure white — easier on aging eyes in bright environments) |
| Card Background | Card surfaces | White, creating subtle elevation against the off-white background |
| Text Primary | Primary text | Near-black |
| Text Secondary | Supporting text, timestamps, captions | Medium gray |
| Insight Card Background | "Next Visit Prep" card | Light blue tint, tied to brand |

**Design intent:** The app should feel warm, approachable, and calm — more like a trusted journal than a clinical dashboard. Not sterile or institutional.

### Typography

**System font only (SF Pro).** No custom fonts. Renders perfectly at all sizes, supports Dynamic Type natively, no font loading or embedding overhead.

| Level | SwiftUI Style | Usage |
|-------|--------------|-------|
| Large Title | `.largeTitle` | Screen headers ("My Markers," "Visits") |
| Headline | `.headline` | Marker names on cards |
| Body | `.body` | Values, dates, general text |
| Caption | `.caption` | Timestamps, reference range labels, supporting info |

**Critical rule: Never hardcode font sizes.** Always use SwiftUI semantic text styles so Dynamic Type scaling works automatically. Use `@ScaledMetric` for spacing values that should scale proportionally.

### Component Library

Six core reusable components:

**MarkerRow** — Compact single-row home screen component. Marker name left-aligned, value with unit right-aligned, trend arrow next to value, status color as left-edge accent bar or dot. Single tappable row navigating to detail view. ~48–56pt tall at default text size.

**TrendChart** — Hero visualization for marker detail. Swift Charts time-series with point-and-line, shaded reference range band, colored out-of-range points. Handles sparse data gracefully (1 point shows single dot with no line, 2 points shows connected dots, 3+ shows full trend). Auto-scales axes to data range.

**StatusBadge** — Small reusable indicator for normal/watch/high status. Communicates via both color AND icon (green checkmark, amber triangle, red exclamation) for colorblind accessibility.

**VisitCard** — Card for the Visits tab list. Shows date, doctor name, visit type, truncated note preview. Tappable to expand.

**InsightCard** — "Next Visit Prep" card. Light blue tinted background. Shows AI suggestion text with marker name bolded. Subtle icon indicating it's a suggestion. Visually distinct from VisitCards.

**QuickEntrySheet** — Bottom sheet or modal for quick-add and batch entry. Large input fields, big tap targets, clear save button. Feels lightweight and fast.

### Layout Rules

- **Single-column layout** for marker rows on home screen (Option B compact rows)
- Minimum **16pt padding** on screen edges
- Minimum **12pt spacing** between cards/rows
- **Rounded corners** on cards: 12–14pt radius
- **Minimum 44x44pt touch targets** on all interactive elements (Apple HIG, non-negotiable for seniors)

### Empty States

Every screen has a designed empty state:

- **Markers tab, no markers tracked:** Guide to onboarding / marker selection
- **Marker detail, 1 data point:** Single dot on chart, message: "Add another reading to start seeing your trend"
- **Marker detail, 0 data points:** Encouraging prompt to add first reading
- **Visits tab, no visits:** "Log your first visit after your next appointment" with add button, plus "You can also log past visits to build a richer history"
- **Next Visit Prep, no flags:** Section is simply not displayed (no empty card, no "everything looks good")

---

## 9. Error States & Edge Cases

### Data Entry Validation

**Plausible range check:** Each predefined marker includes a physiological min/max (plausible range). Values outside this range trigger a confirmation dialog: "You entered HDL of 890 mg/dL. This seems unusual — would you like to double-check?"

**10x outlier detection:** If a value is roughly 10x off from the user's typical range for that marker (based on their existing entries), suggest the likely intended value: "Did you mean 89?" This feels intelligent and helpful, not patronizing.

**Duplicate detection:** If the same marker, same value, and same date of service already exist, show a soft warning: "You already have an HDL entry of 89 for this date. Add anyway?" Don't block — just flag.

**Future date prevention:** Date picker for marker entries maxes out at today. Lab results don't come from the future. Visits can have future dates (optional future visit logging).

**Custom marker limitations:** Custom markers (user-created) do not get plausible range validation, 10x outlier detection, or AI flagging — these features require predefined data we don't have for custom markers.

### Chart Rendering Edge Cases

- Data points spanning very long time ranges (e.g., one reading in 2015, one in 2025): chart auto-scales x-axis with sensible date formatting
- Outlier values that would blow up the y-axis: use plausible range to cap y-axis or auto-detect statistical outliers and offer to exclude them from the chart view while keeping them in the data
- Sparse data: 0 points = empty state, 1 point = single dot, 2 points = connected dots (no trend arrow), 3+ = full trend with arrow

### Edit and Delete Safeguards

- Editing shows the previous value for comparison
- Deleting requires confirmation: "Delete HDL reading of 89 from Feb 15, 2025?" with clear cancel
- No swipe-to-delete without confirmation — too easy to trigger accidentally for seniors
- Edit and delete accessible via an explicit button in the detail view (not gesture-only)

### Batch Entry Edge Cases

- Single date applies to all markers in the batch
- If a user needs to change the date for one marker after saving, they edit that individual entry
- Empty/skipped fields in batch entry are not saved — no zero-value entries created

---

## 10. Accessibility & UX Constraints

### Dynamic Type (Mandatory)

- Every text element uses SwiftUI semantic text styles (`.title`, `.headline`, `.body`, `.caption`)
- **No hardcoded font sizes anywhere**
- App must remain fully functional and visually coherent at `.accessibilityExtraExtraExtraLarge` Dynamic Type setting
- "Fully functional" means: no clipped text, no overlapping elements, no broken layouts
- Cards and rows grow taller to accommodate larger text — they never truncate
- Use `@ScaledMetric` property wrapper for spacing values that should scale with text
- Generate SwiftUI `#Preview` blocks at both default and `.accessibility3` text sizes for every view

### Touch Targets

- Minimum **44x44 points** on all tappable elements (Apple HIG)
- Especially critical for batch entry fields stacked vertically — must not be too close together

### Color Accessibility

- **Color is never the only signifier.** Green/amber/red status always paired with icons (checkmark, triangle, exclamation mark)
- Text-to-background contrast meets **WCAG AA minimum** (4.5:1 for body text, 3:1 for large text)
- Status colors used as accents (dots, bars, icons, background tints), not as text colors (amber text on white is low contrast)

### VoiceOver

- Every interactive element has a meaningful `.accessibilityLabel()`
- MarkerRow reads as: "HDL Cholesterol, 89 milligrams per deciliter, trending down, within normal range"
- TrendChart has an accessibility summary: "HDL Cholesterol over the past 2 years, 6 readings, trending down from 95 to 89, all within normal range"

### Gesture Constraints

- No reliance on gestures that aren't discoverable (no long-press, no swipe-to-reveal, no double-tap as the only path)
- Every action reachable through a visible button or menu
- Swipe-to-delete is acceptable as a shortcut but must also be available through an explicit edit/delete button

### Screen Size Adaptability

- All layout uses SwiftUI flexible primitives: `ScrollView`, `LazyVStack`, `LazyVGrid`, `.frame(maxWidth: .infinity)`
- **Never use fixed pixel dimensions** for anything containing text
- Never use fixed-height containers that could clip content at large text sizes
- Use `GeometryReader` sparingly — prefer SwiftUI's natural layout system
- Use `LazyVStack` inside `ScrollView` for all lists (markers and visits) for smooth scroll performance
- **Portrait orientation only** in V1

### Preview Testing Matrix

Every view file includes `#Preview` blocks for:
- iPhone SE (3rd generation) — smallest screen
- iPhone 15 — standard
- iPhone 16 Plus — largest

Each at:
- Default Dynamic Type
- Large Dynamic Type
- Accessibility Extra Extra Extra Large

**Nine combinations per screen.** Generated once per view file, scanned visually in Xcode.

---

## 11. Security & Privacy Baseline

### Local Data Protection

- All health data lives in SwiftData **only**
- No storing marker values in UserDefaults
- No writing to plain text files
- No logging health values to the console in production builds
- iOS filesystem encryption (Data Protection) provides encryption at rest when device is locked

### Biometric App Lock

- Optional Face ID / Touch ID lock using the LocalAuthentication framework
- Off by default, configurable in Settings
- Adds a layer of protection if someone accesses an unlocked phone

### Export Security

- Export (JSON/CSV) produces a plain text file containing all health data
- Brief notice shown on export: "This file contains your health information. Store it securely."
- Export file is not encrypted (would make it unusable for most users)

### No Tracking, No Analytics, No Third-Party SDKs

- **Zero analytics frameworks** — no Firebase, no Mixpanel, no Amplitude
- **Zero crash reporting SDKs** that phone home with device data
- **Zero ad-tech SDKs** of any kind
- This is a hard rule for V1. Reduces FTC exposure and builds user trust.
- If analytics are needed later, they will be privacy-preserving and first-party

### Privacy Policy

- Required for App Store listing
- Content: We collect no data. We transmit no data. Everything stays on your device. Export files are created only when you explicitly request them.
- Accessible from Settings tab and linked in the App Store listing
- Included in the repository as `PrivacyPolicy.md`

### Deferred to V2

- Cloud sync encryption strategy
- HIPAA compliance assessment
- Consent management for multi-profile data sharing
- Breach notification procedures (only relevant once data leaves the device)

---

## 12. Testing & Milestones

### Testing Strategy

#### Tier 1: Automated Unit Tests

Claude Code writes and runs these. Failures block progress.

**InsightsEngine (critical — safety-sensitive):**
- Every flag condition (out of range high, out of range low, at boundary)
- Every trend calculation (3 readings up, 3 readings down, mixed, fewer than 3)
- Contextual trend interpretation (higher-is-better vs lower-is-better markers)
- Edge cases: identical readings, single reading, no readings

**Validation logic:**
- Plausible range boundaries for every predefined marker
- 10x outlier detection
- Duplicate entry detection
- Future date rejection

**Repository layer:**
- All CRUD operations for markers, entries, and visits
- Query correctness (by date range, by type, sorting)
- Export serialization (round-trip: export → re-import produces identical data)

**Search/synonym matching:**
- Alias resolution (e.g., "good cholesterol" → HDL)
- Partial match behavior
- Custom marker search

**Target: ≥90% code coverage on Models, Repositories, and Services.**

#### Tier 2: Automated UI Tests (XCTest)

Claude Code writes these. Run in simulator.

**Critical user flows:**
- Onboarding: launch fresh → select markers → arrive at populated home screen
- Quick-add: tap add → select marker → enter value → save → verify appears on home screen
- Batch entry: enter date → fill multiple markers → save → verify all appear
- Navigation: tap marker row → see detail view → back → switch to Visits tab → switch to Settings
- Visit logging: add visit → enter details → save → verify in list
- Search: type query → verify correct results surface

#### Tier 3: Visual Review via Preview Matrix

Every view file includes `#Preview` blocks across the nine-combination matrix (3 devices × 3 text sizes). Reviewed visually in Xcode before marking a task complete.

### Milestones

#### Milestone 1: Foundation (Weeks 1–2)
- SwiftData entities for all models (Profile, MarkerCategory, MarkerDefinition, UserMarker, MarkerEntry, Visit)
- DataRepository protocol and LocalDataRepository implementation
- MarkerData.json with ~30 predefined markers, seeded on first launch
- Full unit test coverage on repository and models
- **Deliverable:** Can programmatically create, read, update, delete all entities. No UI yet.

#### Milestone 2: Core Markers Experience (Weeks 2–4)
- Onboarding flow (marker library browsing, search, selection, custom add)
- Home screen (Markers tab) with compact marker rows
- Marker Detail View with trend chart and entry list
- Quick-add entry flow
- **Deliverable:** A user can onboard, see their markers, tap into detail, add a reading, and see it on the chart.

#### Milestone 3: Batch Entry & Search (Weeks 4–5)
- Batch entry flow
- Global search with synonym support
- Settings screen (marker management, reference range editing)
- **Deliverable:** A user can enter a full lab panel efficiently and find any marker instantly.

#### Milestone 4: Visits & AI Insights (Weeks 5–6)
- Visits tab with visit logging and chronological list
- "Next Visit Prep" section with InsightsEngine-generated suggestions
- Threshold flagging and trend detection on marker cards (status indicators, trend arrows)
- "Last [visit type]" date display
- **Deliverable:** Full app experience end to end.

#### Milestone 5: Polish & Edge Cases (Week 6)
- Empty states for all screens
- Validation dialogs (outlier detection, 10x suggestion, duplicate warning)
- Export/backup feature (JSON and CSV)
- Optional biometric lock
- Accessibility audit against preview matrix
- All UI tests passing
- **Deliverable:** Shippable MVP.

---

## 13. Repo Structure & GitHub Setup

### Branching Strategy

- `main` — always represents the latest stable, working state
- `dev` — active development; merge to main at each milestone completion
- Feature branches off `dev` for major features if needed (e.g., `feature/batch-entry`)
- Post-MVP: `option-a-layout` branch for experimenting with full-card layout vs. compact rows

### README

Generated by Claude Code, includes:
- Project overview (one paragraph)
- Tech stack summary
- How to build and run
- Folder structure with brief descriptions
- How to run tests

### CLAUDE.md / AGENTS.md

A project-level file that Claude Code reads at the start of every session. Contains architecture patterns, design constraints, testing requirements, and the explicit non-scope list. **This is the most important file in the repo for maintaining alignment across development sessions.** (To be drafted as a separate document.)

---

## 14. Explicit Non-Scope & Claude Code Constraints

### Do NOT Build in V1

- No FHIR integration or portal connections
- No document upload or OCR
- No chatbot or conversational AI
- No medication tracking or management
- No multi-profile or caregiver access
- No cloud sync or backend services
- No user accounts or authentication (except optional biometric app lock)
- No notifications, reminders, or scheduling
- No Apple Health or wearable integration
- No dark mode
- No landscape orientation
- No in-app purchases or paywall logic
- No analytics or third-party SDKs of any kind
- No social features or sharing (except raw data export)

### Architecture Constraints

- Views never access SwiftData directly — always go through the Repository via ViewModels
- No third-party dependencies — everything uses Apple-native frameworks
- All text uses semantic SwiftUI text styles — no hardcoded font sizes
- All health data stored exclusively in SwiftData — nothing in UserDefaults, no temp files, no console logging of health values in production
- Every view includes `#Preview` blocks for the 3-device, 3-text-size matrix

### AI / Insights Constraints

- The InsightsEngine never uses the words "diagnosis," "treatment," "medication," or "you should"
- All suggestions framed as "Consider asking your doctor about..." or "Your [marker] has been [trending direction]"
- No risk scores, no severity ratings, no medical terminology beyond marker names
- Insights are deterministic (threshold math and trend detection) — no LLM calls, no external API calls

### Content / Copy Constraints

- All user-facing text in plain language, not medical jargon
- Error messages warm and helpful, not technical
- Empty states encouraging, not blank
- Tone: knowledgeable friend, not clinical system

---

*PRD Version 1.0 — February 18, 2026*
*Ready for development handoff*
