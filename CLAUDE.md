# VYNL — Project Context

> This file is persistent context for the AI coding agent. Read it at the start of every session.
> It describes the WHOLE project so you never build something that contradicts where we're heading —
> but you must build ONLY the story you're currently asked to build. See "Rules for the agent" at the bottom.

---

## What VYNL is

VYNL is a vinyl collection app for DJs. It helps a DJ quickly recall and find tracks in their own
vinyl collection while curating a set (by mood and BPM), and assemble a "crate" of records picked
for a specific gig.

The core value is **fast recall for set curation** — not cataloguing. The killer feature is filtering
the collection by mood + BPM to remember what you have. A crate lets you mark, per record, exactly
which tracks you plan to play, with side/position hints (A2, B1) so you can remember at the decks.

The user is the developer himself: a DJ playing hypnotic / minimal / atmospheric techno from vinyl,
with a collection of tens to hundreds of records.

---

## Progress / current state

### E1 — Collection management: COMPLETE

All six stories shipped:

- **S1** — SwiftData model: `Release`, `Track`, `ReleaseStatus` enum, cascade delete, `ModelContainer` configured in `vynlApp`.
- **S2** — Collection list: `CollectionView` with empty state (`ContentUnavailableView`) and `@Query`-driven list sorted A–Z.
- **S3** — Add release form: `AddReleaseView` with required-field validation (trim whitespace), optional label/year, SwiftData insert on save.
- **S4** — Release detail screen: details section + track list sorted by position, empty-track state, placeholder edit/add-track entry points.
- **S5** — Add/edit tracks: `TrackFormView` with `TrackFormMode` enum (`.add(release:)` / `.edit(track:)`), BPM numeric filter, SwiftData insert and in-place mutation.
- **S6** — Edit/delete release: `AddReleaseView` refactored to `ReleaseFormMode` enum (`.add` / `.edit(release:)`); status `Picker` in edit mode only; delete release with `.alert` confirmation + cascade; swipe-to-delete on individual tracks.

### Navigation shell (NAV-1): DONE

`ContentView` is a `TabView` with two tabs, Collection and Crates, each with its own
`NavigationStack`. Crates shows a placeholder until E4.

### E2 — Mood tags: BUILT (S1–S4 in review)

- **S1** — `MoodTag` model, many-to-many with `Track` (nullify both ways), default vocabulary
  seeded once (`MoodVocabulary`), `AppSchema` as the single list of models.
- **S2** — Mood vocabulary screen behind the gear on Collection: list A–Z, add, rename, delete;
  empty and duplicate names rejected (case/whitespace-insensitive).
- **S3** — Moods section in the track form: toggle rows, saved only on Save.
- **S4** — Track rows on the release detail show their moods (A–Z) under the title. The row's
  accessibility label stays `"A1, Magneze"`; the moods are its accessibility value.

### Design refresh (SCRUM-28 → epic SCRUM-29): PLANNED

The 27 Oct design kickoff changed the MVP: grid + covers move into it, a stack mode, multiple
genres, Camelot keys, grouped moods, dark only. Decisions are in the PRD and Tech Spec (27.10
changelogs) and the review thread on SCRUM-28. Delivered as stories DR-1…DR-8 (SCRUM-30…37) and
E2-S5 / E2-S6 (SCRUM-38, 39). None of it is built yet — see the data model below for what is
"today" vs "planned".

### UI testing

First XCUITest is green: `testAddReleaseFromEmptyState` in `vynlUITests` passes end-to-end, proving accessibility identifiers are reachable from the test runner.

**Test isolation:** `vynlApp` detects the `-uitesting` launch argument and configures SwiftData with `isStoredInMemoryOnly: true`, so every UI test run starts with a clean empty database.

---

## Tech stack & constraints

- **Platform:** iOS 18+
- **Language/UI:** Swift, SwiftUI
- **Persistence:** SwiftData (local only)
- **Networking:** NONE in MVP. The app is fully offline. No Discogs, no AI, no CloudKit yet.
- **Bundle ID:** dev.vynl
- **Targets:** vynl (app), vynlTests (unit), vynlUITests (UI)
- Build & run on the iOS Simulator (signing warnings on the free Personal Team are expected and irrelevant for simulator).

---

## Full data model (the WHOLE picture — for awareness, not for building all at once)

Source of truth: Tech Spec §2 (Confluence), updated after the 27 Oct design kickoff (SCRUM-28).
Six entities. Each one below is marked with what is **in the code today** and what is **planned**
and in which story. Do not build a planned change outside its story.

```
Release ──< Track            a release has many tracks
Release >──< Genre           many-to-many (the collection's genre vocabulary)   [planned DR-2]
Track >──< MoodTag           many-to-many (fixed vocabulary)
Crate ──< CrateItem          a crate has many items                              [E4]
CrateItem → Release          an item references one release                      [E4]
CrateItem ──< Track          + the marked tracks from that release               [E4]
```

### Release — IMPLEMENTED (v1); v2 planned in DR-2 (SCRUM-31)
- artist: String — required
- title: String — required
- label: String? — optional
- year: Int? — optional
- status: ReleaseStatus — default .owned, changed in the edit form. **Stays** in v2; it is only
  dropped from the E3 filter.
- one-to-many to Track, **cascade delete**
- today: `genre: String` — required
- **v2 (DR-2):** `genre` is replaced by `genres` — many-to-many with `Genre`, at least one required
  (DR-4); `cover: Data?` (external storage, downscaled on save; no cover → a placeholder computed
  from artist + title, never stored); `dateAdded: Date` set on insert (for "recently added" sort)

### Track — IMPLEMENTED (v1); key changes in DR-2 / DR-6
- position: String — required (e.g. "A1", "B2")
- title: String — required
- bpm: Int? — optional
- to-one back to its Release
- many-to-many to MoodTag (`moods`)
- today: `key: String?` — free text
- **v2 (DR-2, DR-6):** `key` is a Camelot position, one of 24 values 1A–12B; the classic name (Am,
  F#) is derived, never stored; displayed as `8A · Am`; picked on a Camelot wheel

### MoodTag — IMPLEMENTED (v1, E2-S1); v2 planned in DR-2 / E2-S5 (SCRUM-38)
- name: String — unique case-insensitively, enforced by `MoodVocabulary.isNameTaken`, deliberately
  NOT `@Attribute(.unique)` (unique makes SwiftData upsert on collision, silently merging a rename)
- many-to-many with Track, nullify both ways
- seeded once per store, tracked by a UserDefaults flag (deleting every mood doesn't reseed)
- today: names stored lowercase; 8 seeded moods, flat
- **v2:** names stored **as typed** (only trimmed), uniqueness still case-insensitive;
  `group` — one of Dark & Driving, Bright & Emotional, Atmospheric, Groovy, Dub;
  seeded vocabulary = the PRD list, 30 moods in those 5 groups (Industrial in Dark & Driving,
  Dubby in its own Dub group)

### Genre — PLANNED (DR-2, DR-4)
- name: String — unique case-insensitively, the **first spelling is kept** ("dub techno" never
  creates a second "Dub Techno")
- many-to-many with Release, nullify both ways
- the release form suggests genres that already exist; E3 filters by them

### Crate — LATER (E4)
- name: String — required (e.g. "Friday, [club]")
- date: Date? — optional
- one-to-many to CrateItem
- can be created by importing (a copy of) another crate, whole or selected records

### CrateItem — LATER (E4)
- references one Release; holds the set of marked Tracks from that release
- guarantees integrity: marked tracks are physically tied to their release, no orphans

### Data migrations (Tech Spec §4)
- **Now (no real data yet):** a schema change resets the store. DR-2 implements that reset
  explicitly and logged — it must not become a catch-all that would swallow a real migration bug.
- **From the first build that holds a real collection:** `VersionedSchema` + `SchemaMigrationPlan`,
  every schema change a new version with a migration. The reset goes away then.

---

## Architecture

### Navigation
```
TabView (bottom, native: Liquid Glass on iOS 26, classic bar on 18–25; no search tab)
├── "Collection" tab → one screen, grid / stack modes → release detail → track
└── "Crates" tab     → crate list → crate → crate item                     (content in E4)
Header, trailing: grid/stack toggle and mood gear (Collection only), contextual "+"
```
- Each tab owns its own `NavigationStack`. **Today:** Collection is a list; the gear sits top-left;
  Crates shows a placeholder.
- **Planned:** header actions move to the right with large section titles COLLECTION / CRATES
  (DR-3); "+" on Crates hidden until E4 — no disabled or placeholder controls; grid / stack modes
  replace the list, release detail opens via push with a zoom transition from the cover (DR-7);
  sort in the filter bar (DR-8).
- The mood vocabulary is a separate screen behind the gear, not a hamburger.

### Appearance
- **Dark only** (planned DR-1, SCRUM-30): dark appearance forced once at the root, colours from the
  Design System's colour sets. No hard-coded colours in views. Today the app follows the system.

### Accessibility identifiers — PROJECT-WIDE RULE
Every interactive element gets an `.accessibilityIdentifier(...)` from the very start.
This is critical for Appium/XCUITest automation — without stable IDs, locators are fragile.
- Naming: `screen.element` (e.g. `collection.addReleaseButton`, `trackForm.saveButton`).
- A repeated element shares ONE id and is told apart by its label (`releaseDetail.trackRow` with
  label "A1, Magneze"; planned `collection.record` with label "Artist, Title").
- Selected state (chips, segments, sort options, the stack's current card, marked tracks) is
  exposed as the **Selected** trait. A filter match is a value ("match" / "no match"), not a
  selection.
- Every story's AC names the identifiers of its new elements, and the same names go into the
  Design System's component notes.

### Future architectural note (do NOT build now)
When service-style functions accumulate (saved filter presets, collection stats, export/import,
settings), they will move into a side drawer / hamburger (Instagram style), keeping tabs clean.
Premature in the MVP.

---

## Scope

### MVP (changed by the design kickoff, SCRUM-28)
1. Add / edit / delete a release (release + tracks), **with a cover** (camera or library; generated
   placeholder when there is none), several genres, Camelot key on tracks
2. Collection: **grid with covers + stack mode**, filter and sort on one screen
3. Mood tags (grouped vocabulary) + filter by BPM, key, mood, genre
4. Crate — checkbox mode (create, tick records; inside a crate show marked tracks with positions)
5. Everything local, offline, dark only

### Post-MVP (NOT in the MVP — do not build unless explicitly asked)
- Track preview (manual YouTube link → local audio fallback → nothing)
- Discogs import (cover, tracklist) with a local cache
- Card-based crate ("drawer / dossier" swipe-through of records)
- Folders / collection organisation
- AI: mood auto-tagging, natural-language search, set-curation assistant, AI preview search
- CloudKit sync
- Hamburger / side drawer for service functions

---

## Epics (high level)

- **E1 — Collection management:** add/edit/delete release; release contains tracks. (v1 COMPLETE;
  redesign delta in DR)
- **E2 — Mood tags:** assign mood tags to tracks; a track can have several moods. (v1 built and in
  review; grouped vocabulary in E2-S5 / E2-S6)
- **DR — Design refresh (SCRUM-29):** the delta from the design kickoff — dark only, schema v2,
  header, genres, covers, Camelot key, grid/stack, sort. Order: DR-1 → DR-2 → (DR-3…DR-6,
  E2-S5 → E2-S6) → DR-7 → DR-8.
- **E3 — Search & filtering:** filter by BPM range, key, mood, genre (status is not a filter).
  Result = records with at least one matching track; matching tracks highlighted, "N of M" on the
  record. Track conditions (BPM, key, mood) must match within the same track; genre filters the
  release. One filter shared by grid and stack, kept when switching.
- **E4 — Crate:** create (from scratch or by importing a copy of another crate); add releases from
  the collection or from inside the crate; tracks matching the active filter are marked
  automatically; mark tracks to play; marked / all toggle; counts of records and tracks.

E1 is the foundation. E2, E3, E4 depend on it.

---

## Workflow

Work is tracked in Jira, project `SCRUM` (vynl.atlassian.net). The Confluence space `vynldev`
holds the PRD, the Tech Spec, and a Ways of Working page.

How a story reaches you:

1. **Requirements are settled with the human first** — what the feature is, and what it is not.
2. **A story is written in Jira** with its acceptance criteria as Gherkin scenarios. The AC is
   the definition of done and the direct source for test cases later.
3. **A plan is produced before code.** Describe what you will change and why; the human reviews
   the plan. This is the cheap moment to catch a wrong approach.
4. **Code.** Build only that story.
5. **Review against the AC**, scenario by scenario, not "looks fine".

`To Do → In Progress → In QA → Done`. Only the human moves a ticket to `Done`.

**Gherkin AC is a contract with the test suite.** The Appium framework in `appium/` mirrors
these scenarios rather than inventing its own. If an AC describes behaviour you did not build,
that divergence surfaces later as a test that cannot pass — flag it while implementing instead
of leaving it for the suite to discover.

---

## Testing

- **Unit tests** live in `vynlTests` (Swift Testing): model-level rules the UI can't observe —
  cascade delete, the mood model, seeding. `xcodebuild test -scheme vynl -only-testing:vynlTests`.
- **UI tests** live in the `vynlUITests` target using XCUITest (`XCUIApplication`).
- **Pattern established:** `field.tap()` → `field.typeText(...)` → assert on `app.staticTexts["value"].waitForExistence(timeout:)`. Release row text is a `StaticText` element in XCUITest.
- **Test isolation:** pass `-uitesting` as a launch argument; `vynlApp` switches SwiftData to an in-memory store, giving each run a clean database.
- **Accessibility identifiers** are set on every interactive element from day one — this is what makes tests stable. See architecture note above.
- **Appium framework:** lives in `appium/` in this repo and has its own CLAUDE.md — Java 21 / Maven / Appium XCUITest driver / Cucumber / JUnit 5. It drives the app on the Simulator through the same accessibility identifiers, with page objects in `appium/src/main` and scenarios plus glue in `appium/src/test`. It is the main UI suite going forward; `vynlUITests` stays as the XCUITest sanity check.
- **Next planned:** a one-command run (boot simulator, start Appium, `mvn test`), then CI on a macOS runner.
- **Acceptance criteria** for each story are written as Gherkin scenarios and serve as the direct source for test cases.

---

## Rules for the agent (IMPORTANT)

1. **Build only the current story.** Know the whole picture (above) so you never contradict it,
   but do NOT implement future entities, fields, screens, or "flexibility for later". No speculative
   abstraction. We want a clean skeleton, fast. Over-engineering is a failure, not a bonus.

2. **Respect scope.** If something is marked LATER or post-MVP, do not build it unless the task
   explicitly asks for it. If a task seems to require it, stop and flag it instead of guessing.

3. **Always add accessibility identifiers** to interactive elements, on every screen.

4. **Match the data model exactly** as specified — field names, types, optionality, and the
   cascade-delete rule on Release → Track. Don't add fields that aren't specified.

5. **No networking, no external dependencies** in the MVP. SwiftData + SwiftUI only.

6. **Each task comes with its own Acceptance Criteria.** Treat them as the definition of done and
   self-check against them before declaring the task complete.

7. **Don't narrate or over-explain.** Implement, keep changes scoped to the task, and surface any
   decision that goes beyond the task so the human can confirm.

8. **Keep code idiomatic and simple** for current Swift / SwiftUI / SwiftData on iOS 18+.
   Prefer clarity over cleverness.
