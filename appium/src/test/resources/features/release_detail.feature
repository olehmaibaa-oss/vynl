Feature: Release detail

  Scenario: Release detail shows the entered values
    Given a release "Surgeon" / "Internal Empire" / "Techno" exists
    When I open it from the collection
    Then I see "Surgeon", "Internal Empire" and "Techno" on the detail screen
    And the status is "Owned"

  Scenario: Empty optional fields render as a placeholder
    Given a release with no label and no year exists
    When I open it from the collection
    Then label and year show the empty placeholder

  Scenario: A release with no tracks shows an empty state
    Given a release exists
    When I open it from the collection
    Then I see the add-track call to action

  # Contract test, not behaviour coverage. ReleaseDetailView renders both controls
  # unconditionally, so this asserts little more than "the detail screen loaded".
  # It is kept because it fails if an identifier is renamed, and AUTO-3, AUTO-4 and
  # AUTO-5 all depend on that contract. It will never go red for an interesting reason.
  Scenario: Edit and add-track entry points are available
    Given I am on a release detail screen
    Then the edit control is available
    And the toolbar add-track control is available
