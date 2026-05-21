@TS-004 @regression
Feature: Project Name Required Field Collection and Validation

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Valid project name is accepted and echoed in the 201 response
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "my-service",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_name" should equal "my-service"

  Scenario: Single-character alphanumeric project name is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "a",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_name" should equal "a"

  Scenario: Mixed-case alphanumeric name with hyphens is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "My-Service-v2",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201

  # ── Edge cases ────────────────────────────────────────────

  Scenario: project_name field missing from request body returns 422
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 422

  # ── Negative ──────────────────────────────────────────────

  Scenario: Empty string project_name returns 400 "Project name is required"
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name is required"

  Scenario: Whitespace-only project_name returns 400 "Project name is required"
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "   ",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name is required"

  Scenario: Project name containing a space returns 400 with format error
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "my project",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Project name containing an exclamation mark returns 400 (AC-04)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "bad name!",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Project name containing an underscore returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "my_project",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Project name containing a dot returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "service.v2",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Project name containing an @ sign returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "service@corp",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"


# ════════════════════════════════════════════════════════════
# TS-005  Optional Team Member Addition with Role Assignment
# Impl:   POST /api/projects/{project_id}/members
#         Body: {"user_email": str, "role": str}
#         Validation: "@" in email → 400 "Valid email is required"
#                     duplicate email (case-insensitive) → 409 "Member already in project"
#                     project missing → 404 "Project not found"
#         Success: 200 {"status":"ok","member":{"user_email":...,"role":...}}
# ════════════════════════════════════════════════════════════