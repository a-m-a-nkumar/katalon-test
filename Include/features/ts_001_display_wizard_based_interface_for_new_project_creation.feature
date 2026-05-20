@TS-001 @regression @wizard @ui
Feature: Display wizard-based interface for new project creation

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And the user navigates to "/"
    And the view "view-landing" is the active view

  Scenario: New Project card is present on the landing page with correct label
    Then the element with data-testid "card-create" is visible
    And the card heading reads "New Project"
    And the card description reads "Create a new project with the guided wizard."

  Scenario: Clicking the New Project card activates the wizard view
    When the user clicks the element with data-testid "card-create"
    Then the JavaScript function showView('wizard') is invoked
    And the view "view-wizard" has CSS class "active"
    And the view "view-landing" does NOT have CSS class "active"
    And the page heading "Create a New Project" is visible
    And the element with data-testid "input-type" is visible
    And the element with data-testid "input-language" is visible
    And the element with data-testid "input-name" is visible
    And the element with data-testid "btn-submit" is visible with text "Create project"
    And the element with data-testid "btn-cancel" is visible with text "Back"

  Scenario: Wizard form renders with correct initial field states
    Given the user has navigated to the wizard view
    Then the select element with data-testid "input-type" has selected value ""
    And the select element with data-testid "input-type" contains the placeholder option "— select a type —"
    And the select element with data-testid "input-language" is disabled
    And the select element with data-testid "input-language" contains the placeholder "— select a project type first —"
    And the input with data-testid "input-name" has value ""
    And the input with data-testid "input-name" has placeholder "my-project-name"
    And the element with data-testid "wizard-error" has inline style "display:none"
    And the element with data-testid "wizard-success" has inline style "display:none"

  Scenario: Back button from wizard returns to landing view
    Given the user has navigated to the wizard view
    When the user clicks the element with data-testid "btn-cancel"
    Then the JavaScript function showView('landing') is invoked
    And the view "view-landing" has CSS class "active"
    And the view "view-wizard" does NOT have CSS class "active"
    And the element with data-testid "card-create" is visible

  Scenario: Wizard page title is "Project Provisioning Portal — Demo"
    Given the user has navigated to the wizard view
    Then the document title is "Project Provisioning Portal — Demo"

  Scenario: Direct navigation to root "/" returns HTTP 200 with wizard-capable HTML
    When the client sends "GET /"
    Then the response status is 200
    And the response Content-Type contains "text/html"
    And the response body contains the string "card-create"
    And the response body contains the string "view-wizard"
    And the response body contains the string "data-testid"


# =============================================================================
# TS-002 — Select project type from available options
# BRD: FR-L02 (GET /api/project-types, input-type dropdown population)
# =============================================================================