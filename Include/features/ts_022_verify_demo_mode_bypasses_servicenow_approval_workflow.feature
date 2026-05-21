@TS-022 @regression
Feature: Demo Mode Provides Implicit Immediate Approval on Wizard Submission

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: POST /api/projects returns 201 immediately with no intermediate approval state
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-implicit-approve",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    And the response JSON field "id" is a non-empty string
    And the response JSON field "project_name" should equal "demo-implicit-approve"
    And the response JSON field "created_at" is a non-empty string

  Scenario: Created project is immediately visible in GET /api/projects list
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "immediate-project", "project_type": "Library", "language": "Python"}
      """
    And the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the "projects" array contains an object where "project_name" equals "immediate-project"

  Scenario: Created project is immediately retrievable by ID via GET /api/projects/{id}
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "instant-retrieval", "project_type": "Batch Job", "language": "Shell"}
      """
    And the response status should be 201
    And I store the response JSON field "id" as "new_project_id"
    When I send a GET request to "/api/projects/{new_project_id}"
    Then the response status should be 200
    And the response JSON field "project_name" should equal "instant-retrieval"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: POST /api/_reset clears the in-memory PROJECTS store and returns 200
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "to-be-cleared", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And the response status should be 201
    When I send a POST request to "/api/_reset" with no body
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    When I send a GET request to "/api/projects"
    Then the response JSON field "projects" is an empty array

  Scenario: GET /api/projects/{id} returns 404 for a project ID that was never created
    When I send a GET request to "/api/projects/00000000-0000-0000-0000-000000000000"
    Then the response status should be 404
    And the response JSON field "detail" should equal "Project not found"


# ════════════════════════════════════════════════════════════
# TS-028  Repository Naming Follows Organizational Conventions
# Impl:   create_project() validates: re.match(r"^[A-Za-z0-9-]+$", name)
#         → 400 "Project name must contain only ASCII letters, digits, and hyphens"
#         In demo mode "repository" = in-memory project record.
# ════════════════════════════════════════════════════════════