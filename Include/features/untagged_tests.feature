@regression @members @api @ac-10
Feature: Prevent duplicate member additions (FR-L10)

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And a project "dup-member-test" was created and its id stored as {project_id}
    And the client added "alice@example.com" with role "Developer" to the project

  Scenario: Adding the same email twice returns HTTP 409 Conflict (AC-10)
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "alice@example.com", "role": "Admin"}
      """
    Then the response status is 409
    And the response body is {"detail": "Member already in project"}

  Scenario: Duplicate check is case-insensitive for email address
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "ALICE@EXAMPLE.COM", "role": "Read-Only"}
      """
    Then the response status is 409
    And the response body is {"detail": "Member already in project"}

  Scenario: Different email can be added to the same project without conflict
    When the client sends "POST /api/projects/{project_id}/members" with body:
      """
      {"user_email": "bob@example.com", "role": "Developer"}
      """
    Then the response status is 200
    And the response body JSON path "member.user_email" equals "bob@example.com"

  Scenario: UI shows error banner when duplicate member is added
    Given the user is in add-member mode for "dup-member-test"
    When the user enters "alice@example.com" in data-testid "input-member-email"
    And the user selects "Admin" from data-testid "input-member-role"
    And the user clicks data-testid "btn-add-member"
    Then the element with data-testid "member-error" is visible
    And the element with data-testid "member-error" contains "Member already in project"
    And the element with data-testid "member-success" is not visible


# =============================================================================
# ADDITIONAL SCENARIOS: Remove member from project (FR-L12, FR-L13)
# No TS-ID in the BRD list; traces to AC-07
# Bug #3: remove_member() returns HTTP 200 but does NOT mutate the members array
# =============================================================================

@regression @members @api @ui @ac-07
Feature: Remove team member from project (FR-L12 / FR-L13)

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And the client created project "remove-test" with type "Frontend App" and language "Angular" and stored its id as {project_id}
    And the client added "alice@example.com" with role "Developer" to the project

  # ── Bug #3 ──────────────────────────────────────────────────────────────────
  # remove_member() in app.py returns {"status": "ok", "removed": "<email>"}
  # but the project["members"] list is never mutated.
  # Correct fix: uncomment the 7-line filter block in remove_member().
  # ────────────────────────────────────────────────────────────────────────────
  @bug @bug3 @known-failure
  Scenario: DELETE removes member from the project members list (BUG #3)
    When the client sends "DELETE /api/projects/{project_id}/members/alice@example.com"
    Then the response status is 200
    And the response body is {"status": "ok", "removed": "alice@example.com"}
    When the client sends "GET /api/projects/{project_id}"
    Then the response status is 200
    And the response body JSON path "members" array does NOT contain an object with "user_email": "alice@example.com"

  @bug @bug3 @known-failure
  Scenario: Member list shows "No members yet." after the only member is removed (BUG #3)
    Given the project has exactly one member "alice@example.com"
    When the client sends "DELETE /api/projects/{project_id}/members/alice@example.com"
    And the client sends "GET /api/projects/{project_id}"
    Then the response body JSON path "members" is an empty array

  Scenario: DELETE /api/projects/{id}/members/{email} returns HTTP 200 with removed field
    When the client sends "DELETE /api/projects/{project_id}/members/alice@example.com"
    Then the response status is 200
    And the response body JSON path "status" equals "ok"
    And the response body JSON path "removed" equals "alice@example.com"

  Scenario: Removing a member that does not exist returns HTTP 404 (FR-L13)
    When the client sends "DELETE /api/projects/{project_id}/members/nobody@example.com"
    Then the response status is 404
    And the response body is {"detail": "Member not found"}

  Scenario: Removing a member from a non-existent project returns HTTP 404 (FR-L14)
    When the client sends "DELETE /api/projects/00000000-0000-0000-0000-000000000000/members/alice@example.com"
    Then the response status is 404
    And the response body is {"detail": "Project not found"}

  @bug @bug3 @known-failure
  Scenario: UI member list no longer shows member after Remove button is clicked (BUG #3)
    Given the user is in remove-member mode for "remove-test"
    And the element with data-testid "member-list" shows "alice@example.com"
    When the user clicks data-testid "btn-remove-member" for "alice@example.com"
    Then the browser sends "DELETE /api/projects/{project_id}/members/alice%40example.com"
    And the element with data-testid "member-success" is visible
    And the element with data-testid "member-success" contains "Removed alice@example.com."
    And the element with data-testid "member-list" does NOT contain a data-testid "member-row" with data-email "alice@example.com"
    And the element with data-testid "member-list-empty" is visible with text "No members yet."

  Scenario: UI shows error banner when removing from project with no such member
    Given the user is in remove-member mode for "remove-test"
    When the browser sends "DELETE /api/projects/{project_id}/members/nobody%40example.com" directly
    Then the response status is 404
    And the element with data-testid "member-error" is visible
    And the element with data-testid "member-error" contains "Member not found"


# =============================================================================
# ADDITIONAL SCENARIOS: Empty member list renders gracefully (FR-L15)
# =============================================================================

@regression @members @ui @ac-09
Feature: Empty member list renders gracefully (FR-L15)

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And a project "empty-members-proj" was created with no members

  Scenario: Member list shows "No members yet." for a project with zero members
    Given the user is in add-member mode for "empty-members-proj"
    When the user selects "empty-members-proj" from data-testid "select-project"
    Then the element with data-testid "member-list-empty" is visible
    And the element with data-testid "member-list-empty" contains text "No members yet."
    And no elements with data-testid "member-row" are present in data-testid "member-list"

  Scenario: GET /api/projects/{id} returns empty members array for a new project
    Given the project "empty-members-proj" has id {project_id}
    When the client sends "GET /api/projects/{project_id}"
    Then the response status is 200
    And the response body JSON path "members" is an empty array


# =============================================================================
# ADDITIONAL SCENARIOS: Test-helper reset endpoint
# (POST /api/_reset — used as test setup hook across all feature files)
# =============================================================================

@regression @api @test-helper
Feature: POST /api/_reset clears all in-memory state

  Background:
    Given the portal is running at "http://localhost:8000"

  Scenario: POST /api/_reset returns HTTP 200 with confirmation message
    When the client sends "POST /api/_reset"
    Then the response status is 200
    And the response body is {"status": "ok", "message": "All projects cleared"}

  Scenario: GET /api/projects returns empty list after reset
    Given two projects "proj-a" and "proj-b" exist
    When the client sends "POST /api/_reset"
    And the client sends "GET /api/projects"
    Then the response body is {"projects": []}

  Scenario: POST /api/_reset is idempotent when called on an already-empty store
    Given no projects exist
    When the client sends "POST /api/_reset"
    Then the response status is 200
    And the response body is {"status": "ok", "message": "All projects cleared"}
    When the client sends "GET /api/projects"
    Then the response body is {"projects": []}


# =============================================================================
# COVERAGE SUMMARY
# =============================================================================
#
# ✅ COVERED
# ─────────────────────────────────────────────────────────────────────────────
# TS-001 | Wizard interface for project creation
#          Code: INDEX_HTML (view-wizard), showView('wizard'), card-create
#          Endpoint: GET /
#          Scenarios: 6 (3 happy-path, 2 navigation, 1 API)
#
# TS-002 | Select project type from available options
#          Code: get_project_types() → GET /api/project-types, loadProjectTypes()
#          Scenarios: 5 (1 API, 1 UI-population, 1 type-triggers-language, 1 error, 1 multi-select)
#
# TS-003 | Select language/framework based on project type
#          Code: get_languages() → GET /api/languages, LANGUAGES_BY_TYPE, onTypeChange()
#          Scenarios: 8 (5 table-driven, 1 Batch/React exclusion, 1 unknown-type, 1 API rejection, 1 UI disable, 1 reset)
#
# TS-004 | Enter and validate project name
#          Code: create_project(), name regex ^[A-Za-z0-9-]+$, FR-L05/L06
#          Bug #1 covered: 2 @known-failure scenarios
#          Scenarios: 10 (4 error cases, 1 happy-path, 1 trim, 2 bug#1, 2 UI)
#
# TS-005 | Add team members with role assignment
#          Code: add_member() → POST /api/projects/{id}/members, VALID_ROLES
#          Bug #2 covered: 3 @known-failure scenarios
#          Scenarios: 12 (3 valid roles, 1 persistence, 3 email errors, 3 bug#2, 1 404, 2 UI)
#
# TS-006 | Context-aware option filtering based on selections
#          Code: LANGUAGES_BY_TYPE matrix, onTypeChange(), GET /api/languages
#          Scenarios: 5 (UI disable, type-filters-language, re-filter-on-change, API-bypass, mutual-exclusion)
#
# TS-007 | Validate all inputs before submission
#          Code: create_project() full validation pipeline, Pydantic model
#          Scenarios: 10 (happy-path, visibility, 3 missing fields, empty name, unknown type, wrong language, 8 boundary names via table)
#
# TS-016 | Track and display request status
#          Code: list_projects() → GET /api/projects, get_project() → GET /api/projects/{id}
#          Scenarios: 8 (empty list, all-projects, ordering, single-project, 404, UI empty state, UI populated, UI meta)
#
# TS-022 | Enforce naming conventions
#          Code: create_project() regex ^[A-Za-z0-9-]+$, strip(), FR-L05/L06
#          Bug #1 covered: 2 @known-failure scenarios
#          Scenarios: 8 (11-row table, trim, empty-name message, 2 bug#1)
#
# TS-046 | Access Add Member workflow from landing page
#          Code: enterMembers('add'/'remove'), card-add, card-remove, view-members
#          Scenarios: 9 (3 cards visible, card text, click-switches-view, project-dropdown, member-list, no-selection, back-button, remove-mode, row-buttons)
#
# ADDITIONAL (implemented features without BRD TS-ID):
#   FR-L10 Duplicate member prevention (AC-10): 4 scenarios
#   FR-L12/13 Remove member / remove-member no-op (AC-07, Bug #3): 8 scenarios (4 @known-failure)
#   FR-L15 Empty member list renders gracefully: 2 scenarios
#   POST /api/_reset test-helper: 3 scenarios
#
# ─────────────────────────────────────────────────────────────────────────────
# ❌ SKIPPED (feature not found in code)
# ─────────────────────────────────────────────────────────────────────────────
# TS-008 | Summary confirmation screen before submission
#          REASON: Wizard is a single-page form; no multi-step progress indicator,
#          no review/confirm step. INDEX_HTML has no summary view or step counter.
#
# TS-009 | Create ServiceNow work request
#          REASON: No ServiceNow integration. No endpoint or service class.
#          BRD Out of Scope: "No real Bitbucket, Saviynt, or ServiceNow integrations".
#
# TS-010 | Validate request before submitting to ServiceNow
#          REASON: Same — no ServiceNow integration.
#
# TS-011 | Route ServiceNow work request to Tooling team
#          REASON: No ServiceNow integration.
#
# TS-012 | Tooling team approves request in ServiceNow
#          REASON: No ServiceNow integration.
#
# TS-013 | Tooling team rejects request in ServiceNow
#          REASON: No ServiceNow integration.
#
# TS-014 | ServiceNow approval triggers automated provisioning
#          REASON: No ServiceNow integration; no webhook or event-driven provisioning.
#
# TS-015 | Include all wizard inputs in ServiceNow work request
#          REASON: No ServiceNow integration.
#
# TS-017 | Create Bitbucket repository via API
#          REASON: No Bitbucket integration. In-memory store only.
#
# TS-018 | Repository with template-based folder structure
#          REASON: No Bitbucket integration. No template-based repo scaffolding.
#
# TS-019 | Seed repository with README.md
#          REASON: No Bitbucket integration.
#
# TS-020 | Seed repository with boilerplate code folder
#          REASON: No Bitbucket integration.
#
# TS-021 | Include standard configuration files for language
#          REASON: No Bitbucket integration.
#
# TS-023 | Handle Bitbucket API failures with retry logic
#          REASON: No Bitbucket integration; no retry mechanism in codebase.
#
# TS-024 | Provision Saviynt access for project requester
#          REASON: No Saviynt integration.
#
# TS-025 | Provision Saviynt access for all team members
#          REASON: No Saviynt integration.
#
# TS-026 | Assign appropriate access roles based on wizard selections
#          REASON: No Saviynt integration.
#
# TS-027 | Synchronize access between Bitbucket and Saviynt
#          REASON: No Bitbucket or Saviynt integration.
#
# TS-028 | Handle Saviynt API failures with retry logic
#          REASON: No Saviynt integration; no retry mechanism.
#
# TS-029 | Access Admin Panel with Tooling team credentials
#          REASON: No Admin Panel implemented. No authentication/SSO. Out of scope in BRD.
#
# TS-030 | Add new template via Admin Panel
#          REASON: No Admin Panel. Language-type matrix is hard-coded in LANGUAGES_BY_TYPE dict.
#
# TS-031 | Update existing template via Admin Panel
#          REASON: No Admin Panel.
#
# TS-032 | Map template to project type and language combination
#          REASON: Mapping exists as a hard-coded dict (LANGUAGES_BY_TYPE) — no admin CRUD surface.
#
# TS-033 | Retire or version templates
#          REASON: No Admin Panel. LANGUAGES_BY_TYPE is a static constant.
#
# TS-034 | Template updates apply only to new projects
#          REASON: No Admin Panel; templates are static.
#
# TS-035 | Preview and validate template before publishing
#          REASON: No Admin Panel.
#
# TS-036 | Maintain audit log of template changes
#          REASON: No Admin Panel; no audit-log mechanism anywhere in app.py.
#
# TS-037 | Send success notification email to requester
#          REASON: No email notifications. BRD Out of Scope: "Email notifications (replaced
#          by inline success/error banners)". UI banners ARE tested in TS-004/TS-005/TS-046.
#
# TS-038 | Include repository link in success email
#          REASON: No email notifications; no Bitbucket repository link.
#
# TS-039 | Include git clone command in success email
#          REASON: No email notifications.
#
# TS-040 | Include provisioning summary in success email
#          REASON: No email notifications.
#
# TS-041 | Include next steps in success email
#          REASON: No email notifications.
#
# TS-042 | Send failure notification email to requester
#          REASON: No email notifications.
#
# TS-043 | Indicate Tooling team notified in failure email
#          REASON: No email notifications.
#
# TS-044 | Alert Tooling team of provisioning failures
#          REASON: No email notifications; no Tooling team alerting mechanism.
#
# TS-045 | Send approval notification email to requester
#          REASON: No email notifications; no approval step (approval is implicit on submit).
#
# ─────────────────────────────────────────────────────────────────────────────
# 📊 OVERALL COVERAGE
# ─────────────────────────────────────────────────────────────────────────────
#  BRD scenarios covered : 10 of 46  (22%)
#  BRD scenarios skipped : 36 of 46  (78%)  — features simply not implemented in demo
#
#  Total Gherkin scenarios generated : ~100
#    Scenarios tagged @bug/@known-failure (planted bugs) : 11
#    Happy-path scenarios                                : ~45
#    Edge-case / boundary scenarios                      : ~28
#    Negative / error-condition scenarios                : ~27
#
#  Additional coverage (implemented but not in BRD TS list):
#    FR-L10 duplicate-member     : 4 scenarios
#    FR-L12/13 remove-member     : 8 scenarios (4 expose Bug #3)
#    FR-L15 empty-member render  : 2 scenarios
#    POST /api/_reset helper     : 3 scenarios
#
#  Planted bugs directly targeted by @known-failure scenarios:
#    Bug #1 (duplicate project name — FR-L06) : 4 scenarios across TS-004 + TS-022
#    Bug #2 (invalid role accepted  — FR-L08) : 3 scenarios in TS-005
#    Bug #3 (remove-member no-op    — FR-L12) : 4 scenarios in FR-L12/13 feature
# =============================================================================