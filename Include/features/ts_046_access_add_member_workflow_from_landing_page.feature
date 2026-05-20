@TS-046 @regression @ui @members
Feature: Access Add Member workflow from landing page

  Background:
    Given the portal is running at "http://localhost:8000"
    And the state is clean via "POST /api/_reset"
    And the client created project "member-test-proj" with type "Library" and language "Python" and stored its id

  Scenario: Three action cards are present on the landing page (AC-08)
    Given the user navigates to "/"
    Then the element with data-testid "card-create" is visible
    And the element with data-testid "card-add" is visible
    And the element with data-testid "card-remove" is visible

  Scenario: Add Member card text and description are correct
    Given the user navigates to "/"
    Then the element with data-testid "card-add" heading reads "Add Member"
    And the element with data-testid "card-add" description reads "Grant access to an existing project."

  Scenario: Clicking Add Member card switches to members view in "add" mode
    Given the user navigates to "/"
    When the user clicks the element with data-testid "card-add"
    Then the JavaScript function enterMembers('add') is invoked
    And the view "view-members" has CSS class "active"
    And the view "view-landing" does NOT have CSS class "active"
    And the element with id "members-title" has text "Add Member to Project"
    And the element with data-testid "add-member-form" is displayed (style.display != "none")
    And the element with data-testid "select-project" is visible
    And the element with data-testid "btn-members-back" is visible

  Scenario: Members view project dropdown is populated by GET /api/projects
    Given the user has clicked data-testid "card-add"
    Then the browser calls "GET /api/projects"
    And the select element with data-testid "select-project" contains option "member-test-proj"

  Scenario: Selecting a project in members view loads its member list via GET /api/projects/{id}
    Given the user is in add-member mode
    When the user selects "member-test-proj" from data-testid "select-project"
    Then the browser calls "GET /api/projects/{project_id}"
    And the element with data-testid "member-list-empty" is visible
    And the element with data-testid "member-list-empty" contains text "No members yet."

  Scenario: No project selected shows default prompt in member list
    Given the user has clicked data-testid "card-add"
    And no project is selected in data-testid "select-project"
    Then the element with data-testid "member-list" contains text "Select a project to see members."

  Scenario: Back button in members view returns to landing page and refreshes project list
    Given the user is in the members view
    When the user clicks data-testid "btn-members-back"
    Then the JavaScript function showView('landing') is invoked
    And the view "view-landing" has CSS class "active"
    And the browser calls "GET /api/projects" to refresh the landing page list

  Scenario: Remove Member card switches to members view in "remove" mode (not "add")
    Given the user navigates to "/"
    When the user clicks the element with data-testid "card-remove"
    Then the JavaScript function enterMembers('remove') is invoked
    And the element with id "members-title" has text "Remove Member from Project"
    And the element with data-testid "add-member-form" has inline style "display:none"

  Scenario: Member rows in remove mode each have a Remove button
    Given the user has clicked data-testid "card-add"
    And the user added "alice@example.com" with role "Developer" to "member-test-proj"
    And the user has navigated to remove-member mode for "member-test-proj"
    Then the element with data-testid "member-row" for "alice@example.com" contains data-testid "btn-remove-member"

  Scenario: Member rows in add mode do NOT have a Remove button
    Given the user has clicked data-testid "card-add"
    And "alice@example.com" is a member of "member-test-proj"
    When the user selects "member-test-proj" from data-testid "select-project"
    Then the element with data-testid "member-row" for "alice@example.com" does NOT contain data-testid "btn-remove-member"


# =============================================================================
# ADDITIONAL SCENARIOS: Duplicate member prevention (FR-L10)
# No TS-ID in the BRD list but directly implemented and traceable to AC-10
# =============================================================================