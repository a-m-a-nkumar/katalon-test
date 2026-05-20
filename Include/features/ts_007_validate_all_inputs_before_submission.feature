@TS-007 @regression @wizard @api
Feature: Validate all inputs before submission

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario: All fields valid — project is persisted and HTTP 201 is returned (FR-L07)
    When the client sends "POST /api/projects" with body:
      """
      {
        "project_name": "fully-valid-project",
        "project_type": "Data Pipeline",
        "language":     "Python"
      }
      """
    Then the response status is 201
    And the response body JSON path "id" is a non-empty UUID string
    And the response body JSON path "project_name" equals "fully-valid-project"
    And the response body JSON path "project_type" equals "Data Pipeline"
    And the response body JSON path "language" equals "Python"
    And the response body JSON path "members" is an empty array
    And the response body JSON path "created_at" matches ISO-8601 pattern ending in "Z"

  Scenario: Project created via POST is immediately visible in GET /api/projects (FR-L07)
    Given the client created project "visibility-check" with type "Microservice" and language "Node.js"
    When the client sends "GET /api/projects"
    Then the response status is 200
    And the response body JSON path "projects" array contains an object with "project_name": "visibility-check"

  Scenario: Missing project_name in request body returns HTTP 422 (Pydantic)
    When the client sends "POST /api/projects" with body:
      """
      {"project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 422

  Scenario: Missing project_type in request body returns HTTP 422 (Pydantic)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "test", "language": "Python"}
      """
    Then the response status is 422

  Scenario: Missing language in request body returns HTTP 422 (Pydantic)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "test", "project_type": "Microservice"}
      """
    Then the response status is 422

  Scenario: project_name empty string returns HTTP 400 before type/language checks
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name is required"}

  Scenario: Valid name but unknown project_type returns HTTP 400
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "ok-name", "project_type": "Monolith", "language": "COBOL"}
      """
    Then the response status is 400
    And the response body is {"detail": "Unknown project type: 'Monolith'"}

  Scenario: Valid name, valid type, but incompatible language returns HTTP 400
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "ok-name", "project_type": "Frontend App", "language": "Java"}
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Language 'Java' is not valid for project type 'Frontend App'"

  Scenario Outline: Boundary project name values against ^[A-Za-z0-9-]+$ regex
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "<name>", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is <status>

    Examples:
      | name            | status |
      | a               | 201    |
      | A               | 201    |
      | 0               | 201    |
      | abc-123-XYZ     | 201    |
      | -leading-hyphen | 201    |
      | trailing-hyphen-| 201    |
      | bad name        | 400    |
      | bad_name        | 400    |
      | bad.name        | 400    |
      | bad/name        | 400    |
      | bad@name        | 400    |
      | bad!name        | 400    |


# =============================================================================
# TS-016 — Track and display request status to user
# BRD: FR-L01, FR-L07 (GET /api/projects, GET /api/projects/{id})
# =============================================================================