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

### Design refresh (SCRUM-28 → epic SCRUM-29): IN PROGRESS

The 27 Oct design kickoff changed the MVP: grid + covers move into it, a stack mode, multiple
genres, Camelot keys, grouped moods, dark only. Decisions are in the PRD and Tech Spec (27.10
changelogs) and the review thread on SCRUM-28. Delivered as stories DR-1…DR-8 (SCRUM-30…37) and
E2-S5 / E2-S6 (SCRUM-38, 39). **Done: DR-1 (dark only), DR-2 (schema v2). Built, in review:
DR-3 (header).** The rest is not — see the data model below for what is "today" vs "planned".

**Collection draft v0 (27.10, comments on SCRUM-28/31/32/34/36/37, Tech Spec v4).** Mockup: Claude
Design "VYNL Font Options" (https://claude.ai/artifact/KcWS1eMYnvkvJujGf7Fd1a).
- **Stack (DR-7):** a card is **collapsed** by default: die-cut sleeve, artist, title, "N tracks"
  ("N/M" while a filter is active). A tap **expands it in place**: the record slides out, label ·
  year, genres, tracklist. It collapses on a tap, on **Hide tracks**, or on a swipe to the next
  card. One card expanded at a time; the stack opens collapsed. A long tracklist scrolls inside the
  card. The release opens from the **Open release** button (in the grid a tap still opens it).
  **Add to crate** is hidden until E4.
- **No visible Collection title (DR-3):** `navigationTitle` is kept for VoiceOver and the back
  button but not drawn. Crates keeps its large title.
- **Filter = a bar above the tab bar + a sheet (E3):** iOS 26 `tabViewBottomAccessory`, iOS 18–25
  `safeAreaInset(edge: .bottom)`. The sheet holds BPM range with presets Exact / ±3 / ±6, the
  Camelot wheel, moods by group, genres; footer "Show N records" / "Reset". The empty-result state
  is not drawn yet.
- **Sort placement is OPEN (DR-8):** proposal is a Sort section inside the filter sheet.
  `filter.sortChip` is TBD; `sort.option` stays.
- **`Release.coverColor` (DR-2, DR-5):** see the data model.
- Not covered by draft v0 yet: the grid in the new style, the empty filter bar, sort placement, font.

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
Release >──< Genre           many-to-many (the collection's genre vocabulary)
Track >──< MoodTag           many-to-many (fixed vocabulary)
Crate ──< CrateItem          a crate has many items                              [E4]
CrateItem → Release          an item references one release                      [E4]
CrateItem ──< Track          + the marked tracks from that release               [E4]
```

Schema **v2** is built (DR-2, SCRUM-31): `AppSchema.version = 2`, models Release, Track, MoodTag,
Genre. The UI still shows v1 screens; the stories after DR-2 bring the UI for each field.

### Release — IMPLEMENTED (v2)
- artist: String — required
- title: String — required
- label: String? — optional
- year: Int? — optional
- status: ReleaseStatus — default .owned, changed in the edit form. Not an E3 filter.
- `genres: [Genre]` — many-to-many, inverse + nullify declared on `Genre.releases`. "At least one"
  is enforced by the form (DR-4). `genreNames` gives them A–Z.
- `cover: Data?` — `@Attribute(.externalStorage)`; nil → a placeholder computed from artist +
  title, never stored. Picked and downscaled in DR-5.
- `coverColor: String?` — `"#RRGGBB"`: the colour that contrasts most with the average among the
  colours covering ≥ ~5% of the cover. Computed when a cover is saved (DR-5), cleared when it is
  removed; placeholders derive theirs from their seed and store nothing.
- `dateAdded: Date` — set in init (`.now`), never edited. For "recently added" sort.
- one-to-many to Track, **cascade delete**

### Track — IMPLEMENTED (v2); the wheel comes in DR-6
- position: String — required (e.g. "A1", "B2")
- title: String — required
- bpm: Int? — optional
- to-one back to its Release
- many-to-many to MoodTag (`moods`)
- key: `CamelotKey?` (24 cases 1A–12B), stored as its code in `keyCode: String?` so E3 can use it in
  a predicate; always go through `track.key`. Classic name derived (`classicName`, "Am"), shown as
  `display` ("8A · Am"). Until DR-6 the track form keeps a text field that accepts a code or a
  classic name (`CamelotKey(parsing:)`); anything else saves no key.

### MoodTag — IMPLEMENTED (v2); screen and 30 seeds in E2-S5 (SCRUM-38)
- name: String — stored **as typed**, only trimmed (`MoodTag.clean`; v1 lowercased). Unique
  case-insensitively via `MoodVocabulary.isNameTaken`, deliberately NOT `@Attribute(.unique)`
  (unique makes SwiftData upsert on collision, silently merging a rename). Lists sort A–Z ignoring
  case (`sortedByName()`), not with `@Query(sort:)`.
- group: `MoodGroup` (Dark & Driving, Bright & Emotional, Atmospheric, Groovy, Dub, in that order),
  stored as `groupName: String`; go through `mood.group`.
- many-to-many with Track, nullify both ways
- seeded once per store, tracked by a UserDefaults flag (deleting every mood doesn't reseed)
- today: still the 8 v1 seeds in their v1 lowercase spelling, now with their PRD group (Industrial
  in Dark & Driving, Dubby in Dub, Deep / Atmospheric in Atmospheric). A mood added on the
  vocabulary screen goes to `MoodVocabulary.defaultGroupForNewMoods` until E2-S5 adds the group
  picker. **E2-S5:** the PRD's 30 moods in PRD spelling, grouped screen.

### Genre — IMPLEMENTED (v2); form in DR-4
- name: String — unique case-insensitively, the **first spelling is kept** ("dub techno" never
  creates a second "Dub Techno"): always create through `GenreVocabulary.findOrCreate`
- many-to-many with Release, nullify both ways (deleting a release keeps its genres)
- until DR-4 the release form has one text field, read as a comma-separated list
  (`GenreVocabulary.resolve(list:)`); DR-4 brings chips with suggestions from existing genres

### Crate — LATER (E4)
- name: String — required (e.g. "Friday, [club]")
- date: Date? — optional
- one-to-many to CrateItem
- can be created by importing (a copy of) another crate, whole or selected records

### CrateItem — LATER (E4)
- references one Release; holds the set of marked Tracks from that release
- guarantees integrity: marked tracks are physically tied to their release, no orphans

### Data migrations (Tech Spec §4)
- **Now (no real data yet):** a schema change resets the store. `StoreReset` (DR-2) does it,
  keyed on an explicit version: `AppSchema.version` vs `storeSchemaVersion` in UserDefaults (a
  store with no recorded version is v1). Different → delete the store files (+ `-wal`, `-shm`,
  the external-storage folder), clear the mood "seeded" flag, log it (`dev.vynl` / `store`). A
  container that fails to open for any other reason still crashes (`fatalError`), so a real bug
  isn't swallowed. **Any model change: bump `AppSchema.version`.** Store path:
  `AppSchema.storeURL` (Application Support/default.store). `-uitesting` is in-memory, no reset.
  Checked on the simulator with a real v1 store: v2 resets it and starts with the seeded moods;
  the same store without the reset does not open.
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
- Each tab owns its own `NavigationStack`. **Today:** Collection is a list; Crates shows a
  placeholder.
- **Header (DR-3, built):** Collection's actions (moods gear, "+") are one `ToolbarItemGroup` on
  the right; the grid/stack toggle joins it in DR-7. Collection draws **no visible title**:
  `navigationTitle("Collection")` stays (VoiceOver, the back button reads "Collection") and
  `.hiddenNavigationTitle()` blanks the bar. Crates shows the Design System `SectionTitle`
  ("CRATES", screen-title + heavy rule) as content, bar title hidden; no "+" on Crates until E4.
- **Planned:** grid / stack modes replace the list (DR-7): the
  grid opens a release on tap via push with a zoom transition from the cover, the stack expands
  the card in place and opens the release from **Open release**; filter is a bar above the tab bar
  plus a sheet (E3); sort placement open (DR-8).
- The mood vocabulary is a separate screen behind the gear, not a hamburger.

### Appearance
- **Dark only** (DR-1, SCRUM-30, built): `.preferredColorScheme(.dark)` and `.tint(Palette.ink)`
  once at the root in `vynlApp`; sheets and alerts follow.
- **Colours** come from the Design System (Claude Design "VYNL",
  https://claude.ai/artifact/1xL56ScQVjdMTG49ipTmdg, `tokens.json`): one Color Set per token in
  `Assets.xcassets/DesignSystem`, named exactly as the token, reached through `Palette`
  (`Palette.ink`, `Palette.inkMuted`, `Palette.key("8A")`…). **No literal colours in views**
  (`.red`, `.secondary`, `Color.green` are all gone). `PaletteTests` fails if a token's set is
  missing. AccentColor = ink: VYNL has no accent, selection is shown by inversion
  (`invert` fill + `on-invert` text).
- Screens sit on `bg` via `.screenBackground()` (List / Form) or `.fillBackground()` (empty
  states). List and Form rows still use the system's dark grouped cell colour, and system alerts
  keep the system red on destructive buttons; the screens get redrawn in DR-3 / DR-7 anyway.

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
- **Planned ids from Collection draft v0 (Tech Spec v4):**
  - kept: `collection.grid`, `collection.stack`, `collection.record` (in the stack a tap expands
    instead of opening)
  - new in the stack: `collection.trackList`, `collection.trackRow` (label "A2, Salt Line", value
    = moods), `collection.hideTracksButton`, `collection.openReleaseButton`,
    `collection.addToCrateButton` (E4)
  - filter: `filter.bar` (label = summary, value "14 records") replaces `filter.bpmChip` /
    `keyChip` / `moodChip` / `genreChip`, their clear buttons, `filter.resultCount` and
    `filterSheet.closeButton`; `filterSheet.resetButton` (instead of `filter.resetButton`),
    `filterSheet.applyButton` ("Show 14 records"), `bpmFilter.lowerThumb`, `bpmFilter.upperThumb`,
    `bpmFilter.presetChip`, `camelot.segment`, `moodPicker.chip`, `genreFilter.chip`
  - sort: `sort.option` stays, `filter.sortChip` TBD

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
