@moods
Feature: Mood vocabulary

  # Source AC: SCRUM-21 (E2-S2). The default vocabulary is seeded on every
  # -uitesting launch, so the moods below exist without any setup.

  Scenario: Open the vocabulary from the collection
    Given the app is launched
    When I open the mood vocabulary
    Then the moods read "atmospheric, dark, deep, driving, dubby, hypnotic, industrial, minimal"

  # "Acid" sorts first and is typed with padding and a capital, so the one
  # scenario proves the new mood is stored trimmed, case kept (DR-2: names as
  # typed, v1 lowercased them) and sorted in A–Z ignoring case.
  Scenario: Add a mood
    Given I am on the mood vocabulary
    When I add a mood "  Acid "
    Then the first mood is "Acid"

  # Named kinds rather than literal values: Gherkin trims table cells, so a
  # whitespace-only cell would silently become the empty case twice.
  Scenario Outline: An empty name blocks saving
    Given I am adding a mood
    When the mood name is <kind>
    Then the mood save action is disabled

    Examples:
      | kind            |
      | empty           |
      | whitespace-only |

  Scenario: Duplicate name is rejected
    Given I am adding a mood
    When I enter the mood name "Hypnotic "
    Then the mood save action is disabled
    And I see that the mood already exists

  # The case @Attribute(.unique) would have got wrong: SwiftData would upsert
  # the rename into the existing mood instead of rejecting it.
  Scenario: Renaming onto an existing mood is rejected
    Given I am on the mood vocabulary
    When I start renaming the mood "dubby" to "Deep"
    Then the mood save action is disabled
    And I see that the mood already exists

  Scenario: Rename a mood
    Given I am on the mood vocabulary
    When I rename the mood "dubby" to "dub"
    Then "dub" is in the vocabulary
    And "dubby" is no longer in the vocabulary

  Scenario: Delete a mood
    Given I am on the mood vocabulary
    When I swipe-delete the mood "industrial"
    Then "industrial" is no longer in the vocabulary
