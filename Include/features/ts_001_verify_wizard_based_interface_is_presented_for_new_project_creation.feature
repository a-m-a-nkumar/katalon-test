@TS-001 @regression
Feature: Wizard-Based Interface for New Project Creation

  Background:
    Given the portal is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Landing page returns HTTP 200
    When I navigate to "http://localhost:8000"
    Then the HTTP response status is 200

  Scenario: Landing page renders the three action cards
    When I navigate to "http://localhost:8000"
    Then the page contains an element with data-testid "card-create"
    And the page contains an element with data-testid "card-add"
    And the page contains an element with data-testid "card-remove"

  Scenario: Clicking Create Project card activates the wizard view
    Given I am on the landing page at "http://localhost:8000"
    When I click the element with data-testid "card-create"
    Then the element with id "view-wizard" has CSS class "active"
    And the element with id "view-landing" does not have CSS class "active"

  Scenario: Wizard view contains all required form elements
    Given I am on the wizard view
    Then the page contains a select element with data-testid "input-type"
    And the page contains a select element with data-testid "input-language"
    And the page contains an input element with data-testid "input-name"
    And the page contains a button with data-testid "btn-submit"
    And the page contains a button with data-testid "btn-cancel"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: Cancel button navigates back to landing view
    Given I am on the wizard view
    When I click the element with data-testid "btn-cancel"
    Then the element with id "view-landing" has CSS class "active"
    And the element with id "view-wizard" does not have CSS class "active"

  Scenario: Landing page contains project list container
    When I navigate to "http://localhost:8000"
    Then the page contains an element with data-testid "project-list"

  Scenario: Empty project list shows "No projects yet." placeholder
    When I navigate to "http://localhost:8000"
    Then the element with data-testid "project-list-empty" is visible
    And the element with data-testid "project-list-empty" text should contain "No projects yet."

  # ── Negative ──────────────────────────────────────────────

  Scenario: GET / response body contains the three card labels
    When I send a GET request to "/"
    Then the response status should be 200
    And the response body contains the string "Create Project"
    And the response body contains the string "Add Member"
    And the response body contains the string "Remove Member"


# ════════════════════════════════════════════════════════════
# TS-002  Project Type Selection
# Impl:   GET /api/project-types  → {"project_types": [...]}
#         Frontend: loadProjectTypes() populates input-type select
# ════════════════════════════════════════════════════════════