@TS-036 @regression
Feature: Demo Mode Access Grants Stored as In-Memory user_email and role Tuples

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"
    And I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "access-grant-project",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    And the response status should be 201
    And I store the response JSON field "id" as "project_id"

  # ── Happy path ────────────────────────────────────────────

  Scenario: POST /api/projects/{id}/members response "member" object contains exactly "user_email" and "role"
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "eng@corp.com", "role": "Developer"}
      """
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "member.user_email" should equal "eng@corp.com"
    And the response JSON field "member.role" should equal "Developer"

  Scenario: Access grant tuple persists in project's members array after addition
    When I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "pm@corp.com", "role": "Admin"}
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{project_id}"
    Then the response status should be 200
    And the "members" array contains an object where "user_email" equals "pm@corp.com"
    And the "members" array contains an object where "role" equals "Admin"

  Scenario: Access grants survive multiple GET requests (in-memory state is stable between calls)
    Given I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "persistent@corp.com", "role": "Read-Only"}
      """
    And the response status should be 200
    When I send a GET request to "/api/projects/{project_id}"
    Then the "members" array contains an object where "user_email" equals "persistent@corp.com"
    When I send a GET request to "/api/projects/{project_id}"
    Then the "members" array contains an object where "user_email" equals "persistent@corp.com"

  Scenario: DELETE /api/projects/{id}/members/{email} removes the member (FR-L12 happy path) [DOCUMENTS PLANTED BUG #3]
    # Bug #3 causes the endpoint to return 200 but NOT remove the member.
    # This test will FAIL on the final assertion until Bug #3 is fixed (AC-07).
    Given I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "alice@corp.com", "role": "Developer"}
      """
    And the response status should be 200
    When I send a DELETE request to "/api/projects/{project_id}/members/alice@corp.com"
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "removed" should equal "alice@corp.com"
    When I send a GET request to "/api/projects/{project_id}"
    Then the "members" array should NOT contain an object where "user_email" equals "alice@corp.com"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: DELETE on non-existent member returns 404 (FR-L13) [DOCUMENTS PLANTED BUG #3]
    # Bug #3 causes all DELETEs (real or not) to return 200, so this will FAIL.
    When I send a DELETE request to "/api/projects/{project_id}/members/ghost@corp.com"
    Then the response status should be 404
    And the response JSON field "detail" should equal "Member not found"

  Scenario: DELETE on non-existent project returns 404
    When I send a DELETE request to "/api/projects/00000000-0000-0000-0000-000000000000/members/any@corp.com"
    Then the response status should be 404
    And the response JSON field "detail" should equal "Project not found"

  Scenario: POST /api/_reset clears all in-memory access grants together with their projects
    Given I send a POST request to "/api/projects/{project_id}/members" with body:
      """
      {"user_email": "tobe-cleared@corp.com", "role": "Admin"}
      """
    And the response status should be 200
    When I send a POST request to "/api/_reset" with no body
    Then the response JSON field "status" should equal "ok"
    When I send a GET request to "/api/projects"
    Then the response JSON field "projects" is an empty array

  Scenario: Members list renders "No members yet." when project has no members (FR-L15)
    Given I navigate to the portal at "http://localhost:8000"
    And I click the element with data-testid "card-add"
    And I select project "access-grant-project" from the element with data-testid "select-project"
    Then the element with data-testid "member-list-empty" is visible
    And the element with data-testid "member-list-empty" text should contain "No members yet."


# ════════════════════════════════════════════════════════════
# TS-045  Success Notification upon Successful Provisioning Completion
# Impl:   Implemented as inline banners (no email in demo mode).
#         wizard-success (data-testid): shows "Project '...' created successfully. ID: ..."
#         wizard-error  (data-testid): shows server detail on failure
#         member-success (data-testid): shows "Added {email} as {role}."
#         member-error   (data-testid): shows server detail on failure
# ════════════════════════════════════════════════════════════