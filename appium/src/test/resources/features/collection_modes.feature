@collection-modes
Feature: Collection grid and stack

  # Source AC: SCRUM-36 (DR-7), designer's answers 28.10 (Tech Spec §3);
  # record sheet: SCRUM-42 (29.10, Tech Spec v7 §3).
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

  Scenario: A grid tile opens its record sheet
    When I tap "Halvorsen" in the grid
    Then the record sheet is "Halvorsen, Grey Room"

  Scenario: Open release from a grid tile's sheet
    When I open "Halvorsen" from the collection
    Then the release screen shows "Grey Room" by "Halvorsen"

  Scenario: Switching to stack puts the first record in the middle
    When I switch the collection to stack
    Then the collection is in stack mode
    And the current record is "Halvorsen, Grey Room" with "No tracks"
    And the current record sits in the middle

  Scenario: Swiping the stack moves one record at a time
    When I switch the collection to stack
    And I swipe the stack up
    Then the current record is "Mira Kovac, Night Office"
    When I swipe the stack down
    Then the current record is "Halvorsen, Grey Room"

  Scenario: Tapping a neighbour makes it current without opening its sheet
    When I switch the collection to stack
    And I tap "Mira Kovac" in the stack
    Then the current record is "Mira Kovac, Night Office"
    And no record sheet is open

  Scenario: The current record opens its sheet with its tracks and × closes it
    Given "Halvorsen" has tracks "A1" and "B1"
    When I switch the collection to stack
    And I open the current record's sheet
    Then the record sheet is "Halvorsen, Grey Room"
    And the sheet's tracks read "A1, Track A1" and "B1, Track B1"
    When I close the record sheet
    Then no record sheet is open
    And the current record is "Halvorsen, Grey Room"

  Scenario: A record sheet without tracks says so
    When I switch the collection to stack
    And I open the current record's sheet
    Then the record sheet shows "No tracks yet"

  Scenario: Swiping the record sheet down closes it
    When I switch the collection to stack
    And I open the current record's sheet
    And I swipe the record sheet down
    Then no record sheet is open
    And the current record is "Halvorsen, Grey Room"

  Scenario: Open release from the stack
    When I switch the collection to stack
    And I open the current record's sheet
    And I tap Open release in the sheet
    Then the release screen shows "Grey Room" by "Halvorsen"

  Scenario: The last record also sits in the middle
    When I switch the collection to stack
    And I swipe the stack up
    And I swipe the stack up
    Then the current record is "Sable Drift, Undertow"
    And the current record sits in the middle

  Scenario: Three records don't loop
    When I switch the collection to stack
    Then the stack holds each record once

  Scenario: Four records loop
    Given I add a release from the toolbar with artist "Aster" and title "Lines"
    When I switch the collection to stack
    And I swipe the stack down
    Then the current record is "Sable Drift, Undertow"
    And the current record sits in the middle

  Scenario: The mode is remembered after a relaunch
    When I switch the collection to stack
    And I relaunch the app keeping the mode
    And I add a release from the empty state with artist "Halvorsen" and title "Grey Room"
    Then the collection is in stack mode
    And the current record is "Halvorsen, Grey Room"
    And the current record sits in the middle

  Scenario: Deleting the last record from the stack shows the empty state
    When I switch the collection to stack
    And I delete every release from the stack
    Then I see the collection screen
