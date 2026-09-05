Feature: Release detail

  Scenario: Release detail shows the entered values
    Given a release "Surgeon" / "Internal Empire" / "Techno" exists
    When I open it from the collection
    Then I see "Surgeon", "Internal Empire" and "Techno" on the detail screen
    And the status is "Owned"

  Scenario: Empty optional fields render as a placeholder
    Given a release with no label and no year exists
    When I open it from the collection
    Then label and year show "—"

  Scenario: A release with no tracks shows an empty state
    Given a release exists
    When I open it from the collection
    Then I see the add-track call to action

  Scenario: Edit and add-track entry points are available
    Given I am on a release detail screen
    Then the edit control is available
    And the toolbar add-track control is available
