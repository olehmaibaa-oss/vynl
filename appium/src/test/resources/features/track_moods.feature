@track-moods
Feature: Track moods

  # Source AC: SCRUM-22 (assign moods in the track form) and SCRUM-23 (moods on
  # the track row). The row is how the form's result is observed, so every
  # "shows moods" check reads the release's track list after the form closed.

  Scenario: Tag a new track with several moods
    Given I am on a release detail screen
    When I add a track "A1" / "Magneze" with moods "hypnotic" and "deep"
    Then the track "A1" shows moods "deep, hypnotic"

  Scenario: Moods are optional
    Given I am on a release detail screen
    When I add a track "A1" / "Magneze"
    Then the track "A1" shows no moods

  Scenario: Editing shows the current moods
    Given a release has a track "A1" tagged "dark"
    When I open the track "A1"
    Then the mood "dark" is selected
    And the mood "deep" is not selected

  Scenario: Deselect a mood
    Given a release has a track "A1" tagged "dark" and "driving"
    When I toggle the mood "dark" on track "A1" and save
    Then the track "A1" shows moods "driving"

  # Proves the selection lives in form state until Save: the row is read after
  # cancelling, not the form.
  Scenario: Cancel discards mood changes
    Given a release has a track "A1" tagged "dark"
    When I toggle the mood "minimal" on track "A1" and cancel
    Then the track "A1" shows moods "dark"

  # The only test that proves the row reads the live mood entity rather than a
  # copied string: the rename happens on another screen.
  Scenario: Renaming a mood updates the track row
    Given a release has a track "A1" tagged "dubby"
    When I rename the mood "dubby" to "dub" and return to the release
    Then the track "A1" shows moods "dub"
