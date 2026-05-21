@TS-045 @regression
Feature: Success Notification Banner After Project Provisioning Completion

  Background:
    Given I navigate to the portal at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: wizard-success banner is not visible on initial wizard load
    Given I click the element with data-testid "card-create"
    Then the element with data-testid "wizard-success" should not be visible

  Scenario: wizard-success banner is shown with project name and ID after successful creation
    Given I click the element with data-testid "card-create"
    And I select "Microservice" from the element with data-testid "input-type"
    And I select "Python/Flask" from the element with data-testid "input-language"
    And I type "notify-test-project" into the element with data-testid "input-name"
    When I click the element with data-testid "btn-submit"
    Then the element with data-testid "wizard-success" is visible
    And the element with data-testid "wizard-success" text contains "notify-test-project"
    And the element with data-testid "wizard-success" text contains "created successfully"
    And the element with data-testid "wizard-success" text contains "ID:"

  Scenario: wizard-success banner text includes the UUID-format project ID
    Given I click the element with data-testid "card-create"
    And I select "Library" from the element with data-testid "input-type"
    And I select "TypeScript" from the element with data-testid "input-language"
    And I type "id-display-test" into the element with data-testid "input-name"
    When I click the element with data-testid "btn-submit"
    Then the element with data-testid "wizard-success" text matches the pattern "ID: [0-9a-f-]{36}"

  Scenario: project-list updates on the landing page after successful wizard creation (no page reload)
    Given I click the element with data-testid "card-create"
    And I select "Batch Job" from the element with data-testid "input-type"
    And I select "Shell" from the element with data-testid "input-language"
    And I type "dynamic-list-test" into the element with data-testid "input-name"
    When I click the element with data-testid "btn-submit"
    And I click the element with data-testid "btn-cancel"
    Then the element with data-testid "project-list" contains an element with data-testid "project-name"
    And the element with data-testid "project-name" text should contain "dynamic-list-test"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: member-success banner shows added email and role after a valid add-member action
    Given I navigate to "http://localhost:8000"
    And I send a POST request to "/api/projects" with body:
      """
      {"project_name": "banner-project", "project_type": "Microservice", "language": "Python/Flask"}
      """
    And I click the element with data-testid "card-add"
    And I select project "banner-project" from the element with data-testid "select-project"
    And I type "member@example.com" into the element with data-testid "input-member-email"
    And I select "Developer" from the element with data-testid "input-member-role"
    When I click the element with data-testid "btn-add-member"
    Then the element with data-testid "member-success" is visible
    And the element with data-testid "member-success" text contains "member@example.com"
    And the element with data-testid "member-success" text contains "Developer"

  # ── Negative ──────────────────────────────────────────────

  Scenario: wizard-error banner is shown and wizard-success is hidden when creation fails
    Given I click the element with data-testid "card-create"
    And I select "Microservice" from the element with data-testid "input-type"
    And I select "Python/Flask" from the element with data-testid "input-language"
    And I type "bad name!" into the element with data-testid "input-name"
    When I click the element with data-testid "btn-submit"
    Then the element with data-testid "wizard-error" is visible
    And the element with data-testid "wizard-success" should not be visible

  Scenario: member-error banner is shown when add-member fails with duplicate email
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "dup-banner-proj", "project_type": "Library", "language": "Java"}
      """
    And I click the element with data-testid "card-add"
    And I select project "dup-banner-proj" from the element with data-testid "select-project"
    And I type "taken@example.com" into the element with data-testid "input-member-email"
    And I select "Admin" from the element with data-testid "input-member-role"
    And I click the element with data-testid "btn-add-member"
    And the element with data-testid "member-success" is visible
    And I type "taken@example.com" into the element with data-testid "input-member-email"
    And I select "Developer" from the element with data-testid "input-member-role"
    When I click the element with data-testid "btn-add-member"
    Then the element with data-testid "member-error" is visible
    And the element with data-testid "member-error" text contains "Member already in project"