@camelot
Feature: Camelot key

  # Source AC: SCRUM-35 (DR-6). The wheel is a pushed screen inside the track
  # form; every segment is its own element (camelot.segment, label "8A · Am").

  Background:
    Given I am on a release detail screen

  Scenario: Pick a key on the wheel
    When I add a track "A1" / "Magneze" with key "8A"
    Then the track "A1" has key "8A · Am"

  Scenario: Key is optional
    When I add a track "A1" / "Magneze"
    Then the track "A1" has no key

  Scenario: Editing shows the current key
    Given the release has a track "A1" / "Magneze" with key "8A"
    When I open the track "A1" and its key picker
    Then the selected key is "8A · Am"

  Scenario: Clear a key
    Given the release has a track "A1" / "Magneze" with key "8A"
    When I clear the key of track "A1" and save
    Then the track "A1" has no key

  # Bug found in DR-6: popping the wheel re-ran the form's onAppear, which
  # reloaded every field from the stored track and threw the edits away.
  Scenario: Edits made before opening the wheel are kept
    Given the release has a track "A1" / "Magneze" with key "8A"
    When I rename track "A1" to "Salt Line", open and close the key picker, and save
    Then I see the track "A1" / "Salt Line" in the track list

  Scenario: All 24 keys are offered
    When I start adding a track and open the key picker
    Then the wheel offers 24 keys from "1A · Abm" to "12B · E"
