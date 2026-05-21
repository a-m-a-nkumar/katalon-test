@TS-014 @regression
Feature: Language Dropdown Disabled Until Project Type Is Selected

  Background:
    Given I navigate to the portal at "http://localhost:8000"
    And I click the element with data-testid "card-create"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Language select has "disabled" attribute on wizard load before type selection
    Then the element with data-testid "input-language" is disabled
    And the select element with data-testid "input-language" contains only the placeholder option "— select a project type first —"

  Scenario: Language select becomes enabled after selecting Microservice type
    When I select "Microservice" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the select element with data-testid "input-language" has an option with value "Java/Spring Boot"
    And the select element with data-testid "input-language" has an option with value "Python/Flask"

  Scenario: Language select becomes enabled after selecting Frontend App type
    When I select "Frontend App" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the select element with data-testid "input-language" has an option with value "React"
    And the select element with data-testid "input-language" has an option with value "Angular"
    And the select element with data-testid "input-language" has an option with value "Vue"

  Scenario: Language select becomes enabled after selecting Data Pipeline type
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the select element with data-testid "input-language" has an option with value "Python"
    And the select element with data-testid "input-language" has an option with value "Scala"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: Language options refresh when type selection changes from Microservice to Data Pipeline
    Given I have selected "Microservice" from the element with data-testid "input-type"
    And the select element with data-testid "input-language" has an option with value "Java/Spring Boot"
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the select element with data-testid "input-language" has an option with value "Scala"
    And the select element with data-testid "input-language" should NOT have an option with value "Java/Spring Boot"

  # ── Negative ──────────────────────────────────────────────

  Scenario: Selecting the blank placeholder option disables the language dropdown
    Given I have selected "Library" from the element with data-testid "input-type"
    And the element with data-testid "input-language" is not disabled
    When I select the blank placeholder option from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is disabled


# ════════════════════════════════════════════════════════════
# TS-022  Demo Mode Bypasses ServiceNow Approval Workflow
# Impl:   POST /api/projects returns 201 immediately (no approval queue).
#         DEMO_BRD.md § Demo simplifications: "No ServiceNow:
#         approval is implicit on submission"
#         POST /api/_reset resets the PROJECTS in-memory store.
# ════════════════════════════════════════════════════════════