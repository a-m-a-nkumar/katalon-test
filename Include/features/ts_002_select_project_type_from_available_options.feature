@TS-002 @regression @wizard @api
Feature: Select project type from available options

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario: GET /api/project-types returns all five supported project types
    When the client sends "GET /api/project-types"
    Then the response status is 200
    And the response Content-Type contains "application/json"
    And the response body JSON path "project_types" is an array of exactly 5 items
    And the "project_types" array contains "Microservice"
    And the "project_types" array contains "Batch Job"
    And the "project_types" array contains "Frontend App"
    And the "project_types" array contains "Library"
    And the "project_types" array contains "Data Pipeline"

  Scenario: Wizard project-type dropdown is populated by loadProjectTypes() on page load
    When the user navigates to "/"
    Then the browser calls "GET /api/project-types"
    When the user clicks data-testid "card-create"
    Then the select element with data-testid "input-type" contains option "Microservice"
    And the select element with data-testid "input-type" contains option "Batch Job"
    And the select element with data-testid "input-type" contains option "Frontend App"
    And the select element with data-testid "input-type" contains option "Library"
    And the select element with data-testid "input-type" contains option "Data Pipeline"

  Scenario: Selecting a project type triggers onTypeChange() and enables language dropdown
    Given the user is on the wizard view
    And the select element with data-testid "input-language" is disabled
    When the user selects "Microservice" from data-testid "input-type"
    Then the JavaScript function onTypeChange() fires
    And the browser calls "GET /api/languages?project_type=Microservice"
    And the select element with data-testid "input-language" is enabled

  Scenario: Submitting wizard with no project type selected causes API to return HTTP 400
    Given the user is on the wizard view
    And no project type is selected in data-testid "input-type"
    When the user enters "test-project" in data-testid "input-name"
    And the user clicks data-testid "btn-submit"
    Then the browser sends "POST /api/projects" with body:
      """
      {"project_type": "", "language": "", "project_name": "test-project"}
      """
    And the response status is 400
    And the response body is {"detail": "Unknown project type: ''"}
    And the element with data-testid "wizard-error" is visible
    And the element with data-testid "wizard-error" contains text "Unknown project type: ''"
    And the element with data-testid "wizard-success" is not visible

  Scenario: Changing project type selection multiple times before submitting
    Given the user is on the wizard view
    When the user selects "Microservice" from data-testid "input-type"
    And the user selects "Frontend App" from data-testid "input-type"
    And the user selects "Library" from data-testid "input-type"
    Then the current value of data-testid "input-type" is "Library"
    And the language dropdown does NOT contain "Java/Spring Boot"
    And the language dropdown does NOT contain "React"
    And the language dropdown contains "Java"
    And the language dropdown contains "Python"
    And the language dropdown contains "TypeScript"


# =============================================================================
# TS-003 — Select language/framework based on project type
# BRD: FR-L03 (GET /api/languages?project_type=..., LANGUAGES_BY_TYPE matrix)
# =============================================================================