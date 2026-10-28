@genres
Feature: Genres

  # Source AC: SCRUM-33 (DR-4). Genre uniqueness in the store ("no second genre
  # is created") is proven in vynlTests GenreTests; here the UI side: the chip
  # takes the collection's spelling.

  Scenario: Add a release with two genres
    Given I am on the add-release form with artist and title filled
    When I add the genres "Techno" and "Dub Techno"
    And I save the release and open it
    Then the release shows the genres "Dub Techno, Techno"

  Scenario: An existing genre is suggested
    Given a release "Surgeon" / "Internal Empire" / "Dub Techno" exists
    When I start adding a release and type the genre "dub"
    Then "Dub Techno" is suggested

  Scenario: Typing an existing genre in another case reuses its spelling
    Given a release "Surgeon" / "Internal Empire" / "Dub Techno" exists
    When I start adding a release and add the genre "dub techno"
    Then the form's genres read "Dub Techno"

  Scenario: Remove a genre before saving
    Given I am on the add-release form with artist and title filled
    When I add the genres "Techno" and "Minimal"
    And I remove the genre "Minimal"
    Then the form's genres read "Techno"

  Scenario: Edit adds a genre
    Given I am on a release detail screen
    When I edit the release and add the genre "Minimal"
    Then the release shows the genres "Minimal, Techno"

  # AUTO-4's deferred "clearing genre" case, now that genres are chips.
  Scenario: Removing the last genre blocks saving
    Given I am on a release detail screen
    When I edit the release and remove the genre "Techno"
    Then Save is disabled
