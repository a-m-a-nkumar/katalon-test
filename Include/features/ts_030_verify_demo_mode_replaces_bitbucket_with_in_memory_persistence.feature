@TS-030 @regression
Feature: Demo Mode In-Memory Project Persistence with Server-Generated UUID

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: POST /api/projects response contains a server-generated UUID "id" field
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "uuid-test",
        "project_type": "Library",
        "language": "TypeScript"
      }
      """
    Then the response status should be 201
    And the response JSON field "id" matches the UUID v4 pattern "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

  Scenario: POST /api/projects response contains all required fields with correct values
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "full-record-test",
        "project_type": "Data Pipeline",
        "language": "Scala"
      }
      """
    Then the response status should be 201
    And the response JSON field "id" is a non-empty string
    And the response JSON field "project_name" should equal "full-record-test"
    And the response JSON field "project_type" should equal "Data Pipeline"
    And the response JSON field "language" should equal "Scala"
    And the response JSON field "members" is an empty array
    And the response JSON field "created_at" is a non-empty string

  Scenario: GET /api/projects lists all in-memory projects
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "project-alpha", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And the response status should be 201
    And I send a POST request to "/api/projects" with body:
      """
      {"project_name": "project-beta", "project_type": "Library", "language": "Java"}
      """
    And the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an array
    And the "projects" array contains an object where "project_name" equals "project-alpha"
    And the "projects" array contains an object where "project_name" equals "project-beta"

  Scenario: GET /api/projects/{id} retrieves a specific project by its UUID
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "single-lookup", "project_type": "Frontend App", "language": "React"}
      """
    And the response status should be 201
    And I store the response JSON field "id" as "created_id"
    When I send a GET request to "/api/projects/{created_id}"
    Then the response status should be 200
    And the response JSON field "id" should equal the stored value "created_id"
    And the response JSON field "project_name" should equal "single-lookup"

  Scenario: GET /api/projects list is ordered by created_at ascending
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "first-project", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And the response status should be 201
    And I send a POST request to "/api/projects" with body:
      """
      {"project_name": "second-project", "project_type": "Batch Job", "language": "Shell"}
      """
    And the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response JSON field "projects[0].project_name" should equal "first-project"
    And the response JSON field "projects[1].project_name" should equal "second-project"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: GET /api/projects returns empty "projects" array after reset
    When I send a POST request to "/api/_reset" with no body
    And I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an empty array

  # ── Negative ──────────────────────────────────────────────

  Scenario: GET /api/projects/{id} returns 404 for a non-existent UUID (FR-L14)
    When I send a GET request to "/api/projects/00000000-0000-0000-0000-000000000000"
    Then the response status should be 404
    And the response JSON field "detail" should equal "Project not found"

  Scenario: Operations on a valid UUID not in the store return 404 (FR-L14)
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "real-project", "project_type": "Library", "language": "Java"}
      """
    And the response status should be 201
    And I store the response JSON field "id" as "real_id"
    When I send a POST request to "/api/_reset" with no body
    And I send a GET request to "/api/projects/{real_id}"
    Then the response status should be 404
    And the response JSON field "detail" should equal "Project not found"


# ════════════════════════════════════════════════════════════
# TS-033  Appropriate Access Roles Assigned Based on Wizard Selections
# Impl:   VALID_ROLES = ("Admin", "Developer", "Read-Only")  in app.py
#         POST /api/projects/{id}/members — role stored as-is in member record
#         Bug #2: role allowlist check is commented out (any string is accepted)
# ════════════════════════════════════════════════════════════