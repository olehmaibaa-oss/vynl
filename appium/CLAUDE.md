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
└── src/test/
    ├── java/vynl/
    │   ├── Hooks.java              @Before/@After — driver lifecycle + capabilities
    │   ├── DriverManager.java      ThreadLocal driver holder
    │   ├── AddReleaseSteps.java    step definitions (no locators — page objects only)
    │   ├── RunCucumberTest.java    JUnit suite entry point
    │   └── pages/
    │       ├── BasePage.java       driver + find/tap/type/isEnabled by accessibility id
    │       ├── CollectionPage.java collection screen
    │       └── AddReleasePage.java add-release form
    └── resources/features/
        └── add_release.feature     Gherkin scenarios
```

Page objects take the driver through the constructor and get it from `DriverManager`
(ThreadLocal), not from a public static field — so parallel execution later doesn't
require touching every page object. Steps instantiate page objects lazily inside each
step rather than as fields, so they never depend on glue-instantiation order vs `@Before`.

`ReleaseDetailPage` and `TrackFormPage` don't exist yet — there are no scenarios for
them, and empty page objects rot.

**Still a young framework.** Remaining gaps (see "Roadmap"): no explicit waits (a blanket
10s implicit wait in Hooks), no retry logic, no reporting, capabilities hardcoded.

---

## Capabilities (in Hooks.java)

```
platformName: iOS
appium:automationName: XCUITest
appium:deviceName: iPhone 17 Pro Max
appium:platformVersion: 26.5
appium:udid: A0EC2CC4-88A7-423A-B851-C59705474E84
appium:bundleId: dev.vynl
appium:processArguments: { args: ["-uitesting"] }
```

**Test isolation:** the `-uitesting` launch argument makes the app use an in-memory SwiftData
store, so every test run starts from a clean database regardless of manual usage. Always pass it.

If the simulator or its UDID changes, the capabilities need updating (`xcrun simctl list devices booted`).

WDA timeouts were raised (`wdaLaunchTimeout` / `wdaConnectionTimeout`) because the first
WebDriverAgent build exceeded the default. `useNewWDA: true` forces a rebuild each run — this can
be turned off once things are stable, to speed runs up.

---

## Accessibility identifiers exposed by the app

These are set in the Swift code and are the contract between app and tests. Match them exactly.

**Collection screen**
- `collection.list` — the releases list
- `collection.releaseRow` — a single release row
- `collection.addReleaseButton` — empty-state "Add Release" CTA
- `collection.toolbarAddButton` — toolbar "+"

**Add / edit release form**
- `addRelease.artistField`, `addRelease.titleField`, `addRelease.genreField` (required)
- `addRelease.labelField`, `addRelease.yearField` (optional)
- `addRelease.statusPicker` (edit mode only — owned/sold)
- `addRelease.saveButton`, `addRelease.cancelButton`

**Release detail screen**
- `releaseDetail.view` — the detail container
- `releaseDetail.trackRow` — a single track row
- `releaseDetail.addTrackButton` — empty-state add-track CTA
- `releaseDetail.toolbarAddTrackButton` — toolbar "+"
- `releaseDetail.editButton`
- `releaseDetail.deleteButton`
- `releaseDetail.confirmDeleteButton`, `releaseDetail.cancelDeleteButton` (delete alert)

**Track add / edit form**
- `trackForm.positionField`, `trackForm.titleField` (required)
- `trackForm.bpmField`, `trackForm.keyField` (optional)
- `trackForm.saveButton`, `trackForm.cancelButton`

### Element-type notes (learned from actual runs)
- Release row **text** resolves as `StaticText` in XCUITest — asserting on the artist/title text is
  more reliable than targeting the row container, whose type is ambiguous.
- The delete confirmation uses `.alert` (not `.confirmationDialog`) deliberately: confirmationDialog
  buttons don't reliably expose accessibility identifiers to UI automation.

---

## App behaviour the tests rely on

**Collection**
- Empty state when there are no releases, with an add CTA.
- Releases listed sorted by artist A–Z; each row shows artist, title, status (Owned/Sold).
- Tapping a row opens the release detail.

**Add release** — required: artist, title, genre. Optional: label, year (numeric only).
Save is disabled until all three required fields are non-empty (whitespace trimmed).
Status defaults to `owned`; there is no status picker in add mode.

**Release detail** — shows artist, title, genre, status, label, year (empty optionals render as "—").
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
2. **Explicit waits** — replace the blanket implicit wait with targeted `WebDriverWait`
   conditions; add a small wait helper. Do this before writing more scenarios, or every
   new scenario inherits the implicit wait and the rewrite touches twenty places
   instead of two.
3. **Config extraction** — move capabilities out of `Hooks.java` into a properties/config
   file so device, platform version and UDID aren't hardcoded. The UDID already breaks
   runs whenever the simulator changes.
4. **More coverage, written by hand** — the remaining Gherkin scenarios already carried as
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

## Conventions

- **Gherkin scenarios come from Jira acceptance criteria.** Each story in the Jira project `SCRUM`
  carries Gherkin AC; scenarios here should mirror them rather than being invented.
- Feature files in `src/test/resources/features/`, step definitions in `src/test/java/vynl/`.
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
