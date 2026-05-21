@TS-005 @regression
Feature: Team Member Addition with Role Assignment

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"
    And I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "member-test-project",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    And the response status should be 201
    And I store the response JSON field "id" as "project_id"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Add a member with "Admin" role returns 200 with member record
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "member.user_email" should equal "alice@example.com"
    And the response JSON field "member.role" should equal "Admin"

  Scenario: Add a member with "Developer" role returns 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "bob@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Developer"

  Scenario: Add a member with "Read-Only" role returns 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "carol@example.com",
        "role": "Read-Only"
      }
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Read-Only"

  Scenario: Added member appears in subsequent GET /api/projects/{id} response
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "dave@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{project_id}"
    Then the response status should be 200
    And the "members" array contains an object where "user_email" equals "dave@example.com"
    And the "members" array contains an object where "role" equals "Developer"

  Scenario: A newly created project has an empty members array
    When I send a GET request to "/api/projects/{project_id}"
    Then the response status should be 200
    And the response JSON field "members" is an empty array

  # ── Edge cases ────────────────────────────────────────────

  Scenario: Duplicate email check is case-insensitive — second add returns 409 (AC-10)
    Given I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "Alice@Example.com", "role": "Developer"}
      """
    And the response status should be 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "alice@example.com", "role": "Admin"}
      """
    Then the response status should be 409
    And the response JSON field "detail" should equal "Member already in project"

  Scenario: Multiple different members can be added to the same project
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "eng1@corp.com", "role": "Admin"}
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "eng2@corp.com", "role": "Developer"}
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{project_id}"
    Then the response JSON field "members" is an array with exactly 2 items

  # ── Negative ──────────────────────────────────────────────

  Scenario: Add member with email missing @ sign returns 400
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "not-an-email",
        "role": "Developer"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Valid email is required"

  Scenario: Add member with empty email returns 400
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {
        "user_email": "",
        "role": "Developer"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Valid email is required"

  Scenario: Add member to non-existent project returns 404
    When I send a POST request to "/api/projects/00000000-0000-0000-0000-000000000000/members" with body:
      """
      {
        "user_email": "ghost@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 404
    And the response JSON field "detail" should equal "Project not found"

  Scenario: Same email added twice in a row returns 409 on the second attempt
    Given I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "dup@example.com", "role": "Developer"}
      """
    And the response status should be 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "dup@example.com", "role": "Admin"}
      """
    Then the response status should be 409
    And the response JSON field "detail" should equal "Member already in project"


# ════════════════════════════════════════════════════════════
# TS-006  Smart Decisions and Narrowed-Down Options
# Impl:   GET /api/languages?project_type=<type>
#         LANGUAGES_BY_TYPE dict in app.py
#         POST /api/projects validates language vs project type
# ════════════════════════════════════════════════════════════