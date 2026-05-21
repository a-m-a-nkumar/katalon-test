@TS-007 @regression
Feature: Server-Side Input Validation Before Project Submission

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: All valid inputs pass server-side validation and return 201
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "validation-pass",
        "project_type": "Batch Job",
        "language": "Python"
      }
      """
    Then the response status should be 201

  # ── Negative — project creation ───────────────────────────

  Scenario: Empty project_name is rejected with 400 "Project name is required"
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name is required"

  Scenario: project_name with invalid characters is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "my project!", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Unknown project_type is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "valid-name", "project_type": "FullStack", "language": "React"}
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "Unknown project type"

  Scenario: Language incompatible with project_type is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "valid-name", "project_type": "Library", "language": "React"}
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "React"
    And the response JSON field "detail" contains "Library"

  Scenario: Request body with all three required fields missing returns 422
    When I send a POST request to "/api/projects" with body:
      """
      {}
      """
    Then the response status should be 422

  # ── Negative — member validation ──────────────────────────

  Scenario: Invalid email (no @ sign) is rejected with 400
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "val-proj", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And the response status should be 201
    And I store the response JSON field "id" as "project_id"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "invalidemail", "role": "Developer"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Valid email is required"

  Scenario: Invalid role value "GodMode" is rejected with 400 [DOCUMENTS PLANTED BUG #2]
    # BRD FR-L08: only "Admin", "Developer", "Read-Only" are valid roles.
    # Bug #2 causes the server to return 200 instead of 400.
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "val-proj-2", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And the response status should be 201
    And I store the response JSON field "id" as "project_id"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "hacker@example.com", "role": "GodMode"}
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "GodMode"
    And the response JSON field "detail" contains "Admin"
    And the response JSON field "detail" contains "Developer"
    And the response JSON field "detail" contains "Read-Only"


# ════════════════════════════════════════════════════════════
# TS-009  Microservice Project Type Language Compatibility
# Impl:   LANGUAGES_BY_TYPE["Microservice"] = ["Java/Spring Boot","Python/Flask"]
#         BRD FR-L03 requires 3 languages: + "Node.js"
#         ⚠ LANGUAGE BUG: Node.js is absent from the matrix (only 2 returned)
# ════════════════════════════════════════════════════════════