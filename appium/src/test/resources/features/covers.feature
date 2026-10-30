@covers
Feature: Covers

  # Source AC: SCRUM-34 (DR-5). A cover is told apart from the generated
  # placeholder by the accessibility value ("image+label" / "placeholder"), never by
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

  # COV-3 (SCRUM-59): a library photo goes through the crop screen first.
  Scenario: Cancelling the crop leaves the form unchanged
    Given a photo is in the library
    And I am on the add-release form
    When I fill the release, pick the newest photo and cancel the crop
    Then the cover slot still shows the placeholder

  # COV-4 (SCRUM-61): the photo is cleaned up on the crop screen, each step a chip.
  Scenario: Cleanup chips on the crop screen
    Given a photo is in the library
    And I am on the add-release form
    When I fill the release and open the newest photo
    Then the crop chip "enhance" is "on"
    And the crop chip "background" is "off"
    When I tap the crop chip "enhance"
    Then the crop chip "enhance" is "off"
    When I use the crop
    Then the cover slot shows a cover image

  Scenario: Remove a cover
    Given a photo is in the library
    And a release with a cover exists
    When I edit it, remove the cover and save
    Then the release shows the placeholder

  @no-camera
  Scenario: Camera is offered only where there is one
    Given I am on the add-release form
    Then the camera option is not offered
