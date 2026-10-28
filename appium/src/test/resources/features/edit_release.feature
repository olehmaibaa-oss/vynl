@edit-release
Feature: Edit release
  SCRUM-11 / AUTO-4. Removing the last genre is in genres.feature (DR-4).
  Deferred: the status on the collection row (DR-7 replaces the list with grid/stack).

  Background:
    Given I am on a release detail screen

  Scenario: Edited title shows on the detail screen
    When I change the title to "Basictonalvocabulary"
    Then I see "Surgeon", "Basictonalvocabulary" and "Techno" on the detail screen
    And the collection still lists the release

  Scenario Outline: Clearing <field> blocks save
    When I start editing and clear <field>
    Then Save is disabled

    Examples:
      | field  |
      | artist |
      | title  |

  Scenario: Marking a release as sold
    When I change the status to "Sold"
    Then the status is "Sold"

  Scenario: Cancel keeps the original values
    When I change the title to "Changed" and cancel
    Then I see "Surgeon", "Internal Empire" and "Techno" on the detail screen
