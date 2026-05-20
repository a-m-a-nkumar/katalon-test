@TS-016 @regression @api @ui
Feature: Track and display project status

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"

  Scenario: GET /api/projects returns empty list when no projects exist
    When the client sends "GET /api/projects"
    Then the response status is 200
    And the response body is {"projects": []}

  Scenario: GET /api/projects returns all created projects with full records
    Given the client created project "alpha-service" with type "Microservice" and language "Python/Flask"
    And the client created project "beta-lib" with type "Library" and language "TypeScript"
    When the client sends "GET /api/projects"
    Then the response status is 200
    And the response body JSON path "projects" is an array of exactly 2 items
    And the array contains an object with "project_name": "alpha-service"
    And the array contains an object with "project_name": "beta-lib"
    And each project object has fields "id", "project_name", "project_type", "language", "members", "created_at"

  Scenario: GET /api/projects returns projects ordered by created_at ascending
    Given two projects were created in this order:
      | project_name | project_type | language   |
      | first-proj   | Microservice | Node.js    |
      | second-proj  | Library      | TypeScript |
    When the client sends "GET /api/projects"
    Then the response body JSON path "projects[0].project_name" equals "first-proj"
    And the response body JSON path "projects[1].project_name" equals "second-proj"

  Scenario: GET /api/projects/{id} returns full project record including members
    Given the client created project "status-check" with type "Microservice" and language "Python/Flask" and stored its id as {project_id}
    And the client added "user@example.com" with role "Admin" to the project
    When the client sends "GET /api/projects/{project_id}"
    Then the response status is 200
    And the response body JSON path "project_name" equals "status-check"
    And the response body JSON path "project_type" equals "Microservice"
    And the response body JSON path "language" equals "Python/Flask"
    And the response body JSON path "members" array contains {"user_email": "user@example.com", "role": "Admin"}
    And the response body JSON path "created_at" is present and non-empty

  Scenario: GET /api/projects/{id} returns HTTP 404 for non-existent project id (FR-L14)
    When the client sends "GET /api/projects/00000000-0000-0000-0000-000000000000"
    Then the response status is 404
    And the response body is {"detail": "Project not found"}

  Scenario: Landing page project list is empty state when no projects exist
    Given the user navigates to "/"
    And GET /api/projects returns an empty "projects" array
    Then the element with data-testid "project-list-empty" is visible
    And the element with data-testid "project-list-empty" contains text "No projects yet."
    And no elements with data-testid "project-row" are present

  Scenario: Landing page project list shows rows after project creation (FR-L01)
    Given the client created project "landing-visible" with type "Frontend App" and language "React"
    When the user navigates to "/"
    Then the element with data-testid "project-list" is populated via "GET /api/projects"
    And at least one element with data-testid "project-row" is present
    And an element with data-testid "project-name" containing "landing-visible" is visible
    And the element with data-testid "project-list-empty" is not present

  Scenario: Project list row shows project name, type, language and member count in meta
    Given a project "meta-check" of type "Batch Job" with language "Shell" and one member exists
    When the user navigates to "/"
    Then the project row for "meta-check" displays "Batch Job" in the meta span
    And the project row for "meta-check" displays "Shell" in the meta span
    And the project row for "meta-check" displays "1 member(s)" in the meta span


# =============================================================================
# TS-022 — Enforce repository naming conventions
# BRD: FR-L05 (name regex), FR-L06 (uniqueness — Bug #1)
# =============================================================================