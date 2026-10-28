@sort
Feature: Collection sort

  # Source AC: SCRUM-37 (DR-8). Entry point per the PO decision 28.10: the filter
  # bar opens the filter sheet, Sort is its top section, Apply applies.

  Scenario Outline: Sort the collection
    Given the collection holds, in this order:
      | artist         | title  | year |
      | Surgeon        | Ignite | 1998 |
      | Regis          | Gymnastics | 2001 |
      | Abdulla Rashim | Unanimity | 2012 |
    When I sort by "<sort>"
    Then the record artists read "<order>"
    And the filter bar reads "3 records, <sort>"

    Examples:
      | sort           | order                          |
      | Artist A–Z     | Abdulla Rashim, Regis, Surgeon |
      | Artist Z–A     | Surgeon, Regis, Abdulla Rashim |
      | Year           | Surgeon, Regis, Abdulla Rashim |
      | Recently added | Abdulla Rashim, Regis, Surgeon |

  Scenario: Sort by title
    Given the collection holds, in this order:
      | artist | title  | year |
      | Aaa    | Zero   |      |
      | Bbb    | Atom   |      |
      | Ccc    | Mantra |      |
    When I sort by "Title"
    Then the record titles read "Atom, Mantra, Zero"

  Scenario: Releases without a year sort last when sorting by year
    Given the collection holds, in this order:
      | artist | title | year |
      | Aaa    | One   |      |
      | Zzz    | Two   | 1998 |
    When I sort by "Year"
    Then the record artists read "Zzz, Aaa"

  Scenario: The sheet marks the current sort and discards an unapplied choice
    Given the collection holds, in this order:
      | artist | title | year |
      | Aaa    | One   |      |
    When I open the filter sheet
    Then the selected sort option is "Artist A–Z"
    When I pick "Year" and close the sheet without applying
    Then the filter bar reads "1 record, Artist A–Z"

  Scenario: Sort applies to both modes and survives switching
    Given the collection holds, in this order:
      | artist         | title  | year |
      | Surgeon        | Ignite | 1998 |
      | Regis          | Gymnastics | 2001 |
      | Abdulla Rashim | Unanimity | 2012 |
    And I sort by "Recently added"
    When I switch the collection to stack
    Then the current record is "Abdulla Rashim, Unanimity"
    When I swipe the stack up
    Then the current record is "Regis, Gymnastics"
    When I switch the collection to grid
    Then the record artists read "Abdulla Rashim, Regis, Surgeon"

  Scenario: Default sort is artist A–Z
    Given the collection holds, in this order:
      | artist  | title | year |
      | Surgeon | One   |      |
      | Regis   | Two   |      |
    Then the record artists read "Regis, Surgeon"
    And the filter bar reads "2 records, Artist A–Z"
