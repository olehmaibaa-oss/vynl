@collection-modes
Feature: Collection grid and stack

  # Source AC: SCRUM-36 (DR-7), designer's answers 28.10 (Tech Spec §3).
  # Test launches always start in grid; "-uitesting-keepMode" keeps the stored mode.

  Background:
    Given the collection holds:
      | artist      | title        |
      | Sable Drift | Undertow     |
      | Halvorsen   | Grey Room    |
      | Mira Kovac  | Night Office |

  Scenario: Grid shows two records per row
    Then the collection is in grid mode
    And the grid rows read:
      | Halvorsen, Grey Room | Mira Kovac, Night Office |
      | Sable Drift, Undertow |                         |

  Scenario: A grid tile opens its release
    When I open "Halvorsen" from the collection
    Then the release screen shows "Grey Room" by "Halvorsen"

  Scenario: Switching to stack puts the first record in the middle
    When I switch the collection to stack
    Then the collection is in stack mode
    And the current record is "Halvorsen, Grey Room" with "0 tracks"

  Scenario: Swiping the stack moves one record at a time
    When I switch the collection to stack
    And I swipe the stack up
    Then the current record is "Mira Kovac, Night Office"
    When I swipe the stack down
    Then the current record is "Halvorsen, Grey Room"

  Scenario: Tapping a neighbour makes it current without expanding
    When I switch the collection to stack
    And I tap "Mira Kovac" in the stack
    Then the current record is "Mira Kovac, Night Office"
    And the current record is collapsed

  Scenario: The current record expands with its tracks and Hide tracks collapses it
    Given "Halvorsen" has tracks "A1" and "B1"
    When I switch the collection to stack
    And I expand the current record
    Then the expanded record is "Halvorsen, Grey Room"
    And the expanded tracks read "A1, Track A1" and "B1, Track B1"
    When I tap Hide tracks
    Then the current record is collapsed

  Scenario: Tapping the expanded sleeve collapses it
    When I switch the collection to stack
    And I expand the current record
    And I tap the expanded sleeve
    Then the current record is collapsed

  Scenario: Swiping an expanded record collapses it and moves on
    When I switch the collection to stack
    And I expand the current record
    And I swipe the expanded record up
    Then the current record is collapsed
    And the current record is "Mira Kovac, Night Office"

  Scenario: Open release from the stack
    When I switch the collection to stack
    And I expand the current record
    And I tap Open release
    Then the release screen shows "Grey Room" by "Halvorsen"

  Scenario: The mode is remembered after a relaunch
    When I switch the collection to stack
    And I relaunch the app keeping the mode
    And I add a release from the empty state with artist "Halvorsen" and title "Grey Room"
    Then the collection is in stack mode
    And the current record is "Halvorsen, Grey Room"

  Scenario: Deleting the last record from the stack shows the empty state
    When I switch the collection to stack
    And I delete every release from the stack
    Then I see the collection screen
