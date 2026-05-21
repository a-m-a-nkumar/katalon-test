@TS-002 @regression
Feature: Project Type Selection via GET /api/project-types

  Background:
    Given the portal API is running at "http://localhost:8000"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/project-types returns HTTP 200 with JSON
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the response Content-Type header contains "application/json"

  Scenario: GET /api/project-types returns exactly 5 project types
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the response JSON field "project_types" is an array with exactly 5 items

  Scenario: GET /api/project-types contains all supported types
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the "project_types" array contains "Microservice"
    And the "project_types" array contains "Batch Job"
    And the "project_types" array contains "Frontend App"
    And the "project_types" array contains "Library"
    And the "project_types" array contains "Data Pipeline"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: GET /api/project-types response shape is a JSON object with key "project_types"
    When I send a GET request to "/api/project-types"
    Then the response body is a JSON object
    And the response JSON object has the key "project_types"

  Scenario: Project type dropdown is populated from /api/project-types on page load
    Given I navigate to "http://localhost:8000"
    And I click the element with data-testid "card-create"
    Then the select element with data-testid "input-type" has an option with value "Microservice"
    And the select element with data-testid "input-type" has an option with value "Batch Job"
    And the select element with data-testid "input-type" has an option with value "Frontend App"
    And the select element with data-testid "input-type" has an option with value "Library"
    And the select element with data-testid "input-type" has an option with value "Data Pipeline"

  # ── Negative ──────────────────────────────────────────────

  Scenario: GET /api/project-types does not return "Full-Stack App"
    When I send a GET request to "/api/project-types"
    Then the "project_types" array should NOT contain "Full-Stack App"


# ════════════════════════════════════════════════════════════
# TS-003  Language / Framework Options Vary by Project Type
# Impl:   GET /api/languages?project_type=<type>
#         → {"languages": [...]} or 400 {"detail": "..."}
#         Frontend: onTypeChange() calls this and populates input-language
# ════════════════════════════════════════════════════════════