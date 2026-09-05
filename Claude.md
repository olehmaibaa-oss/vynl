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

Five entities total. **Release and Track are implemented.** MoodTag, Crate, and CrateItem come in later epics.
This whole model is documented here so that when you build an early entity, you don't design
something that will have to be broken later.

```
Release ──< Track            a release has many tracks
Track >──< MoodTag           many-to-many (fixed vocabulary)
Crate ──< CrateItem          a crate has many items
CrateItem → Release          an item references one release
CrateItem ──< Track          + the marked tracks from that release
```

### Release — (IMPLEMENTED)
- artist: String — required
- title: String — required
- label: String? — optional
- year: Int? — optional
- genre: String — required
- status: ReleaseStatus — default .owned
- one-to-many relationship to Track, **cascade delete** (deleting a Release deletes its Tracks)

### Track — (IMPLEMENTED)
- position: String — required (e.g. "A1", "B2")
- title: String — required
- bpm: Int? — optional
- key: String? — optional (e.g. "Am", "8A") — free text in MVP, no Camelot picker
- to-one relationship back to its Release
- (LATER) many-to-many relationship to MoodTag

### MoodTag  — (LATER, epic E2)
- name: String (e.g. "hypnotic", "driving", "atmospheric")
- A **fixed vocabulary**: moods are created once and reused. Modelled as a separate entity
  (not a free-text array) so filters stay clean. Many-to-many with Track.

### Crate — (LATER, epic E4)
- name: String (e.g. "Friday, [club]")
- date: Date? — optional
- one-to-many relationship to CrateItem

### CrateItem — (LATER, epic E4)
- references one Release
- has a set of marked Tracks from that release
- This intermediate entity guarantees integrity: marked tracks are physically tied to their
  release inside the CrateItem, so there can be no orphaned track.

---

## Architecture

### Navigation
```
TabView (bottom)
├── "Collection" tab  → stack: list → release detail → track detail
├── "Crates" tab      → stack: crate list → crate → crate item   (LATER, E4)
└── A gear/settings button → mood vocabulary management           (LATER, E2)
```
- TabView for the two equal zones (Collection / Crates).
- Stack navigation (push/pop) lives inside each tab for drilling into detail.
- In the MVP skeleton only the Collection tab is real. Crates and settings come later.

### Accessibility identifiers — PROJECT-WIDE RULE
Every interactive element gets an `.accessibilityIdentifier(...)` from the very start.
This is critical for Appium/XCUITest automation later — without stable IDs, locators are fragile.
Use clear, stable, descriptive identifiers (e.g. "collection.addReleaseButton",
"release.artistField", "release.saveButton"). Do this on every screen, every story, no exceptions.

### Future architectural note (do NOT build now)
When service-style functions accumulate (saved filter presets, collection stats, export/import,
settings), they will move into a side drawer / hamburger (Instagram style), keeping tabs clean.
Premature in the skeleton.

---

## Scope

### MVP skeleton (build this first, in order)
1. Add / edit / delete a release (release + tracks)
2. Collection — **list view only**
3. Mood tags + filter
4. Crate — checkbox mode (create crate, tick records; inside a crate show marked tracks with positions)
5. Everything local, offline

### Post-MVP (NOT in the skeleton — do not build unless explicitly asked)
- Track preview (manual YouTube link → local audio fallback → nothing)
- Grid view + cover artwork
- Card-based crate ("drawer / dossier" swipe-through of records)
- Folders / collection organisation
- Discogs API (auto-fetch tracklists)
- AI: mood auto-tagging, natural-language search, set-curation assistant, AI preview search
- CloudKit sync
- Hamburger / side drawer for service functions

---

## Epics (high level)

- **E1 — Collection management:** add/edit/delete release; release contains tracks; browse as a list. (COMPLETE)
- **E2 — Mood tags:** assign mood tags to tracks; a track can have several moods. (CURRENT)
- **E3 — Search & filtering:** filter the collection by mood, BPM, genre, status; results at track level.
- **E4 — Crate:** create a crate; add releases (checkboxes); mark tracks to play; view crate with tracks and positions.

E1 is the foundation. E2, E3, E4 depend on it.

---

## Testing

- **UI tests** live in the `vynlUITests` target using XCUITest (`XCUIApplication`).
- **Pattern established:** `field.tap()` → `field.typeText(...)` → assert on `app.staticTexts["value"].waitForExistence(timeout:)`. Release row text is a `StaticText` element in XCUITest.
- **Test isolation:** pass `-uitesting` as a launch argument; `vynlApp` switches SwiftData to an in-memory store, giving each run a clean database.
- **Accessibility identifiers** are set on every interactive element from day one — this is what makes tests stable. See architecture note above.
- **Next planned:** Appium + WebdriverIO (ported framework), then `xcodebuild test` CLI runs, then CI integration.
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
