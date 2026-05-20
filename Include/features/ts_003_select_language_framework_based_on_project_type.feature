@TS-003 @regression @wizard @api
Feature: Select language/framework based on project type

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario Outline: GET /api/languages returns the correct language set for each project type
    When the client sends "GET /api/languages?project_type=<project_type>"
    Then the response status is 200
    And the response body JSON path "languages" equals exactly <expected_languages>

    Examples:
      | project_type  | expected_languages                               |
      | Microservice  | ["Java/Spring Boot", "Python/Flask", "Node.js"]  |
      | Batch Job     | ["Java", "Python", "Shell"]                      |
      | Frontend App  | ["React", "Angular", "Vue"]                      |
      | Library       | ["Java", "Python", "TypeScript"]                 |
      | Data Pipeline | ["Python", "Scala"]                              |

  Scenario: Batch Job language list does NOT contain React (FR-L03 explicit requirement)
    When the client sends "GET /api/languages?project_type=Batch%20Job"
    Then the response status is 200
    And the response body JSON path "languages" does NOT contain "React"
    And the response body JSON path "languages" contains "Java"
    And the response body JSON path "languages" contains "Python"
    And the response body JSON path "languages" contains "Shell"

  Scenario: Unknown project_type parameter returns HTTP 400
    When the client sends "GET /api/languages?project_type=UnknownType"
    Then the response status is 400
    And the response body is {"detail": "Unknown project type: 'UnknownType'"}

  Scenario: Language incompatible with selected project type is rejected on project creation
    When the client sends "POST /api/projects" with body:
      """
      {
        "project_name":  "bad-combo",
        "project_type":  "Batch Job",
        "language":      "React"
      }
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Language 'React' is not valid for project type 'Batch Job'"
    And the response body JSON path "detail" contains "Allowed:"
    And the response body JSON path "detail" contains "Java"

  Scenario: Another incompatible combination — Shell with Frontend App — is rejected
    When the client sends "POST /api/projects" with body:
      """
      {
        "project_name": "bad-frontend",
        "project_type": "Frontend App",
        "language":     "Shell"
      }
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Language 'Shell' is not valid for project type 'Frontend App'"

  Scenario: UI language dropdown is disabled before any project type is selected
    Given the user is on the wizard view
    Then the select element with data-testid "input-language" has the "disabled" attribute
    And the placeholder option "— select a project type first —" is selected

  Scenario: Selecting a project type populates and enables the language dropdown
    Given the user is on the wizard view
    When the user selects "Frontend App" from data-testid "input-type"
    Then the browser calls "GET /api/languages?project_type=Frontend+App"
    And the select element with data-testid "input-language" does NOT have the "disabled" attribute
    And the language dropdown contains option "React"
    And the language dropdown contains option "Angular"
    And the language dropdown contains option "Vue"
    And the language dropdown does NOT contain option "Java/Spring Boot"

  Scenario: Switching project type resets and re-populates the language dropdown
    Given the user is on the wizard view
    And the user has selected "Microservice" as project type
    And the language dropdown contains "Java/Spring Boot"
    When the user selects "Data Pipeline" from data-testid "input-type"
    Then the browser calls "GET /api/languages?project_type=Data+Pipeline"
    And the language dropdown contains "Python"
    And the language dropdown contains "Scala"
    And the language dropdown does NOT contain "Java/Spring Boot"
    And the language dropdown does NOT contain "Node.js"

  Scenario: Selecting the placeholder project type re-disables the language dropdown
    Given the user has selected "Library" as project type
    When the user selects the placeholder "— select a type —" from data-testid "input-type"
    Then the select element with data-testid "input-language" has the "disabled" attribute


# =============================================================================
# TS-004 — Enter and validate project name
# BRD: FR-L04, FR-L05, FR-L06
# Name regex: ^[A-Za-z0-9-]+$  (letters, digits, hyphens only; strip() applied first)
# Bug #1: duplicate-name check is commented out — second POST returns 201 instead of 409
# =============================================================================