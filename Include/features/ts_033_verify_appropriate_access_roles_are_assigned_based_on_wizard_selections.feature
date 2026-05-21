@TS-033 @regression
Feature: Access Roles Assigned Exactly as Specified (Admin, Developer, Read-Only)

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"
    And I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-test-project",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    And the response status should be 201
    And I store the response JSON field "id" as "project_id"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Member with "Admin" role is persisted exactly as "Admin"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "admin@example.com", "role": "Admin"}
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Admin"
    When I send a GET request to "/api/projects/{project_id}"
    Then the "members" array contains an object where "role" equals "Admin"

  Scenario: Member with "Developer" role is persisted exactly as "Developer"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "dev@example.com", "role": "Developer"}
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Developer"

  Scenario: Member with "Read-Only" role is persisted exactly as "Read-Only"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "readonly@example.com", "role": "Read-Only"}
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Read-Only"

  Scenario: All three valid roles can coexist in the same project
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "a@example.com", "role": "Admin"}
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "b@example.com", "role": "Developer"}
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "c@example.com", "role": "Read-Only"}
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{project_id}"
    Then the response JSON field "members" is an array with exactly 3 items

  # ── Negative ──────────────────────────────────────────────

  Scenario: Role "GodMode" is rejected with 400 and error lists valid roles [DOCUMENTS PLANTED BUG #2]
    # BRD FR-L08 + AC-06: invalid roles must return 400.
    # Bug #2 causes the server to return 200 with role persisted as "GodMode".
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "hacker@example.com", "role": "GodMode"}
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "GodMode"
    And the response JSON field "detail" contains "Admin"
    And the response JSON field "detail" contains "Developer"
    And the response JSON field "detail" contains "Read-Only"

  Scenario: Role "admin" (lowercase) is rejected with 400 [DOCUMENTS PLANTED BUG #2]
    # Roles are case-sensitive: "Admin" != "admin"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "lower@example.com", "role": "admin"}
      """
    Then the response status should be 400

  Scenario: Role "DEVELOPER" (all caps) is rejected with 400 [DOCUMENTS PLANTED BUG #2]
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "caps@example.com", "role": "DEVELOPER"}
      """
    Then the response status should be 400

  Scenario: Empty role string is rejected with 400 [DOCUMENTS PLANTED BUG #2]
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "norole@example.com", "role": ""}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-036  Demo Mode Records Access Grants as In-Memory {user_email, role} Tuples
# Impl:   project["members"].append({"user_email": email, "role": req.role})
#         DELETE /api/projects/{id}/members/{email}
#           → Bug #3: returns 200 but does NOT remove member from list
#         FR-L13: non-existent member should return 404 (also broken by Bug #3)
# ════════════════════════════════════════════════════════════