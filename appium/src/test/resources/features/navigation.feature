@navigation
Feature: Navigation

  # Source AC: SCRUM-18 (NAV-1).

  Scenario: App opens on the Collection tab
    Given the app is launched
    Then the Collection tab is selected
    And I see the collection screen

  Scenario: Crates tab shows a placeholder
    Given the app is launched
    When I switch to the Crates tab
    Then the Crates tab is selected
    And I see the Crates placeholder

  Scenario: Each tab keeps its own navigation stack
    Given I have opened a release from the collection
    When I switch to the Crates tab and back to Collection
    Then I am still on that release's detail screen
