@covers
Feature: Covers

  # Source AC: SCRUM-34 (DR-5). A cover is told apart from the generated
  # placeholder by the accessibility value ("image" / "placeholder"), never by
  # pixels. The library photo is the fixture fixtures/cover.jpg, added to the
  # simulator's library by the step that needs it.

  Scenario: Placeholder appears as soon as I type
    Given I am on the add-release form
    When I fill in artist "Surgeon" and title "Internal Empire"
    Then the cover slot shows a placeholder for "Surgeon, Internal Empire"

  Scenario: Pick a cover from the library
    Given a photo is in the library
    And I am on the add-release form
    When I fill the release and pick the newest photo
    And I save the release and open it
    Then the release shows a cover image

  Scenario: Remove a cover
    Given a photo is in the library
    And a release with a cover exists
    When I edit it, remove the cover and save
    Then the release shows the placeholder

  @no-camera
  Scenario: Camera is offered only where there is one
    Given I am on the add-release form
    Then the camera option is not offered
