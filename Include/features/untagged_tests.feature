@regression
Feature: Project Provisioning Portal — Full Regression Suite
  Complete implementation-level test suite for the Project Provisioning Portal demo app.
  All scenarios verify behaviour defined in DEMO_BRD.md against the single-file FastAPI
  application (app.py, http://localhost:8000).

  Endpoints under test:
    GET  /                                           — SPA landing page
    GET  /api/project-types                          — list of 5 supported types
    GET  /api/languages?project_type={type}          — languages for a type
    POST /api/projects                               — create project (201)
    GET  /api/projects                               — list all projects
    GET  /api/projects/{id}                          — get one project (404 if missing)
    POST /api/projects/{id}/members                  — add member (200)
    DELETE /api/projects/{id}/members/{email}        — remove member (200 / no-op Bug#3)
    POST /api/_reset                                 — wipe all state (test helper)

  Planted bugs that failing scenarios will catch:
    Bug #1  FR-L06  — duplicate project name returns 201 instead of 409
    Bug #2  FR-L08  — invalid member role accepted instead of 400
    Bug #3  FR-L12  — remove-member is a no-op; member stays in list
    Bug #4  FR-L03  — Microservice missing Node.js (2 languages instead of 3)

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-001  Wizard-Based Interface for New Project Creation
  # FR-001.1 / FR-L02 — data-testid="card-create", id="view-wizard"
  # ════════════════════════════════════════════════════════════════════════════

  @TS-001
  Scenario: Landing page renders the Create Project action card
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    Then the page contains a button with data-testid "card-create"
    And the element with data-testid "card-create" is visible
    And the element with data-testid "card-create" should contain the text "Create Project"

  @TS-001
  Scenario: Clicking Create Project transitions from landing view to wizard view
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    When I click the element with data-testid "card-create"
    Then the element with id "view-wizard" should have CSS class "active"
    And the element with id "view-landing" should NOT have CSS class "active"

  @TS-001
  Scenario: Wizard view contains the project type dropdown with blank placeholder
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the page contains a select element with data-testid "input-type"
    And the element with data-testid "input-type" is visible
    And the first option of the element with data-testid "input-type" should have value ""
    And the first option of the element with data-testid "input-type" should have text "— select a type —"

  @TS-001
  Scenario: Wizard view contains the language dropdown
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the page contains a select element with data-testid "input-language"
    And the element with data-testid "input-language" is visible

  @TS-001
  Scenario: Wizard view contains the project name input with hint placeholder
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the page contains an input element with data-testid "input-name"
    And the element with data-testid "input-name" is visible
    And the element with data-testid "input-name" should have placeholder "my-project-name"

  @TS-001
  Scenario: Wizard view contains Submit and Back buttons
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the page contains a button with data-testid "btn-submit"
    And the element with data-testid "btn-submit" is visible
    And the page contains a button with data-testid "btn-cancel"
    And the element with data-testid "btn-cancel" is visible

  @TS-001
  Scenario: Back button in wizard returns user to landing page
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I click the element with data-testid "btn-cancel"
    Then the element with id "view-landing" should have CSS class "active"
    And the element with id "view-wizard" should NOT have CSS class "active"

  @TS-001
  Scenario: Landing page also renders Add Member and Remove Member action cards
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    Then the page contains a button with data-testid "card-add"
    And the element with data-testid "card-add" should contain the text "Add Member"
    And the page contains a button with data-testid "card-remove"
    And the element with data-testid "card-remove" should contain the text "Remove Member"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-002  Project Type Selection Dropdown in Wizard
  # FR-001.2 / FR-L02 — GET /api/project-types, PROJECT_TYPES list
  # ════════════════════════════════════════════════════════════════════════════

  @TS-002
  Scenario: GET /api/project-types returns HTTP 200 with JSON content type
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the response Content-Type should contain "application/json"
    And the response body has the key "project_types"
    And the response JSON field "project_types" is an array

  @TS-002
  Scenario: Response contains exactly five project types
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the response JSON field "project_types" is an array with exactly 5 items

  @TS-002
  Scenario: Response includes all five supported project types
    When I send a GET request to "/api/project-types"
    Then the response status should be 200
    And the "project_types" array contains "Microservice"
    And the "project_types" array contains "Batch Job"
    And the "project_types" array contains "Frontend App"
    And the "project_types" array contains "Library"
    And the "project_types" array contains "Data Pipeline"

  @TS-002
  Scenario: Wizard project type dropdown is populated with all five types
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the element with data-testid "input-type" contains an option with text "Microservice"
    And the element with data-testid "input-type" contains an option with text "Batch Job"
    And the element with data-testid "input-type" contains an option with text "Frontend App"
    And the element with data-testid "input-type" contains an option with text "Library"
    And the element with data-testid "input-type" contains an option with text "Data Pipeline"

  @TS-002
  Scenario: POST /api/projects with an unrecognised project type is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "unknown-type-test",
        "project_type": "Full-Stack App",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Unknown project type"

  @TS-002
  Scenario: POST /api/projects with empty project type is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "empty-type-test",
        "project_type": "",
        "language": "Java"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Unknown project type"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-003  Language/Framework Options Vary by Selected Project Type
  # FR-001.3 / FR-L03 — GET /api/languages, LANGUAGES_BY_TYPE, onTypeChange() JS
  # ════════════════════════════════════════════════════════════════════════════

  @TS-003
  Scenario: GET /api/languages returns HTTP 200 with JSON array for a valid project type
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the response Content-Type should contain "application/json"
    And the response body has the key "languages"
    And the response JSON field "languages" is an array

  @TS-003
  Scenario: GET /api/languages returns 400 for an unknown project type
    When I send a GET request to "/api/languages?project_type=UnknownType"
    Then the response status should be 400
    And the response JSON field "detail" should contain "Unknown project type"

  @TS-003
  Scenario: GET /api/languages without project_type query parameter returns 422
    When I send a GET request to "/api/languages"
    Then the response status should be 422

  @TS-003
  Scenario: POST /api/projects rejects incompatible language with descriptive 400 error
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "incompatible-lang-test",
        "project_type": "Batch Job",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "React"
    And the response JSON field "detail" should contain "Batch Job"

  @TS-003
  Scenario: Language dropdown updates with compatible options when project type is changed
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "Python"
    And the element with data-testid "input-language" contains an option with text "Scala"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-004  Project Name Collection and Validation
  # FR-001.4 / FR-L04 / FR-L05 — create_project(), regex ^[A-Za-z0-9-]+$
  # ════════════════════════════════════════════════════════════════════════════

  @TS-004
  Scenario: Successfully create a project with a valid lowercase hyphenated name
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "my-new-project",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_name" should equal "my-new-project"
    And the response JSON field "project_type" should equal "Microservice"
    And the response JSON field "language" should equal "Java/Spring Boot"
    And the response JSON field "members" is an empty array
    And the response JSON field "id" is a non-empty string

  @TS-004
  Scenario: Successfully create a project name with uppercase letters and digits
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "MyProject123",
        "project_type": "Library",
        "language": "TypeScript"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_name" should equal "MyProject123"

  @TS-004
  Scenario: Reject empty project name with 400 and required-field message
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Project name is required"

  @TS-004
  Scenario: Reject whitespace-only project name with 400 and required-field message
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "   ",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Project name is required"

  @TS-004
  Scenario Outline: Reject project names containing invalid characters
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "<invalid_name>",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "letters, digits, and hyphens"

    Examples:
      | invalid_name  |
      | bad name      |
      | bad_name      |
      | bad.name      |
      | bad@name      |
      | project name! |

  @TS-004
  Scenario: Duplicate project name must return 409 Conflict — FR-L06 (⚠ Bug #1 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "duplicate-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "duplicate-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 409
    And the response JSON field "detail" should contain "already exists"

  @TS-004
  Scenario: Wizard shows success banner after valid project creation
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Library" from the element with data-testid "input-type"
    And I select "Python" from the element with data-testid "input-language"
    And I type "ui-project-test" into the element with data-testid "input-name"
    And I click the element with data-testid "btn-submit"
    Then the element with data-testid "wizard-success" is visible
    And the element with data-testid "wizard-success" should contain the text "ui-project-test"

  @TS-004
  Scenario: Wizard shows error banner when project name contains invalid characters
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Library" from the element with data-testid "input-type"
    And I select "Java" from the element with data-testid "input-language"
    And I type "invalid name!" into the element with data-testid "input-name"
    And I click the element with data-testid "btn-submit"
    Then the element with data-testid "wizard-error" is visible


  # ════════════════════════════════════════════════════════════════════════════
  # TS-005  Optional Team Member Addition with Role Assignment
  # FR-001.5 / FR-L08 / FR-L09 / FR-L10 / FR-L11 — add_member(), /api/projects/{id}/members
  # ════════════════════════════════════════════════════════════════════════════

  @TS-005
  Scenario: Successfully add a member with role Admin
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "team-project",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "member.user_email" should equal "alice@example.com"
    And the response JSON field "member.role" should equal "Admin"

  @TS-005
  Scenario: Added member appears in GET /api/projects/{id} members array
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "member-check-project",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "bob@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the "members" array contains an object where "user_email" equals "bob@example.com"
    And the "members" array contains an object where "role" equals "Developer"

  @TS-005
  Scenario: Project is created with zero members — member addition is optional
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "no-members-project",
        "project_type": "Data Pipeline",
        "language": "Python"
      }
      """
    Then the response status should be 201
    And the response JSON field "members" is an empty array

  @TS-005
  Scenario: Add two members with different roles to the same project
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "multi-member-project",
        "project_type": "Frontend App",
        "language": "React"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "lead@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "dev@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "members" is an array with exactly 2 items

  @TS-005
  Scenario: Add Member UI flow is accessible from landing page via card-add
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    When I click the element with data-testid "card-add"
    Then the element with id "view-members" should have CSS class "active"
    And the page contains an input element with data-testid "input-member-email"
    And the page contains a select element with data-testid "input-member-role"
    And the page contains a button with data-testid "btn-add-member"

  @TS-005
  Scenario: Add member to non-existent project returns 404 — FR-L14
    When I send a POST request to "/api/projects/00000000-0000-0000-0000-000000000000/members" with body:
      """
      {
        "user_email": "ghost@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 404
    And the response JSON field "detail" should contain "Project not found"

  @TS-005
  Scenario: Adding the same email twice to a project returns 409 Conflict — FR-L10
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "dup-member-project",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Read-Only"
      }
      """
    Then the response status should be 409
    And the response JSON field "detail" should contain "Member already in project"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-006  Smart Decisions and Narrowed-Down Options Based on Selections
  # FR-001.6 / FR-L03 — onTypeChange() JS, data-testid="input-language" disabled attr
  # ════════════════════════════════════════════════════════════════════════════

  @TS-006
  Scenario: Language dropdown is disabled when the wizard first loads
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the element with data-testid "input-language" should be disabled

  @TS-006
  Scenario: Selecting a project type enables and populates the language dropdown
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "Python"
    And the element with data-testid "input-language" contains an option with text "Scala"

  @TS-006
  Scenario: Language options change when project type is switched
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Frontend App" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "React"
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "Python"
    And the element with data-testid "input-language" should NOT have an option with value "React"

  @TS-006
  Scenario: Selecting blank placeholder re-disables the language dropdown
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Library" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    When I select the blank placeholder option from the element with data-testid "input-type"
    Then the element with data-testid "input-language" should be disabled

  @TS-006
  Scenario: Batch Job type does not offer React in the language dropdown
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Batch Job" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "Java"
    And the element with data-testid "input-language" contains an option with text "Python"
    And the element with data-testid "input-language" contains an option with text "Shell"
    And the element with data-testid "input-language" should NOT have an option with value "React"

  @TS-006
  Scenario: Frontend App type offers only frontend framework languages
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Frontend App" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "React"
    And the element with data-testid "input-language" contains an option with text "Angular"
    And the element with data-testid "input-language" contains an option with text "Vue"
    And the element with data-testid "input-language" should NOT have an option with value "Java"
    And the element with data-testid "input-language" should NOT have an option with value "Python"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-007  Input Validation Before Submission
  # FR-001.7 / FR-L05/L06/L08/L09/L10/L14 — all guards in create_project() + add_member()
  # ════════════════════════════════════════════════════════════════════════════

  @TS-007
  Scenario: Empty project name is rejected with 400 — FR-L05
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Project name is required"

  @TS-007
  Scenario: Project name containing a space is rejected with 400 — FR-L05
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "bad name",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "letters, digits, and hyphens"

  @TS-007
  Scenario: Project name containing an underscore is rejected with 400 — FR-L05
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "bad_name",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "letters, digits, and hyphens"

  @TS-007
  Scenario: Unknown project type is rejected with 400 — FR-L02
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "type-test",
        "project_type": "MegaService",
        "language": "Java"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Unknown project type"

  @TS-007
  Scenario: Incompatible language for project type is rejected with 400 — FR-L03
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "lang-test",
        "project_type": "Batch Job",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "React"

  @TS-007
  Scenario: Submitting the same project name twice returns 409 Conflict — FR-L06 (⚠ Bug #1 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "collision-project",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "collision-project",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 409
    And the response JSON field "detail" should contain "already exists"

  @TS-007
  Scenario: Add member with email lacking "@" is rejected with 400 — FR-L09
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "email-val-project",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "notanemail",
        "role": "Developer"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Valid email is required"

  @TS-007
  Scenario: Add member with empty email is rejected with 400 — FR-L09
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "empty-email-project",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "",
        "role": "Developer"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Valid email is required"

  @TS-007
  Scenario: Add member with invalid role returns 400 — FR-L08 (⚠ Bug #2 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-val-project",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "hacker@example.com",
        "role": "GodMode"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Admin"
    And the response JSON field "detail" should contain "Developer"
    And the response JSON field "detail" should contain "Read-Only"

  @TS-007
  Scenario: GET /api/projects/{id} with non-existent ID returns 404 — FR-L14
    When I send a GET request to "/api/projects/00000000-0000-0000-0000-000000000000"
    Then the response status should be 404
    And the response JSON field "detail" should contain "Project not found"

  @TS-007
  Scenario: POST member to non-existent project returns 404 — FR-L14
    When I send a POST request to "/api/projects/00000000-0000-0000-0000-000000000000/members" with body:
      """
      {
        "user_email": "nobody@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 404
    And the response JSON field "detail" should contain "Project not found"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-009  Microservice Project Type Language Compatibility
  # FR-001.A / FR-L03 — LANGUAGES_BY_TYPE["Microservice"]
  # ⚠ Bug #4: Node.js dropped; should be 3 languages, currently returns 2
  # ════════════════════════════════════════════════════════════════════════════

  @TS-009
  Scenario: GET /api/languages for Microservice returns HTTP 200 with JSON array
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the response Content-Type should contain "application/json"
    And the response JSON field "languages" is an array

  @TS-009
  Scenario: Microservice language list includes Java/Spring Boot
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the "languages" array contains "Java/Spring Boot"

  @TS-009
  Scenario: Microservice language list includes Python/Flask
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the "languages" array contains "Python/Flask"

  @TS-009
  Scenario: Microservice language list includes Node.js — FR-001.A (⚠ Bug #4 will fail this)
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the "languages" array contains "Node.js"

  @TS-009
  Scenario: Microservice language list contains exactly three languages — FR-001.A (⚠ Bug #4 will fail this)
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items

  @TS-009
  Scenario: Successfully create a Microservice project with Java/Spring Boot
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "svc-java",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Microservice"
    And the response JSON field "language" should equal "Java/Spring Boot"

  @TS-009
  Scenario: Successfully create a Microservice project with Python/Flask
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "svc-flask",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    And the response JSON field "language" should equal "Python/Flask"

  @TS-009
  Scenario: Successfully create a Microservice project with Node.js — (⚠ Bug #4 means current code returns 400)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "svc-node",
        "project_type": "Microservice",
        "language": "Node.js"
      }
      """
    Then the response status should be 201
    And the response JSON field "language" should equal "Node.js"

  @TS-009
  Scenario: React is not a valid language for Microservice type
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "svc-react-reject",
        "project_type": "Microservice",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "React"

  @TS-009
  Scenario: Microservice language dropdown should not contain React or Angular
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Microservice" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" should NOT have an option with value "React"
    And the element with data-testid "input-language" should NOT have an option with value "Angular"
    And the element with data-testid "input-language" should NOT have an option with value "Vue"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-010  Batch Job Project Type Language Compatibility — React Must Be Excluded
  # FR-001.A / FR-L03 — LANGUAGES_BY_TYPE["Batch Job"] = ["Java","Python","Shell"]
  # ════════════════════════════════════════════════════════════════════════════

  @TS-010
  Scenario: GET /api/languages for Batch Job returns exactly three languages
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items

  @TS-010
  Scenario: Batch Job language list contains Java, Python, and Shell
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the "languages" array contains "Java"
    And the "languages" array contains "Python"
    And the "languages" array contains "Shell"

  @TS-010
  Scenario: Batch Job language list does NOT contain React, Angular, or Vue
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"

  @TS-010
  Scenario Outline: Successfully create a Batch Job project with each compatible language
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "batch-<lang_key>",
        "project_type": "Batch Job",
        "language": "<language>"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Batch Job"
    And the response JSON field "language" should equal "<language>"

    Examples:
      | lang_key | language |
      | java     | Java     |
      | python   | Python   |
      | shell    | Shell    |

  @TS-010
  Scenario: POST /api/projects with React as language for Batch Job returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "batch-react-reject",
        "project_type": "Batch Job",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "React"
    And the response JSON field "detail" should contain "Batch Job"

  @TS-010
  Scenario: Batch Job language dropdown must not contain React
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Batch Job" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" should NOT have an option with value "React"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-011  Frontend App Project Type Language Compatibility
  # FR-001.A / FR-L03 — LANGUAGES_BY_TYPE["Frontend App"] = ["React","Angular","Vue"]
  # ════════════════════════════════════════════════════════════════════════════

  @TS-011
  Scenario: Frontend App language list contains exactly three languages
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items

  @TS-011
  Scenario: Frontend App language list contains React, Angular, and Vue
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And the "languages" array contains "React"
    And the "languages" array contains "Angular"
    And the "languages" array contains "Vue"

  @TS-011
  Scenario: Frontend App language list does NOT contain backend languages
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And the "languages" array should NOT contain "Java"
    And the "languages" array should NOT contain "Python"
    And the "languages" array should NOT contain "Shell"
    And the "languages" array should NOT contain "TypeScript"
    And the "languages" array should NOT contain "Scala"

  @TS-011
  Scenario Outline: Successfully create a Frontend App project with each compatible language
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "frontend-<lang_key>",
        "project_type": "Frontend App",
        "language": "<language>"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Frontend App"
    And the response JSON field "language" should equal "<language>"

    Examples:
      | lang_key | language |
      | react    | React    |
      | angular  | Angular  |
      | vue      | Vue      |

  @TS-011
  Scenario: POST /api/projects with Java as language for Frontend App returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "frontend-java-reject",
        "project_type": "Frontend App",
        "language": "Java"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Java"
    And the response JSON field "detail" should contain "Frontend App"

  @TS-011
  Scenario: Frontend App language dropdown shows only React, Angular, Vue
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Frontend App" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "React"
    And the element with data-testid "input-language" contains an option with text "Angular"
    And the element with data-testid "input-language" contains an option with text "Vue"
    And the element with data-testid "input-language" should NOT have an option with value "Java"
    And the element with data-testid "input-language" should NOT have an option with value "Python"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-012  Library Project Type Language Compatibility
  # FR-001.A / FR-L03 — LANGUAGES_BY_TYPE["Library"] = ["Java","Python","TypeScript"]
  # ════════════════════════════════════════════════════════════════════════════

  @TS-012
  Scenario: Library language list contains exactly three languages
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items

  @TS-012
  Scenario: Library language list contains Java, Python, and TypeScript
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the "languages" array contains "Java"
    And the "languages" array contains "Python"
    And the "languages" array contains "TypeScript"

  @TS-012
  Scenario: Library language list does NOT contain frontend frameworks
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"

  @TS-012
  Scenario Outline: Successfully create a Library project with each compatible language
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "lib-<lang_key>",
        "project_type": "Library",
        "language": "<language>"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Library"
    And the response JSON field "language" should equal "<language>"

    Examples:
      | lang_key   | language   |
      | java       | Java       |
      | python     | Python     |
      | typescript | TypeScript |

  @TS-012
  Scenario: POST /api/projects with React for Library returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "lib-react-reject",
        "project_type": "Library",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "React"
    And the response JSON field "detail" should contain "Library"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-013  Data Pipeline Project Type Language Compatibility
  # FR-001.A / FR-L03 — LANGUAGES_BY_TYPE["Data Pipeline"] = ["Python","Scala"]
  # ════════════════════════════════════════════════════════════════════════════

  @TS-013
  Scenario: Data Pipeline language list contains exactly two languages
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 2 items

  @TS-013
  Scenario: Data Pipeline language list contains Python and Scala
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the "languages" array contains "Python"
    And the "languages" array contains "Scala"

  @TS-013
  Scenario: Data Pipeline language list does NOT contain frontend or unrelated languages
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Java"
    And the "languages" array should NOT contain "Shell"
    And the "languages" array should NOT contain "TypeScript"

  @TS-013
  Scenario Outline: Successfully create a Data Pipeline project with each compatible language
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "pipeline-<lang_key>",
        "project_type": "Data Pipeline",
        "language": "<language>"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Data Pipeline"
    And the response JSON field "language" should equal "<language>"

    Examples:
      | lang_key | language |
      | python   | Python   |
      | scala    | Scala    |

  @TS-013
  Scenario: POST /api/projects with Java for Data Pipeline returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "pipeline-java-reject",
        "project_type": "Data Pipeline",
        "language": "Java"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Java"
    And the response JSON field "detail" should contain "Data Pipeline"

  @TS-013
  Scenario: Data Pipeline language dropdown shows only Python and Scala
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Data Pipeline" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    And the element with data-testid "input-language" contains an option with text "Python"
    And the element with data-testid "input-language" contains an option with text "Scala"
    And the element with data-testid "input-language" should NOT have an option with value "React"
    And the element with data-testid "input-language" should NOT have an option with value "Java"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-014  Language Dropdown Disabled Until Project Type Is Selected
  # FR-001.A / FR-L03 — HTML disabled attr on input-language, onTypeChange() JS
  # ════════════════════════════════════════════════════════════════════════════

  @TS-014
  Scenario: Language dropdown is disabled when the wizard first loads
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the element with data-testid "input-language" should be disabled

  @TS-014
  Scenario: Language dropdown becomes enabled after selecting a project type
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Library" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled

  @TS-014
  Scenario: Language dropdown initial placeholder prevents premature selection
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    Then the element with data-testid "input-language" should be disabled
    And the first option of the element with data-testid "input-language" should have text "— select a project type first —"

  @TS-014
  Scenario: Language dropdown placeholder changes to select language after type is chosen
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Batch Job" from the element with data-testid "input-type"
    Then the first option of the element with data-testid "input-language" should have text "— select a language —"

  @TS-014
  Scenario: Clearing the project type re-disables the language dropdown
    Given the portal is running at "http://localhost:8000"
    And I am on the wizard view
    When I select "Microservice" from the element with data-testid "input-type"
    Then the element with data-testid "input-language" is not disabled
    When I select the blank placeholder option from the element with data-testid "input-type"
    Then the element with data-testid "input-language" should be disabled

  @TS-014
  Scenario: Submitting with no type or language selected returns 400 from the API
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "no-type-project",
        "project_type": "",
        "language": ""
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Unknown project type"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-022  Demo Mode Bypasses ServiceNow Approval Workflow
  # FR-002 (demo) — create_project() returns 201 immediately, no pending state
  # ════════════════════════════════════════════════════════════════════════════

  @TS-022
  Scenario: POST /api/projects returns 201 Created synchronously with no approval step
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-immediate",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201

  @TS-022
  Scenario: Response body contains the full provisioned project record immediately
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-full-record",
        "project_type": "Batch Job",
        "language": "Shell"
      }
      """
    Then the response status should be 201
    And the response body has the key "id"
    And the response body has the key "project_name"
    And the response body has the key "project_type"
    And the response body has the key "language"
    And the response body has the key "members"
    And the response body has the key "created_at"

  @TS-022
  Scenario: Provisioned project is immediately available via GET /api/projects without any approval
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-visible",
        "project_type": "Frontend App",
        "language": "React"
      }
      """
    Then the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the "projects" array contains an object where "project_name" equals "demo-visible"

  @TS-022
  Scenario: Provisioned project is immediately retrievable by ID without approval
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-by-id",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "project_name" should equal "demo-by-id"

  @TS-022
  Scenario: Multiple projects can be provisioned sequentially without any approval gates
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-seq-one",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "demo-seq-two",
        "project_type": "Batch Job",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an array with at least 2 items
    And the "projects" array contains an object where "project_name" equals "demo-seq-one"
    And the "projects" array contains an object where "project_name" equals "demo-seq-two"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-030  Demo Mode Replaces Bitbucket with In-Memory Persistence
  # FR-003 (demo) — PROJECTS dict, uuid.uuid4(), list_projects(), get_project(), /api/_reset
  # ════════════════════════════════════════════════════════════════════════════

  @TS-030
  Scenario: POST /api/projects returns a server-generated UUID v4 as the project id
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "uuid-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    And the response JSON field "id" matches the UUID v4 pattern "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

  @TS-030
  Scenario: Two separate POST calls produce two different project IDs
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "project-alpha",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "id1"
    And I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "project-beta",
        "project_type": "Batch Job",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "id2"
    Then "id1" should not equal "id2"

  @TS-030
  Scenario: GET /api/projects returns empty array before any projects are created
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an empty array

  @TS-030
  Scenario: Created project is persisted and returned by GET /api/projects
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "persisted-project",
        "project_type": "Frontend App",
        "language": "Angular"
      }
      """
    Then the response status should be 201
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an array with exactly 1 items
    And the "projects" array contains an object where "project_name" equals "persisted-project"

  @TS-030
  Scenario: Created project is retrievable by its UUID via GET /api/projects/{id}
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "fetchable-project",
        "project_type": "Data Pipeline",
        "language": "Scala"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "project_name" should equal "fetchable-project"
    And the response JSON field "id" should equal the stored value "pid"

  @TS-030
  Scenario: POST /api/_reset clears all in-memory projects
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "will-be-reset",
        "project_type": "Library",
        "language": "TypeScript"
      }
      """
    Then the response status should be 201
    When I send a POST request to "/api/_reset" with no body
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    When I send a GET request to "/api/projects"
    Then the response status should be 200
    And the response JSON field "projects" is an empty array

  @TS-030
  Scenario: GET /api/projects/{id} with a non-existent UUID returns 404 — FR-L14
    When I send a GET request to "/api/projects/00000000-0000-0000-0000-000000000000"
    Then the response status should be 404
    And the response JSON field "detail" should contain "Project not found"


  # ════════════════════════════════════════════════════════════════════════════
  # TS-033  Appropriate Access Roles Assigned Based on Wizard Selections
  # FR-004.3 / FR-L08 — VALID_ROLES = ("Admin","Developer","Read-Only"), add_member()
  # ⚠ Bug #2: role allowlist guard commented out; invalid roles currently accepted
  # ════════════════════════════════════════════════════════════════════════════

  @TS-033
  Scenario: Add member with role "Admin" returns 200 and persists the Admin role
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-admin-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "admin@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Admin"
    And the response JSON field "member.user_email" should equal "admin@example.com"

  @TS-033
  Scenario: Add member with role "Developer" returns 200 and persists the Developer role
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-dev-test",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "dev@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Developer"

  @TS-033
  Scenario: Add member with role "Read-Only" returns 200 and persists the Read-Only role
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-readonly-test",
        "project_type": "Batch Job",
        "language": "Shell"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "viewer@example.com",
        "role": "Read-Only"
      }
      """
    Then the response status should be 200
    And the response JSON field "member.role" should equal "Read-Only"

  @TS-033
  Scenario: Add member with role "GodMode" must return 400 — FR-L08 (⚠ Bug #2 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-godmode-test",
        "project_type": "Microservice",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "hacker@example.com",
        "role": "GodMode"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Admin"
    And the response JSON field "detail" should contain "Developer"
    And the response JSON field "detail" should contain "Read-Only"

  @TS-033
  Scenario: Add member with role "admin" (wrong case) must return 400 — FR-L08 (⚠ Bug #2 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-case-test",
        "project_type": "Library",
        "language": "TypeScript"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "wrongcase@example.com",
        "role": "admin"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Admin"

  @TS-033
  Scenario: Add member with role "DEVELOPER" (all-caps) must return 400 — FR-L08 (⚠ Bug #2 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-caps-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "allcaps@example.com",
        "role": "DEVELOPER"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" should contain "Developer"

  @TS-033
  Scenario: Role stored correctly and visible via GET /api/projects/{id}
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "role-persist-test",
        "project_type": "Data Pipeline",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "stored@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the "members" array contains an object where "role" equals "Developer"

  @TS-033
  Scenario: Role dropdown in Add Member UI offers exactly the three valid roles plus blank placeholder
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    When I click the element with data-testid "card-add"
    Then the element with data-testid "input-member-role" contains an option with text "Admin"
    And the element with data-testid "input-member-role" contains an option with text "Developer"
    And the element with data-testid "input-member-role" contains an option with text "Read-Only"
    And the element with data-testid "input-member-role" should contain exactly 4 options


  # ════════════════════════════════════════════════════════════════════════════
  # TS-036  Demo Mode Records Access Grants as In-Memory Tuples
  # FR-004 (demo) — project["members"] list of {user_email, role} tuples
  # ⚠ Bug #3: remove_member() is a no-op — member stays in list after DELETE
  # ════════════════════════════════════════════════════════════════════════════

  @TS-036
  Scenario: POST /api/projects/{id}/members stores the {user_email, role} tuple
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "tuple-store-test",
        "project_type": "Library",
        "language": "Python"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "member.user_email" should equal "alice@example.com"
    And the response JSON field "member.role" should equal "Developer"

  @TS-036
  Scenario: Stored {user_email, role} tuple is retrievable via GET /api/projects/{id}
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "tuple-get-test",
        "project_type": "Microservice",
        "language": "Python/Flask"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "bob@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "members" is an array with exactly 1 items
    And the "members" array contains an object where "user_email" equals "bob@example.com"
    And the "members" array contains an object where "role" equals "Admin"

  @TS-036
  Scenario: Multiple {user_email, role} tuples can be stored for the same project
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "multi-tuple-test",
        "project_type": "Frontend App",
        "language": "Angular"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "lead@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "contributor@example.com",
        "role": "Read-Only"
      }
      """
    Then the response status should be 200
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "members" is an array with exactly 2 items

  @TS-036
  Scenario: Attempting to store the same email twice returns 409 Conflict — FR-L10
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "dup-tuple-test",
        "project_type": "Data Pipeline",
        "language": "Scala"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "duplicate@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "duplicate@example.com",
        "role": "Admin"
      }
      """
    Then the response status should be 409
    And the response JSON field "detail" should contain "Member already in project"

  @TS-036
  Scenario: DELETE removes the access tuple from members array — FR-L12 (⚠ Bug #3 will fail this)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "removal-tuple-test",
        "project_type": "Library",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a POST request to "/api/projects/{pid}/members" with body:
      """
      {
        "user_email": "alice@example.com",
        "role": "Developer"
      }
      """
    Then the response status should be 200
    When I send a DELETE request to "/api/projects/{pid}/members/alice@example.com"
    Then the response status should be 200
    And the response JSON field "status" should equal "ok"
    And the response JSON field "removed" should equal "alice@example.com"
    When I send a GET request to "/api/projects/{pid}"
    Then the response status should be 200
    And the response JSON field "members" is an empty array
    And the "members" array should NOT contain an object where "user_email" equals "alice@example.com"

  @TS-036
  Scenario: Deleting a non-existent member email returns 404 — FR-L13
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "no-member-delete-test",
        "project_type": "Batch Job",
        "language": "Java"
      }
      """
    Then the response status should be 201
    When I remember the response JSON field "id" as "pid"
    And I send a DELETE request to "/api/projects/{pid}/members/nobody@example.com"
    Then the response status should be 404
    And the response JSON field "detail" should contain "Member not found"

  @TS-036
  Scenario: Members view shows No members yet when a project has no members — FR-L15
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "empty-members-ui",
        "project_type": "Library",
        "language": "TypeScript"
      }
      """
    Then the response status should be 201
    Given the portal is running at "http://localhost:8000"
    And I am on the landing page
    When I click the element with data-testid "card-add"
    And I select "empty-members-ui" from the element with data-testid "select-project"
    Then the element with data-testid "member-list-empty" is visible
    And the element with data-testid "member-list-empty" should contain the text "No members yet"