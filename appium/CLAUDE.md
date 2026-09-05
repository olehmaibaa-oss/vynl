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
    │   ├── AddReleaseSteps.java    step definitions
    │   └── RunCucumberTest.java    JUnit suite entry point
    └── resources/features/
        └── add_release.feature     Gherkin scenarios
```

**This is a minimal skeleton, not a mature framework.** Known gaps, to be addressed
incrementally (see "Roadmap"): locators live inline in step definitions, no page objects,
no explicit waits, no retry logic, no reporting.

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

In rough order. Each step is a deliberate move from "scripts that call Appium" toward a real framework.

1. **Page objects** — move locators and screen actions out of step definitions into
   `CollectionPage`, `AddReleasePage`, `ReleaseDetailPage`, `TrackFormPage`.
2. **Explicit waits** — replace the blanket implicit wait with targeted `WebDriverWait` conditions;
   add a small wait helper.
3. **Helpers/utilities** — gesture wrappers (swipe via `mobile: swipe`), screenshots, common flows.
4. **Config extraction** — move capabilities out of `Hooks.java` into a properties/config file so
   device, platform version and UDID aren't hardcoded.
5. **Reporting** — Serenity or Allure, so failures produce readable, machine-parsable output.
6. **More coverage** — the remaining Gherkin scenarios already written as acceptance criteria in Jira
   (validation, edit, cascade delete, swipe-delete).
7. **CI** — GitHub Actions running `mvn test` headlessly.
8. **QA agent** — reads Jira issues in `In QA`, maps them to scenarios, runs them, posts a verdict.

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
