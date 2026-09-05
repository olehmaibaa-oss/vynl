Feature: Add release

  Scenario: Add a release from empty state
    Given the app is launched
    When I add a release with artist "Surgeon", title "Internal Empire" and genre "Techno"
    Then I see the release "Surgeon" in the collection