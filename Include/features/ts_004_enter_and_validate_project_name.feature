@TS-004 @regression @wizard @api
Feature: Enter and validate project name

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario: Valid project name is accepted and project is created with HTTP 201
    When the client sends "POST /api/projects" with body:
      """
      {
        "project_name": "my-valid-project-123",
        "project_type": "Microservice",
        "language":     "Java/Spring Boot"
      }
      """
    Then the response status is 201
    And the response body JSON path "id" is a non-empty UUID string
    And the response body JSON path "project_name" equals "my-valid-project-123"
    And the response body JSON path "project_type" equals "Microservice"
    And the response body JSON path "language" equals "Java/Spring Boot"
    And the response body JSON path "members" is an empty array
    And the response body JSON path "created_at" matches pattern "^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z$"

  Scenario: Empty project name is rejected with HTTP 400 (FR-L05)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name is required"}

  Scenario: Whitespace-only project name is rejected after strip() with HTTP 400 (FR-L05)
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "   ", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name is required"}

  Scenario: Project name with a space fails ^[A-Za-z0-9-]+$ and returns HTTP 400
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "bad name", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name must contain only ASCII letters, digits, and hyphens"}

  Scenario: Project name with underscore fails regex and returns HTTP 400
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "bad_name", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name must contain only ASCII letters, digits, and hyphens"}

  Scenario: Project name with exclamation mark fails regex and returns HTTP 400
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "bad-name!", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 400
    And the response body is {"detail": "Project name must contain only ASCII letters, digits, and hyphens"}

  Scenario: Project name is trimmed of surrounding whitespace before validation
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "  trimmed-name  ", "project_type": "Library", "language": "Java"}
      """
    Then the response status is 201
    And the response body JSON path "project_name" equals "trimmed-name"

  # ── Bug #1 ──────────────────────────────────────────────────────────────────
  # create_project() in app.py has the duplicate-name check commented out.
  # The correct code (3 commented lines) should raise HTTP 409.
  # These scenarios WILL FAIL until Bug #1 is fixed.
  # ────────────────────────────────────────────────────────────────────────────
  @bug @bug1 @known-failure
  Scenario: Submitting the same project name twice returns HTTP 409 on the second request (BUG #1)
    Given the client successfully sent "POST /api/projects" with body:
      """
      {"project_name": "duplicate-demo", "project_type": "Microservice", "language": "Node.js"}
      """
    And the response status was 201
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "duplicate-demo", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status is 409
    And the response body is {"detail": "Project name already exists"}

  @bug @bug1 @known-failure
  Scenario: Duplicate-name check is case-insensitive (BUG #1)
    Given the client created a project named "MyProject"
    When the client sends "POST /api/projects" with body:
      """
      {"project_name": "myproject", "project_type": "Library", "language": "Python"}
      """
    Then the response status is 409
    And the response body is {"detail": "Project name already exists"}

  Scenario: UI wizard shows success banner with project id after valid submission
    Given the user is on the wizard view
    When the user selects "Microservice" from data-testid "input-type"
    And the user selects "Python/Flask" from data-testid "input-language"
    And the user enters "ui-created-project" in data-testid "input-name"
    And the user clicks data-testid "btn-submit"
    Then the browser sends "POST /api/projects"
    And the element with data-testid "wizard-success" is visible
    And the element with data-testid "wizard-success" contains "ui-created-project"
    And the element with data-testid "wizard-success" contains "created successfully"
    And the element with data-testid "wizard-error" is not visible
    And the input with data-testid "input-name" is cleared to ""

  Scenario: UI wizard shows error banner when project name format is invalid
    Given the user is on the wizard view
    When the user selects "Library" from data-testid "input-type"
    And the user selects "TypeScript" from data-testid "input-language"
    And the user enters "invalid name!" in data-testid "input-name"
    And the user clicks data-testid "btn-submit"
    Then the element with data-testid "wizard-error" is visible
    And the element with data-testid "wizard-error" contains "Project name must contain only ASCII letters, digits, and hyphens"
    And the element with data-testid "wizard-success" is not visible


# =============================================================================
# TS-005 — Add optional team members with role assignment
# BRD: FR-L08, FR-L09, FR-L10, FR-L11  (add_member() endpoint)
# VALID_ROLES = ("Admin", "Developer", "Read-Only")
# Bug #2: role allowlist check is commented out — any role string is accepted
# =============================================================================