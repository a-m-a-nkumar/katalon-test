@TS-006 @regression @wizard @api @ui
Feature: Context-aware option filtering based on selections

  Background:
    Given the portal is running at "http://localhost:8000"

  Scenario: Language dropdown is disabled when no project type is selected
    Given the user is on the wizard view
    Then the select element with data-testid "input-language" has the "disabled" attribute
    And the language dropdown shows only the placeholder option

  Scenario: Language dropdown is enabled and filtered when project type is selected
    Given the user is on the wizard view
    When the user selects "Microservice" from data-testid "input-type"
    Then the select element with data-testid "input-language" does NOT have the "disabled" attribute
    And the language dropdown contains exactly: "Java/Spring Boot", "Python/Flask", "Node.js"
    And the language dropdown does NOT contain "React"
    And the language dropdown does NOT contain "Python"

  Scenario: Language dropdown re-filters when project type changes to Data Pipeline
    Given the user has selected project type "Frontend App" and language "React"
    When the user selects "Data Pipeline" from data-testid "input-type"
    Then the language dropdown is repopulated via "GET /api/languages?project_type=Data+Pipeline"
    And the language dropdown contains "Python"
    And the language dropdown contains "Scala"
    And the language dropdown does NOT contain "React"
    And the language dropdown does NOT contain "Angular"

  Scenario: API rejects project_type/language combination that bypasses UI filtering
    When the client sends "POST /api/projects" with body:
      """
      {
        "project_name": "bypass-attempt",
        "project_type": "Library",
        "language":     "Shell"
      }
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Language 'Shell' is not valid for project type 'Library'"
    And the response body JSON path "detail" contains "Allowed:"

  Scenario: Each project type's language list is mutually exclusive where expected
    When the client sends "GET /api/languages?project_type=Microservice"
    Then the response body JSON path "languages" does NOT contain "React"
    And the response body JSON path "languages" does NOT contain "Shell"
    And the response body JSON path "languages" does NOT contain "Scala"


# =============================================================================
# TS-007 — Validate all inputs before submission
# BRD: FR-L05, FR-L06, FR-L07 (full create_project() validation pipeline)
# =============================================================================