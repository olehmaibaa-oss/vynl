# VYNL — Appium Test Framework Context

> Persistent context for the AI coding agent working in this directory.
> This is the **test automation** side of the VYNL project. The iOS app itself lives one level up
> (`../vynl/`, Swift/SwiftUI) and has its own CLAUDE.md — don't modify app code from here.

---

## What this is

A Java/Maven/Appium test framework that runs end-to-end UI tests against **VYNL**, an iOS vinyl
collection app for DJs. The app is built with Swift/SwiftUI/SwiftData, runs on the iOS Simulator,
and exposes stable accessibility identifiers on every interactive element specifically so these
tests can target them.

Repo: https://github.com/olehmaibaa-oss/vynl (monorepo — app + this framework)

---

## Stack

- **Java 21** (Temurin)
- **Maven** — build and dependency management
- **Appium** (`io.appium:java-client`) with the **XCUITest driver**
- **Cucumber-JVM** — Gherkin scenarios
- **JUnit 5** (junit-platform-suite) — test runner
- Selenium version is pinned via `selenium-bom` in `dependencyManagement` — do NOT add a direct
  `selenium-java` dependency, it causes `ContextAware` / `LocationContext` compile errors.

## Running tests

Two terminals:

```bash
# terminal 1 — Appium server (leave running)
appium

# terminal 2 — tests
cd appium
mvn test
```

The iOS Simulator must be booted. First WDA build is slow; subsequent runs are fast.

---

## Current structure

```
appium/
├── pom.xml
└── src/
    ├── main/java/vynl/            ← the framework (no test deps)
    │   ├── config/Config.java      config.properties + -D overrides
    │   ├── driver/DriverManager.java  ThreadLocal driver holder
    │   └── pages/
    │       ├── BasePage.java       explicit waits, tap/type/clearAndType, label predicate,
    │       │                       isButtonEnabled, swipeToDelete, labelsOf, scrollToAndTap
    │       ├── TabBar.java         tab bar component (Collection / Crates)
    │       ├── CollectionPage.java collection screen (+ gear → moods)
    │       ├── AddReleasePage.java add-release form (also the edit form)
    │       ├── ReleaseDetailPage.java  release detail: fields, track rows, delete alert
    │       ├── TrackFormPage.java  add / edit track sheet, mood toggles
    │       ├── MoodVocabularyPage.java  mood vocabulary list
    │       ├── MoodFormPage.java   add / rename mood sheet
    │       └── CratesPage.java     Crates tab (placeholder until E4)
    └── test/
        ├── java/vynl/             ← the tests
        │   ├── RunCucumberTest.java   JUnit suite entry point
        │   ├── hooks/Hooks.java       @Before/@After — driver lifecycle
        │   └── steps/               step definitions (page objects only)
        │       ├── Flows.java          shared data setup (new release, add track)
        │       ├── AddReleaseSteps, ReleaseDetailSteps, TrackSteps,
        │       ├── EditReleaseSteps, GenreSteps, DeleteReleaseSteps, NavigationSteps,
        │       ├── MoodSteps, TrackMoodSteps
        └── resources/
            ├── config.properties   capabilities, timeouts
            └── features/           one tag per file, e.g. -Dcucumber.filter.tags=@tracks
                ├── add_release.feature      @add-release
                ├── edit_release.feature     @edit-release
                ├── genres.feature           @genres
                ├── release_detail.feature   @release-detail
                ├── tracks.feature           @tracks
                ├── delete_release.feature   @delete
                ├── navigation.feature       @navigation
                ├── mood_vocabulary.feature  @moods
                └── track_moods.feature      @track-moods
```

Run one area: `mvn test -Dtest=RunCucumberTest -Dcucumber.filter.tags=@moods -Dwda.useNewWDA=false`.
`-Dtest=RunCucumberTest` matters: without it surefire also runs the Cucumber engine directly and
every scenario executes twice.

**Model-level behaviour lives in `vynlTests` (Swift Testing), not here.** Cascade delete and the
mood model are proven there because the UI can't observe them (orphaned tracks render nowhere).
Run with `xcodebuild test -scheme vynl -only-testing:vynlTests`.

**Gherkin gotcha:** `/` is the alternation operator in Cucumber Expressions. A step like
`a release {string} / {string} exists` must escape it (`\\/` in the Java annotation) — otherwise
`" / "` parses as an empty alternative and glue creation fails for the WHOLE suite, not just
that step.

**The main/test split is deliberate.** `src/main` is framework code and must stay free of
Cucumber and JUnit; `java-client` is `compile` scope, cucumber and junit are `test` scope,
so the compiler enforces it. Guard: `grep -rE "io\.cucumber|org\.junit" src/main` must
print nothing.

`config.properties` stays in `src/test/resources` on purpose. `Config` lives in main but
reads it off the classpath, and test resources are on the classpath at run time. Those are
environment values, not framework code.

`RunCucumberTest` names its glue packages explicitly (`vynl.hooks,vynl.steps`). Scanning is
recursive so plain `vynl` would work too, but a silent glue miss shows up as "0 scenarios"
and is miserable to debug.

Page objects take the driver through the constructor and get it from `DriverManager`
(ThreadLocal), not from a public static field — so parallel execution later doesn't
require touching every page object. Steps instantiate page objects lazily inside each
step rather than as fields, so they never depend on glue-instantiation order vs `@Before`.

Page objects are added when a scenario needs them, not before — empty page objects rot.

**There is no implicit wait.** Every lookup in `BasePage` waits explicitly. Do not add
`implicitlyWait` back: mixing the two makes timings unpredictable, because the implicit
wait applies inside each polling attempt of the explicit one.

Remaining gaps (see "Roadmap"): no screenshot-on-failure, no retry logic, no reporting, no
one-command run, no CI.

---

## Configuration

Capabilities and timeouts live in `src/test/resources/config.properties`, read by
`Config.java`. `Hooks` only assembles them — put no literals there.

Any key can be overridden on the command line without editing the file, which is how CI
and one-off runs should set things:

```bash
mvn test -Dios.udid=A0EC2CC4-88A7-423A-B851-C59705474E84
mvn test -Dwait.elementTimeoutSec=20
```

**`ios.udid=auto`** (the default) resolves to whichever simulator is currently booted, so
a rebuilt or replaced simulator no longer breaks every run. It fails with a clear message
when nothing is booted, or when several simulators are — set an explicit UDID then.

**Two timeouts, used deliberately:** `wait.elementTimeoutSec` for things expected to
appear, `wait.absenceTimeoutSec` (short) for asserting something is NOT there. A negative
check paid at the full element timeout makes a suite crawl.

**Test isolation:** the `-uitesting` launch argument makes the app use an in-memory SwiftData
store, so every test run starts from a clean database regardless of manual usage. Always pass it.

WDA timeouts were raised (`wdaLaunchTimeout` / `wdaConnectionTimeout`) because the first
WebDriverAgent build exceeded the default. `useNewWDA: true` forces a rebuild each run — this can
be turned off once things are stable, to speed runs up.

---

## Accessibility identifiers exposed by the app

These are set in the Swift code and are the contract between app and tests. Match them exactly.

**Tab bar** — no identifiers on tab items; locate by label inside the tab bar ("Collection",
"Crates"). A selected item reports `value="1"`. See `TabBar`.
- `crates.placeholder` — Crates tab content until E4

**Collection screen**
- `collection.moodsButton` — gear in the toolbar, pushes the mood vocabulary
- `collection.list` — the releases list
- `collection.releaseRow` — a single release row
- `collection.addReleaseButton` — empty-state "Add Release" CTA
- `collection.toolbarAddButton` — toolbar "+"

**Add / edit release form**
- `addRelease.artistField`, `addRelease.titleField` (required)
- genres (≥ 1 required): `addRelease.genreInput`, `addRelease.genreChip` (label = genre),
  `addRelease.genreRemoveButton` (label "Remove <genre>"), `addRelease.genreSuggestion` (label =
  genre), `addRelease.genreAddNewButton`; detail: `releaseDetail.genreChip` (label = genre)
- `addRelease.labelField`, `addRelease.yearField` (optional)
- `addRelease.statusPicker` (edit mode only — owned/sold)
- `addRelease.saveButton`, `addRelease.cancelButton`

**Release detail screen**
- `releaseDetail.view` — the detail container
- `releaseDetail.trackRow` — a track row. **label** = `"A1, Magneze"` (position, title — stable
  identity), **value** = its moods `"deep, hypnotic"` (empty when none)
- `releaseDetail.trackMoods` — the mood line inside a row (only rendered when it has moods)
- `releaseDetail.addTrackButton` — empty-state add-track CTA
- `releaseDetail.toolbarAddTrackButton` — toolbar "+"
- `releaseDetail.editButton`
- `releaseDetail.deleteButton`
- `releaseDetail.confirmDeleteButton`, `releaseDetail.cancelDeleteButton` (delete alert)

**Track add / edit form**
- `trackForm.positionField`, `trackForm.titleField` (required)
- `trackForm.bpmField`, `trackForm.keyField` (optional)
- `trackForm.saveButton`, `trackForm.cancelButton`
- `trackForm.moodsSection` — the Moods header
- `trackForm.mood.<name>` — one toggle per mood, e.g. `trackForm.mood.hypnotic`; selected rows
  carry the Selected trait (`selected=true`, `value="1"`)

**Mood vocabulary**
- `moods.list`, `moods.row` (label = mood name), `moods.addButton`
- `moodForm.nameField`, `moodForm.saveButton`, `moodForm.cancelButton`
- `moodForm.duplicateError` — shown when the name is taken

### Element-type notes (learned from actual runs)
- Release row **text** resolves as `StaticText` in XCUITest — asserting on the artist/title text is
  more reliable than targeting the row container, whose type is ambiguous.
- The delete confirmation uses `.alert` (not `.confirmationDialog`) deliberately: confirmationDialog
  buttons don't reliably expose accessibility identifiers to UI automation.
- **`LabeledContent` does not expose its value on its own.** On the release detail screen the
  field "Artist" holding "Surgeon" surfaces as ONE StaticText labelled `Artist, Surgeon` — field
  name and value joined by a comma and a space. A predicate on `label == 'Surgeon'` finds nothing
  there. Go through `ReleaseDetailPage.showsField("Artist", "Surgeon")`, which builds the pair.
- **The release title exists twice on the detail screen**: `ReleaseDetailView` sets
  `.navigationTitle(release.title)`, which surfaces as its own StaticText, and the body renders
  `LabeledContent("Title", …)`. Their labels differ (`Internal Empire` vs `Title, Internal Empire`),
  so a predicate is not ambiguous by accident — but a bare title match asserts the navigation bar,
  not the content. All `ReleaseDetailPage` lookups are nested inside `releaseDetail.view`, which
  holds the body only. Do not use index-based locators to disambiguate.
- `releaseDetail.view` is a `CollectionView`; nested lookups inside it work
  (`ExpectedConditions.visibilityOfNestedElementsLocatedBy`).
- **iOS 26 toolbar buttons appear twice**: an `XCUIElementTypeOther` wrapper with the same
  identifier (always `enabled=true`) and the `XCUIElementTypeButton` inside (truthful). Lookup by
  id returns the wrapper. Read enabled state with `BasePage.isButtonEnabled`; tapping either works.
- **Rows below the keyboard aren't "displayed"**, so `elementToBeClickable` never succeeds for
  them. `BasePage.scrollToAndTap` waits for presence and lets XCUITest's tap scroll the row in.
  `mobile: scroll toVisible` does not work inside a SwiftUI `Form`.
- Swipe-to-delete: `mobile: swipe` left on the row, then tap the system `Delete` action (label
  match — system swipe actions carry no identifier of ours). `BasePage.swipeToDelete`.
- When a new screen's assertions are being written, dump the page source once
  (`GET /session/<id>/source`) rather than guessing how SwiftUI exposes a control. The two notes
  above both came out of a dump and contradicted a reasonable-looking guess.

---

## Coming: design refresh (epic SCRUM-29) — what it will break

Not built yet. Each story's "Automation impact" section in Jira is the detail; the short version,
so nothing here gets "fixed" in the wrong direction before its story lands:

- **DR-7 grid/stack (SCRUM-36)** — the widest change. `collection.list` goes; records become
  `collection.record` with label "Artist, Title" in both modes. `CollectionPage.openRelease` /
  `isReleaseVisible` move to that locator, and every scenario that creates or opens a release
  runs through them. Per Collection draft v0 (Tech Spec v4) a tap opens the release **only in the
  grid**; in the stack it expands the card in place, and the release opens from
  `collection.openReleaseButton`. `-uitesting` starts in the grid, so `openRelease` stays a tap
  there; stack scenarios need their own expand / open steps (`collection.trackList`,
  `collection.trackRow`, `collection.hideTracksButton`).
- **DR-3 header (SCRUM-32), built** — gear moved right next to "+", ids unchanged
  (`CollectionPage.areHeaderActionsOnTheRight` checks both Buttons are past mid-screen). Collection
  draws no title; Crates' "CRATES" is a header StaticText in the content (`CratesPage.showsTitle`),
  the nav bar there is `visible=false`. Crates has no "+" (`CratesPage.hasNoAddButton`).
- **E3 filter** — a bar `filter.bar` (value "14 records") + sheet replaces the planned per-filter
  chips and `filter.resultCount`. Full id list in the root CLAUDE.md.
- **DR-4 genres (SCRUM-33), built** — `AddReleasePage.fillRequired` adds the genre as a chip
  (`addGenre`: type + "\n", waits for the chip, case-insensitive). Also `typeGenre`,
  `tapAddNewGenre`, `chooseSuggestion`, `isSuggested`, `removeGenre` ("Remove <genre>"),
  `genreChips`. Detail: `ReleaseDetailPage.genres()` / `showsGenre` on `releaseDetail.genreChip`
  (the "Genre, Techno" LabeledContent is gone). `genres.feature` (@genres); AUTO-1 outline has a
  `genre` row; AUTO-4's "clear genre" = "Removing the last genre blocks saving" in genres.feature.
  After adding a genre the field keeps focus, so the keyboard stays up over Label/Year.
- **DR-6 Camelot key (SCRUM-35)** — free-text `trackForm.keyField` → `trackForm.keyButton` +
  `camelot.segment`; `TrackFormPage.setKey` becomes a picker.
- **DR-2 schema v2 (SCRUM-31), built** — mood names are stored as typed since DR-2: a mood added
  as `"  Acid "` reads `Acid` (only that scenario changed). Seeds keep their v1 lowercase spelling
  until E2-S5. Track key is a Camelot code now: the key field takes "8A" or "Am" and shows the code.
- **E2-S5 / E2-S6 (SCRUM-38, 39)** — seeds in PRD spelling (`Hypnotic`, not `hypnotic`), grouped
  (`moods.group`), 30 seeds; track-form mood rows `trackForm.mood.<name>` → `trackForm.moodChip`
  by label. `mood_vocabulary.feature` and `track_moods.feature` get rewritten.
- **DR-1 dark only (SCRUM-30), done** — no locator changes; the suite stayed green as-is.

---

## App behaviour the tests rely on

**Collection**
- Empty state when there are no releases, with an add CTA.
- Releases listed sorted by artist A–Z; each row shows artist, title, status (Owned/Sold).
- Tapping a row opens the release detail.

**Add release** — required: artist, title (non-empty, trimmed) and at least one genre chip.
Optional: label, year (numeric only). Save is disabled until all three are there.
Status defaults to `owned`; there is no status picker in add mode.
Year (and track BPM) keep digits only; the app re-filters at save, so fast input can't persist a
letter (SCRUM-27). Cancel discards.

**Edit release** — the same form, pre-filled, plus `addRelease.statusPicker` (a
SegmentedControl; segments are Buttons labelled "Owned" / "Sold", pick by label —
`AddReleasePage.selectStatus`). Save returns to the release detail.

**Release detail** — shows artist, title, genre chips (A–Z), status, label, year (empty optionals
render as "—").
Tracks section lists position + title sorted by position; empty state with an add CTA when there are none.

**Tracks** — required: position (e.g. "A1"), title. Optional: bpm (numeric only), key (free text).
Tapping a track row opens it for editing, pre-filled. Swipe-to-delete removes a track.

**Delete release** — confirmation alert; confirming removes the release *and all its tracks*
(cascade delete), then returns to the collection.

---

## Roadmap for this framework

Ordered by what unblocks what, not by how mature it looks. The goal at the end of this
list is a QA agent that closes the loop: a Jira story moves to `In QA`, the agent reads
the diff and the Gherkin AC, runs the matching scenarios and posts a verdict. Everything
before it exists to make that agent possible and trustworthy.

1. ~~**Page objects**~~ — DONE for `CollectionPage` / `AddReleasePage` (+ `BasePage`,
   `DriverManager`). `ReleaseDetailPage` / `TrackFormPage` come with their scenarios.
2. ~~**Explicit waits**~~ — DONE. Implicit wait removed; `BasePage` waits on presence,
   visibility or clickability, with a short separate budget for negative checks.
3. ~~**Config extraction**~~ — DONE. `config.properties` + `Config.java`, `-D` overrides,
   `ios.udid=auto` resolves the booted simulator.
4. **More coverage, written by hand** — MOSTLY DONE: release detail, tracks, delete, navigation,
   mood vocabulary, track moods (33 scenarios). Still open: AUTO-1 (add-release validation) and
   AUTO-4 (edit release). Originally: the remaining Gherkin scenarios already carried as
   acceptance criteria in Jira (validation, edit, cascade delete, swipe-delete). Four or
   five scenarios covering different interaction shapes (form, list, alert, swipe) are
   not just coverage: they are the corpus the agent later extrapolates its conventions
   from. Written from one example, a generator invents its own style every time.
   Helpers (gesture wrappers, screenshots, common flows) fall out of these scenarios —
   write them when a scenario actually needs one, not speculatively.
5. **One-command run** — a script (or CI job) that boots the simulator, starts Appium,
   runs `mvn test` and reports. The agent needs a closed loop; an agent that writes a
   test but cannot run it is a hypothesis generator.
6. **QA agent, verifier first** — reads Jira issues in `In QA`, reads the diff and the AC,
   maps them to EXISTING scenarios, runs them, posts a verdict as a Jira comment.
   No generation yet. Useful immediately and needs no corpus.
7. **QA agent, generator second** — generates new scenarios and step/page code from AC.
   Needs step 4's corpus and a stable page-object API. Also needs a way to prove a
   generated test actually catches a break (deliberately break the app, the test must
   fail) — a green test that asserts nothing is worse than no test.
8. **CI** — GitHub Actions running the suite on a macOS runner. Worth it once there are
   several scenarios to protect; before that it runs air.

Deliberately parked, and NOT to be implemented speculatively:

- **Reporting (Serenity / Allure)** — cosmetics on top of a suite that barely exists.
  Revisit when failures get hard to read, not before.
- **Maestro** — a separate track that blocks nothing on this line.

---

## Workflow

Work arrives as a Jira ticket in project `SCRUM`, labelled `automation`, under the epic for
the current coverage push. One ticket per session.

`To Do → In Progress → In QA → Done`

- **To Do** — the ticket carries its scenarios, the page objects it touches, and usually a
  comment with app behaviour already verified against the Swift source. Read the ticket, its
  comments, and the story its "Source AC" points to. Don't ask for context that is already there.
- **In Progress** — move it yourself when you pick it up.
- **In QA** — you move it here once the code is written and `mvn test` is green. This does
  **not** mean handed to a tester.
- **Done** — only the human moves a ticket to Done.

**What `In QA` is for.** The failure mode of a test is not going red, it is going green on
nothing: an assertion that is always true, an `isDisplayed()` on an element that is always
present, a step that silently no-ops. None of that shows in a log. It shows only when a person
reads what the scenario actually checks. That review is the gate, which is why the run report
matters more than the exit code.

**Reporting.** Say what each scenario proves, not that N scenarios passed. Name anything you
dropped or changed from the ticket and why. If a scenario turned out to assert nothing, say so
and delete it — a green test that checks nothing is worse than no test, because it buys false
confidence.

**When the app is wrong, not the test.** A test that fails because the app genuinely
misbehaves, or an AC that describes behaviour the app does not have, is a finding. Post it as
a comment on the source story and assert the behaviour that exists. Never edit `../vynl/` from
here, and never bend a scenario until it goes green.

---

## Conventions

- **Gherkin scenarios come from Jira acceptance criteria.** Each story in the Jira project `SCRUM`
  carries Gherkin AC; scenarios here should mirror them rather than being invented.
- Feature files in `src/test/resources/features/`, step definitions in `src/test/java/vynl/steps/`,
  page objects in `src/main/java/vynl/pages/`.
- Keep step definitions readable and behaviour-level; technical detail belongs in page objects
  (once they exist) or helpers.
- Don't use `TouchAction` — it's removed from Appium. Use W3C Actions (`PointerInput`/`Sequence`)
  or `mobile:` commands via `executeScript`.
- Never use `Thread.sleep()`. Use explicit waits.

## Rules for the agent

1. **Only touch the test framework.** The Swift app lives in `../vynl/` and is out of scope here.
   If a test fails because of a genuine app bug, report it — don't fix app code from this directory.
2. **Don't invent accessibility identifiers.** Use the documented list above; if a needed element
   has no identifier, say so rather than guessing a locator.
3. **Build only what's asked.** Know the roadmap so you don't contradict it, but don't implement
   future steps speculatively.
4. **Verify by running.** After changes, run `mvn test` and report the real result rather than
   assuming it passes.
5. Keep changes scoped and explain anything that goes beyond the task so it can be confirmed.
