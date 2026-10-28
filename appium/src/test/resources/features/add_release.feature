@add-release
Feature: Add release
  SCRUM-8 / AUTO-1. Genre is required as "at least one genre chip" since DR-4.

  Scenario: Add a release from empty state
    Given the app is launched
    When I add a release with artist "Surgeon", title "Internal Empire" and genre "Techno"
    Then I see the release "Surgeon" in the collection

  Scenario: Add a release from the toolbar
    Given a release "Surgeon" / "Internal Empire" / "Techno" exists
    When I add a release from the toolbar with artist "Regis", title "Gymnastics" and genre "Techno"
    Then I see the release "Regis" in the collection
    And I see the release "Surgeon" in the collection

  Scenario Outline: Save is blocked while <field> is empty
    Given the app is launched
    When I fill the new release form leaving <field> empty
    Then Save is disabled

    Examples:
      | field  |
      | artist |
      | title  |
      | genre  |

  Scenario: Cancel discards the new release
    Given the app is launched
    When I fill the new release form and cancel
    Then the collection is empty

  # SCRUM-27: the year filter could miss a keystroke under fast input
  Scenario: Year keeps digits only
    Given a release with year "19ab97" exists
    When I open it from the collection
    Then the year is "1997"
