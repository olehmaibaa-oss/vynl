@tracks
Feature: Tracks

  # Source AC: SCRUM-10, plus "Delete a track" from SCRUM-11.

  Scenario: Add a track with every field
    Given I am on a release detail screen
    When I add a track "A1" / "Magneze" with bpm "132" and key "8A"
    Then I see the track "A1" / "Magneze" in the track list
    And the track "A1" keeps bpm "132" and key "8A"

  Scenario: Optional track fields can be left empty
    Given I am on a release detail screen
    When I add a track "A1" / "Magneze"
    Then I see the track "A1" / "Magneze" in the track list

  Scenario Outline: Save is blocked while a required track field is empty
    Given I am adding a track
    When I fill in only the track <field> with "<value>"
    Then saving the track is blocked

    Examples:
      | field    | value   |
      | position | A1      |
      | title    | Magneze |

  # Asserts the persisted value, not the field mid-typing: the display-side
  # filter can lose a keystroke under fast input (SCRUM-27), the save must not.
  Scenario: BPM keeps digits only
    Given I am on a release detail screen
    When I add a track "A1" / "Magneze" typing "12ab3" into bpm
    Then the track "A1" keeps bpm "123"

  Scenario: Edit an existing track
    Given a release has a track "A1" / "Magneze"
    When I rename the track "A1" to "Badger Bite"
    Then I see the track "A1" / "Badger Bite" in the track list
    And the track "A1" / "Magneze" is no longer listed

  # Entered out of order on purpose: entering A1, A2, B1 and reading back
  # A1, A2, B1 would prove nothing about sorting.
  Scenario: Tracks are listed in position order
    Given I am on a release detail screen
    When I add tracks "B1", "A2" and "A1" in that order
    Then the track positions read "A1", "A2", "B1"

  Scenario: Swipe deletes a track
    Given a release has tracks "A1" and "A2"
    When I swipe-delete the track "A1"
    Then the track "A1" is no longer listed
    And the track "A2" is still listed
