@delete
Feature: Delete release

  # Source AC: SCRUM-11 (delete scenarios).
  #
  # "Delete cascades to tracks" is NOT here on purpose. Orphaned tracks
  # (release == nil) render nowhere in the E1 UI, so a UI test cannot tell a
  # working cascade from a broken one — recreating the release and seeing an
  # empty track list passes either way. Cascade is proven at the model level in
  # vynlTests/CascadeDeleteTests.swift, which does go red when .cascade is
  # switched to .nullify.

  Scenario: Deleting a release asks for confirmation
    Given I am on a release detail screen
    When I tap delete release
    Then I see the delete confirmation

  Scenario: Confirming removes the release from the collection
    Given a release has tracks "A1" and "A2"
    When I delete the release and confirm
    Then the collection is empty

  Scenario: Cancelling keeps the release
    Given a release has tracks "A1" and "A2"
    When I tap delete release and cancel
    Then the release is still open with its details
    And the track "A1" is still listed
    And the collection still lists the release
