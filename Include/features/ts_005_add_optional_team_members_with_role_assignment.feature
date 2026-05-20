@TS-005 @regression @members @api
Feature: Add team members with role assignment

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And a project was created and its id is stored as {project_id}:
      """
      POST /api/projects
      {"project_name": "team-project", "project_type": "Library", "language": "Python"}
      """

  Scenario: Add a member with role Admin — returns HTTP 200 with member record
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "alice@example.com", "role": "Admin"}
      """
    Then the response status is 200
    And the response body is:
      """
      {"status": "ok", "member": {"user_email": "alice@example.com", "role": "Admin"}}
      """

  Scenario: Add a member with role Developer — returns HTTP 200
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "bob@example.com", "role": "Developer"}
      """
    Then the response status is 200
    And the response body JSON path "member.role" equals "Developer"
    And the response body JSON path "member.user_email" equals "bob@example.com"

  Scenario: Add a member with role Read-Only — returns HTTP 200
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "charlie@example.com", "role": "Read-Only"}
      """
    Then the response status is 200
    And the response body JSON path "member.role" equals "Read-Only"

  Scenario: Newly added member appears in subsequent GET /api/projects/{id} response
    Given the client added "diana@example.com" with role "Developer" to the project
    When the client sends "GET /api/projects/{project_id}"
    Then the response status is 200
    And the response body JSON path "members" array contains:
      """
      {"user_email": "diana@example.com", "role": "Developer"}
      """

  Scenario: Email without @ character is rejected with HTTP 400 (FR-L09)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "notanemail", "role": "Developer"}
      """
    Then the response status is 400
    And the response body is {"detail": "Valid email is required"}

  Scenario: Empty user_email is rejected with HTTP 400 (FR-L09)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "", "role": "Developer"}
      """
    Then the response status is 400
    And the response body is {"detail": "Valid email is required"}

  Scenario: Whitespace-only user_email is rejected after strip() with HTTP 400
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "   ", "role": "Developer"}
      """
    Then the response status is 400
    And the response body is {"detail": "Valid email is required"}

  # ── Bug #2 ──────────────────────────────────────────────────────────────────
  # add_member() in app.py has the role-allowlist guard commented out.
  # The correct code (5 commented lines) should raise HTTP 400 for unknown roles.
  # These scenarios WILL FAIL until Bug #2 is fixed.
  # ────────────────────────────────────────────────────────────────────────────
  @bug @bug2 @known-failure
  Scenario: Role "GodMode" is rejected with HTTP 400 (BUG #2)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "mallory@example.com", "role": "GodMode"}
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Invalid role 'GodMode'"
    And the response body JSON path "detail" contains "Admin, Developer, Read-Only"

  @bug @bug2 @known-failure
  Scenario: Arbitrary role string "SuperAdmin" is rejected with HTTP 400 (BUG #2)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "eve@example.com", "role": "SuperAdmin"}
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Invalid role 'SuperAdmin'"
    And the response body JSON path "detail" contains "Admin, Developer, Read-Only"

  @bug @bug2 @known-failure
  Scenario: Empty role string is rejected with HTTP 400 (BUG #2)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "frank@example.com", "role": ""}
      """
    Then the response status is 400
    And the response body JSON path "detail" contains "Invalid role"

  Scenario: Adding a member to a non-existent project returns HTTP 404 (FR-L14)
    When the client sends "POST /api/projects/00000000-0000-0000-0000-000000000000/members" with body:
      """
      {"user_email": "alice@example.com", "role": "Developer"}
      """
    Then the response status is 404
    And the response body is {"detail": "Project not found"}

  Scenario: UI shows success banner with email and role after successful add-member
    Given the user is in add-member mode for project "team-project"
    When the user enters "alice@example.com" in data-testid "input-member-email"
    And the user selects "Developer" from data-testid "input-member-role"
    And the user clicks data-testid "btn-add-member"
    Then the browser sends "POST /api/projects/{project_id}/members"
    And the element with data-testid "member-success" is visible
    And the element with data-testid "member-success" contains "Added alice@example.com as Developer."
    And the element with data-testid "member-list" contains a row with data-testid "member-row"
    And that row has data-testid "member-email" with text "alice@example.com"
    And that row has data-testid "member-role" with text "Developer"
    And the input with data-testid "input-member-email" is cleared to ""
    And the select with data-testid "input-member-role" is reset to ""

  Scenario: UI role dropdown offers exactly three valid roles
    Given the user is in the add-member view
    Then the select element with data-testid "input-member-role" contains option "Admin"
    And the select element with data-testid "input-member-role" contains option "Developer"
    And the select element with data-testid "input-member-role" contains option "Read-Only"
    And the select element with data-testid "input-member-role" contains exactly 4 options
    And the select element with data-testid "input-member-role" contains placeholder "— select a role —"


# =============================================================================
# TS-006 — Context-aware option filtering based on selections
# BRD: FR-L03 (language dropdown disabled until type selected; GET /api/languages)
# =============================================================================