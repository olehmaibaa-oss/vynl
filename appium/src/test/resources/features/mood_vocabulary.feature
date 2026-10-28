@moods
Feature: Mood vocabulary

  # Source AC: SCRUM-21 (E2-S2), rewritten for SCRUM-38 (E2-S5): five groups,
  # the PRD's 30 moods in PRD spelling, names kept as typed. The vocabulary is
  # seeded on every -uitesting launch, so these moods exist without setup.

  Scenario: The vocabulary is grouped
    Given the app is launched
    When I open the mood vocabulary
    Then the groups read "Dark & Driving, Bright & Emotional, Atmospheric, Groovy, Dub"
    And "Dark & Driving" lists "Aggressive, Dark, Driving, Hypnotic, Industrial, Minimal, Mysterious, Ominous, Raw"
    And "Dub" lists "Dubby"

  Scenario: The seeded vocabulary matches the PRD
    Given the app is launched
    When I open the mood vocabulary
    Then the vocabulary has 30 moods
    And "Atmospheric" lists "Atmospheric, Chill / Laid back, Deep, Dreamy, Ethereal, Spacey / Cosmic, Trippy / Psychedelic"

  # Typed with padding: stored trimmed, case kept, and sorted into its group.
  Scenario: A new mood goes into the group I choose, as typed
    Given I am on the mood vocabulary
    When I add a mood "  Acid " to "Groovy"
    Then "Groovy" lists "Acid, Bouncy, Energetic, Funky, Groovy, Playful, Sexy / Sensual, Tribal"

  Scenario: A new mood needs a group
    Given I am adding a mood
    When I enter the mood name "Broken"
    Then the mood save action is disabled

  # Named kinds rather than literal values: Gherkin trims table cells, so a
  # whitespace-only cell would silently become the empty case twice.
  Scenario Outline: An empty name blocks saving
    Given I am adding a mood
    When the mood name is <kind>
    And I choose the group "Groovy"
    Then the mood save action is disabled

    Examples:
      | kind            |
      | empty           |
      | whitespace-only |

  Scenario: Duplicates are still rejected regardless of case
    Given I am adding a mood
    When I enter the mood name "hypnotic"
    And I choose the group "Groovy"
    Then the mood save action is disabled
    And I see that the mood already exists

  # The case @Attribute(.unique) would have got wrong: SwiftData would upsert
  # the rename into the existing mood instead of rejecting it.
  Scenario: Renaming onto an existing mood is rejected
    Given I am on the mood vocabulary
    When I start renaming the mood "Dubby" to "deep"
    Then the mood save action is disabled
    And I see that the mood already exists

  Scenario: Rename keeps the group
    Given I am on the mood vocabulary
    When I rename the mood "Dubby" to "Dub Chords"
    Then "Dub" lists "Dub Chords"
    And "Dubby" is no longer in the vocabulary

  Scenario: Delete a mood
    Given I am on the mood vocabulary
    When I swipe-delete the mood "Industrial"
    Then "Industrial" is no longer in the vocabulary
