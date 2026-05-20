@TS-022 @regression @api
Feature: Enforce project naming conventions

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario Outline: Project name validation against ^[A-Za-z0-9-]+$ (FR-L05)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "<name>", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is <expected_status>
    And the response body JSON path "detail" <detail_check>

    Examples:
      | name              | expected_status | detail_check                                                          |
      | valid-name        | 201             | is absent (success)                                                   |
      | ValidName123      | 201             | is absent (success)                                                   |
      | a                 | 201             | is absent (success)                                                   |
      | 123               | 201             | is absent (success)                                                   |
      | invalid name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid_name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid!name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid@name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid/name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid.name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |
      | invalid+name      | 400             | equals "Project name must contain only ASCII letters, digits, and hyphens" |

  Scenario: Project name with leading/trailing whitespace is trimmed then validated
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "  my-project  ", "project_type": "Library", "language": "Java"}
      """
    Then the response status is 201
    And the response body JSON path "project_name" equals "my-project"

  Scenario: Empty project name returns "Project name is required" (not the regex message)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name is required"}

  # ── Bug #1 ──────────────────────────────────────────────────────────────────
  # The duplicate-name loop in create_project() is commented out.
  # Expected: 409 Conflict. Actual: 201 Created.
  # ────────────────────────────────────────────────────────────────────────────
  @bug @bug1 @known-failure
  Scenario: Duplicate project name returns HTTP 409 Conflict (BUG #1)
    Given the client successfully created project "my-app" via "POST /api/projects"
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "my-app", "project_type": "Frontend App", "language": "React"}
      """
    Then the response status is 409
    And the response body is {"detail": "Project name already exists"}

  @bug @bug1 @known-failure
  Scenario: Duplicate-name uniqueness check is case-insensitive (BUG #1)
    Given the client successfully created project "Case-Project" via "POST /api/projects"
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "case-project", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 409
    And the response body is {"detail": "Project name already exists"}


# =============================================================================
# TS-046 — Access Add Member workflow from landing page
# BRD: FR-L01, FR-L08–FR-L11 (card-add card, enterMembers('add'), members view)
# =============================================================================