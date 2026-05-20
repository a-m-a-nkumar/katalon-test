@regression
Feature: Project Provisioning Portal — Full Test Suite

  All implementation-level BDD scenarios for the Project Provisioning Portal demo app.
  API base URL: http://localhost:8000  |  Storage: in-memory Python dict  |  Framework: FastAPI
  Planted bugs: BUG-001 (duplicate names), BUG-002 (role allowlist), BUG-003 (delete no-op).
  Test helper: POST /api/_reset  wipes PROJECTS dict between scenarios.

  # ==========================================================================
  @TS-001 @regression
  Rule: Wizard-Based Interface for New Project Creation

    The landing page at GET / serves an HTML SPA. The wizard view is rendered
    in the element with id "view-wizard". Navigation is driven by JavaScript
    showView() calls and data-testid attributes on every interactive element
    (NFR-3). Endpoint: GET /  Implementation: INDEX_HTML string returned by
    the FastAPI index() route handler.

    Background:
      Given the Project Provisioning Portal is running at "http://localhost:8000"

    # ── AC-08 ─────────────────────────────────────────────────────────────────

    Scenario: Landing page returns HTTP 200
      When I send a GET request to "/"
      Then the response status should be 200
      And the response Content-Type should contain "text/html"

    Scenario: Landing page HTML contains the three required action card data-testid attributes
      When I send a GET request to "/"
      Then the response body should contain 'data-testid="card-create"'
      And the response body should contain 'data-testid="card-add"'
      And the response body should contain 'data-testid="card-remove"'

    Scenario: Landing page action cards display correct labels
      When I navigate to "http://localhost:8000/" in the browser
      Then the element with data-testid "card-create" should contain the text "New Project"
      And the element with data-testid "card-add" should contain the text "Add Member"
      And the element with data-testid "card-remove" should contain the text "Remove Member"

    # ── Wizard view activation ────────────────────────────────────────────────

    Scenario: Clicking the New Project card makes the wizard view active and hides the landing view
      Given I am on the landing page at "http://localhost:8000/"
      When I click the element with data-testid "card-create"
      Then the element with id "view-wizard" should have CSS class "active"
      And the element with id "view-landing" should NOT have CSS class "active"

    Scenario: Wizard view contains project type select element
      Given I have navigated to the wizard view
      Then the element with data-testid "input-type" should exist
      And the element with data-testid "input-type" should be a "select" element

    Scenario: Wizard view contains language select element that is initially disabled
      Given I have navigated to the wizard view
      Then the element with data-testid "input-language" should exist
      And the element with data-testid "input-language" should be a "select" element
      And the element with data-testid "input-language" should have the "disabled" attribute

    Scenario: Wizard view contains project name text input with correct placeholder
      Given I have navigated to the wizard view
      Then the element with data-testid "input-name" should exist
      And the element with data-testid "input-name" should be an "input" element
      And the element with data-testid "input-name" should have placeholder "my-project-name"

    Scenario: Wizard view contains a Create project submit button and a Back cancel button
      Given I have navigated to the wizard view
      Then the element with data-testid "btn-submit" should exist
      And the element with data-testid "btn-cancel" should exist
      And the element with data-testid "btn-submit" should have text "Create project"
      And the element with data-testid "btn-cancel" should have text "Back"

    Scenario: Clicking the Back button from the wizard returns to the landing view
      Given I have navigated to the wizard view
      When I click the element with data-testid "btn-cancel"
      Then the element with id "view-landing" should have CSS class "active"
      And the element with id "view-wizard" should NOT have CSS class "active"

    Scenario: Wizard error banner is hidden by default
      Given I have navigated to the wizard view
      Then the element with data-testid "wizard-error" should have inline style "display:none"

    Scenario: Wizard success banner is hidden by default
      Given I have navigated to the wizard view
      Then the element with data-testid "wizard-success" should have inline style "display:none"

    # ── Project list on landing ───────────────────────────────────────────────

    Scenario: Landing page contains a project list container
      When I navigate to "http://localhost:8000/" in the browser
      Then the element with data-testid "project-list" should exist
      And the element with data-testid "project-list" should be a "ul" element

    Scenario: Project list shows empty state when no projects exist
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I navigate to "http://localhost:8000/" in the browser
      Then the element with data-testid "project-list-empty" should be visible
      And the element with data-testid "project-list-empty" should contain the text "No projects yet."

  # ==========================================================================
  @TS-002 @regression
  Rule: Project Type Selection in Wizard

    The wizard's first dropdown is populated by GET /api/project-types which
    returns a JSON object {"project_types": [...]}. The route handler is
    get_project_types() in app.py. The PROJECT_TYPES constant holds the
    canonical list of five supported types. The frontend loadProjectTypes()
    function populates the <select data-testid="input-type"> on wizard init.
    Implementation: FR-L02.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"

    # ── API contract ──────────────────────────────────────────────────────────

    Scenario: GET /api/project-types returns HTTP 200 with JSON Content-Type
      When I send a GET request to "/api/project-types"
      Then the response status should be 200
      And the response Content-Type should contain "application/json"

    Scenario: GET /api/project-types response envelope contains a "project_types" key
      When I send a GET request to "/api/project-types"
      Then the response status should be 200
      And the response body should have a top-level key "project_types"
      And the value of "project_types" should be a JSON array

    Scenario: GET /api/project-types returns exactly the five supported project types
      When I send a GET request to "/api/project-types"
      Then the response status should be 200
      And the response field "project_types" should be a list of length 5
      And the response field "project_types" should contain "Microservice"
      And the response field "project_types" should contain "Batch Job"
      And the response field "project_types" should contain "Frontend App"
      And the response field "project_types" should contain "Library"
      And the response field "project_types" should contain "Data Pipeline"

    Scenario: GET /api/project-types does NOT include unlisted types
      When I send a GET request to "/api/project-types"
      Then the response field "project_types" should NOT contain "Monolith"
      And the response field "project_types" should NOT contain "Mobile App"
      And the response field "project_types" should NOT contain "Serverless"

    Scenario: GET /api/project-types is idempotent across repeated calls
      When I send a GET request to "/api/project-types"
      And I store the response body as "first_response"
      And I send a GET request to "/api/project-types"
      Then the response body should equal "first_response"

    # ── UI contract ───────────────────────────────────────────────────────────

    Scenario: Project type dropdown in wizard is populated with all five types on page load
      Given I am on the wizard view at "http://localhost:8000/"
      When the page JavaScript has finished executing
      Then the element with data-testid "input-type" should contain an option with text "Microservice"
      And the element with data-testid "input-type" should contain an option with text "Batch Job"
      And the element with data-testid "input-type" should contain an option with text "Frontend App"
      And the element with data-testid "input-type" should contain an option with text "Library"
      And the element with data-testid "input-type" should contain an option with text "Data Pipeline"

    Scenario: Project type dropdown includes a blank placeholder option as first option
      Given I am on the wizard view at "http://localhost:8000/"
      When the page JavaScript has finished executing
      Then the first option of the element with data-testid "input-type" should have value ""
      And the first option of the element with data-testid "input-type" should have text "— select a type —"

    Scenario: Project type dropdown contains exactly six options (placeholder plus five types)
      Given I am on the wizard view at "http://localhost:8000/"
      When the page JavaScript has finished executing
      Then the element with data-testid "input-type" should contain exactly 6 options

  # ==========================================================================
  @TS-003 @regression
  Rule: Language/Framework Options Vary by Selected Project Type

    GET /api/languages?project_type=<type> is handled by get_languages()
    in app.py. It reads from the LANGUAGES_BY_TYPE dict (the compatibility
    matrix). Returns {"languages": [...]} on success or HTTP 400 with
    {"detail": "Unknown project type: '<type>'"} for unknown types.
    The frontend onTypeChange() fetches this endpoint and enables the
    <select data-testid="input-language">. POST /api/projects also cross-
    validates the combination server-side. Implementation: FR-L03.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"

    # ── Response shape ────────────────────────────────────────────────────────

    Scenario: GET /api/languages returns HTTP 200 with JSON Content-Type for a valid project type
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response status should be 200
      And the response Content-Type should contain "application/json"
      And the response body should have a top-level key "languages"
      And the value of "languages" should be a JSON array

    # ── Happy paths per type (covered by TS-009 through TS-013 as well) ───────

    Scenario: Languages for Microservice contain exactly Java/Spring Boot, Python/Flask, Node.js
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java/Spring Boot"
      And the response field "languages" should contain "Python/Flask"
      And the response field "languages" should contain "Node.js"

    Scenario: Languages for Batch Job contain exactly Java, Python, Shell and do NOT contain React
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java"
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "Shell"
      And the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"

    Scenario: Languages for Frontend App contain exactly React, Angular, Vue
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "React"
      And the response field "languages" should contain "Angular"
      And the response field "languages" should contain "Vue"

    Scenario: Languages for Library contain exactly Java, Python, TypeScript
      When I send a GET request to "/api/languages?project_type=Library"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java"
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "TypeScript"

    Scenario: Languages for Data Pipeline contain exactly Python and Scala
      When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
      Then the response status should be 200
      And the response field "languages" should be a list of length 2
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "Scala"

    # ── Error cases ───────────────────────────────────────────────────────────

    Scenario: GET /api/languages with an unknown project type returns HTTP 400
      When I send a GET request to "/api/languages?project_type=Unknown"
      Then the response status should be 400
      And the response Content-Type should contain "application/json"
      And the response field "detail" should contain "Unknown project type"
      And the response field "detail" should contain "'Unknown'"

    Scenario: GET /api/languages with an empty project_type returns HTTP 400
      When I send a GET request to "/api/languages?project_type="
      Then the response status should be 400
      And the response field "detail" should contain "Unknown project type"

    Scenario: GET /api/languages with project_type parameter missing returns HTTP 422
      When I send a GET request to "/api/languages"
      Then the response status should be 422

    # ── Server-side cross-validation on POST /api/projects ───────────────────

    Scenario: POST /api/projects with incompatible language for Batch Job returns HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "batch-react-combo",
          "project_type": "Batch Job",
          "language": "React"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "'React'"
      And the response field "detail" should contain "'Batch Job'"
      And the response field "detail" should contain "not valid for project type"

    Scenario: POST /api/projects with incompatible language for Microservice returns HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "micro-vue-combo",
          "project_type": "Microservice",
          "language": "Vue"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "'Vue'"
      And the response field "detail" should contain "'Microservice'"

    Scenario: POST /api/projects with incompatible language for Data Pipeline returns HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "pipeline-angular",
          "project_type": "Data Pipeline",
          "language": "Angular"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "'Angular'"
      And the response field "detail" should contain "'Data Pipeline'"

    Scenario: POST /api/projects with unknown language for known project type returns HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "cobol-micro",
          "project_type": "Microservice",
          "language": "COBOL"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "'COBOL'"
      And the response field "detail" should contain "not valid for project type"
      And the response field "detail" should contain "Allowed:"

    # ── URL encoding ──────────────────────────────────────────────────────────

    Scenario: GET /api/languages with URL-encoded "Batch Job" resolves correctly
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response status should be 200
      And the response field "languages" should contain "Java"

    Scenario: GET /api/languages with URL-encoded "Frontend App" resolves correctly
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response status should be 200
      And the response field "languages" should contain "React"

    Scenario: GET /api/languages with URL-encoded "Data Pipeline" resolves correctly
      When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
      Then the response status should be 200
      And the response field "languages" should contain "Python"

  # ==========================================================================
  @TS-004 @regression
  Rule: Project Name Collection and Validation

    POST /api/projects is handled by create_project() in app.py.
    Request model: CreateProjectRequest {project_name, project_type, language}.
    Name validation rules (FR-L05):
      - Strip whitespace; reject if empty  → HTTP 400 "Project name is required"
      - Regex ^[A-Za-z0-9-]+$ enforced    → HTTP 400 "Project name must contain
        only ASCII letters, digits, and hyphens"
    Name uniqueness (FR-L06 — PLANTED BUG #1):
      - Correct behaviour: second POST with same name → HTTP 409
        {"detail": "Project name already exists"}
      - Current buggy behaviour: second POST succeeds with HTTP 201
    Successful creation returns HTTP 201 with the full project record.
    Test helper POST /api/_reset wipes the PROJECTS dict between scenarios.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state

    # ── Happy path ────────────────────────────────────────────────────────────

    Scenario: POST /api/projects with valid name returns HTTP 201 and a full project record
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "my-new-project",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 201
      And the response Content-Type should contain "application/json"
      And the response field "project_name" should equal "my-new-project"
      And the response field "project_type" should equal "Microservice"
      And the response field "language" should equal "Java/Spring Boot"
      And the response field "id" should be a non-empty string
      And the response field "members" should be an empty array
      And the response field "created_at" should be a non-empty string

    Scenario: Created project ID is a valid UUID v4
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "uuid-check-project",
          "project_type": "Library",
          "language": "Python"
        }
        """
      Then the response status should be 201
      And the response field "id" should match the UUID v4 pattern
        "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

    Scenario: Created project appears in GET /api/projects immediately after creation
      Given I have successfully created a project named "visible-project" with type "Library" and language "Python"
      When I send a GET request to "/api/projects"
      Then the response status should be 200
      And the response field "projects" should contain an entry with "project_name" equal to "visible-project"

    Scenario: Created project is retrievable by its ID via GET /api/projects/{id}
      Given I have successfully created a project named "get-by-id-project" with type "Data Pipeline" and language "Scala"
      And I have stored the created project ID as "project_id"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "project_name" should equal "get-by-id-project"

    Scenario: Project name is trimmed of leading and trailing whitespace before validation
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "  trimmed-name  ",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "trimmed-name"

    Scenario: Project name consisting entirely of hyphens is accepted
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "---",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "---"

    Scenario: Project name of a single valid character is accepted
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "x",
          "project_type": "Frontend App",
          "language": "React"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "x"

    Scenario: Project name with mix of uppercase, lowercase, digits, and hyphens is accepted
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "My-Project-2024",
          "project_type": "Library",
          "language": "TypeScript"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "My-Project-2024"

    Scenario: Project name consisting only of digits is accepted
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "123456",
          "project_type": "Batch Job",
          "language": "Shell"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "123456"

    # ── Name format validation (FR-L05) ──────────────────────────────────────

    Scenario: POST /api/projects with empty project name returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Project name is required"

    Scenario: POST /api/projects with whitespace-only project name returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "   ",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Project name is required"

    Scenario: POST /api/projects with project name containing a space returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "bad name",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: POST /api/projects with project name containing exclamation mark returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "bad-name!",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: POST /api/projects with project name containing underscore returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "bad_underscore",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: POST /api/projects with project name containing dot returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "bad.name",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: POST /api/projects with project name containing at-sign returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "bad@name",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: POST /api/projects with project name containing Unicode characters returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "pr\u00f6ject",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    # ── Name uniqueness (FR-L06) — PLANTED BUG #1 — these tests are expected
    #    to FAIL against the current buggy implementation and PASS after fix ───

    Scenario: [BUG-001] POST /api/projects with a duplicate project name returns HTTP 409
      Given I have successfully created a project named "duplicate-project" with type "Microservice" and language "Python/Flask"
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "duplicate-project",
          "project_type": "Microservice",
          "language": "Python/Flask"
        }
        """
      Then the response status should be 409
      And the response field "detail" should equal "Project name already exists"

    Scenario: [BUG-001] Duplicate name check is case-insensitive
      Given I have successfully created a project named "case-project" with type "Microservice" and language "Node.js"
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "CASE-PROJECT",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 409
      And the response field "detail" should equal "Project name already exists"

    Scenario: [BUG-001] Two unique project names can both be created with HTTP 201
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "first-unique-project",
          "project_type": "Microservice",
          "language": "Java/Spring Boot"
        }
        """
      Then the response status should be 201
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "second-unique-project",
          "project_type": "Library",
          "language": "Python"
        }
        """
      Then the response status should be 201
      And "GET /api/projects" should return exactly 2 projects

    # ── Unknown project type (separate from name validation) ─────────────────

    Scenario: POST /api/projects with unknown project type returns HTTP 400
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "type-unknown",
          "project_type": "MobileApp",
          "language": "Swift"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Unknown project type"
      And the response field "detail" should contain "'MobileApp'"

    # ── GET /api/projects/{id} ────────────────────────────────────────────────

    Scenario: GET /api/projects with a non-existent UUID returns HTTP 404
      When I send a GET request to "/api/projects/00000000-0000-0000-0000-000000000000"
      Then the response status should be 404
      And the response field "detail" should equal "Project not found"

  # ==========================================================================
  @TS-005 @regression
  Rule: Optional Team Member Addition with Role Assignment

    POST /api/projects/{project_id}/members is handled by add_member() in
    app.py. Request model: AddMemberRequest {user_email, role}.
    Validation rules:
      - Project must exist              → HTTP 404 "Project not found"
      - email must contain "@"          → HTTP 400 "Valid email is required" (FR-L09)
      - role must be in VALID_ROLES     → HTTP 400 (FR-L08 — PLANTED BUG #2, not enforced)
        VALID_ROLES = ("Admin", "Developer", "Read-Only")
      - email must not be duplicate     → HTTP 409 "Member already in project" (FR-L10)
    Success: HTTP 200 {"status": "ok", "member": {"user_email": ..., "role": ...}}

    DELETE /api/projects/{project_id}/members/{user_email} is handled by
    remove_member() in app.py.
    PLANTED BUG #3: The member list is NOT modified; response is HTTP 200 but
    a subsequent GET still shows the deleted member.
    Correct behaviour: member removed from list; HTTP 404 if member not found.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state
      And I have successfully created a project named "member-test-project" with type "Microservice" and language "Java/Spring Boot"
      And I have stored the created project ID as "project_id"

    # ── Add member happy path (FR-L11) ────────────────────────────────────────

    Scenario: Successfully add a member with the Admin role
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "alice@example.com",
          "role": "Admin"
        }
        """
      Then the response status should be 200
      And the response field "status" should equal "ok"
      And the response field "member.user_email" should equal "alice@example.com"
      And the response field "member.role" should equal "Admin"

    Scenario: Successfully add a member with the Developer role
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "bob@example.com",
          "role": "Developer"
        }
        """
      Then the response status should be 200
      And the response field "status" should equal "ok"
      And the response field "member.user_email" should equal "bob@example.com"
      And the response field "member.role" should equal "Developer"

    Scenario: Successfully add a member with the Read-Only role
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "carol@example.com",
          "role": "Read-Only"
        }
        """
      Then the response status should be 200
      And the response field "status" should equal "ok"
      And the response field "member.user_email" should equal "carol@example.com"
      And the response field "member.role" should equal "Read-Only"

    Scenario: Added member persists in GET /api/projects/{id} response
      Given I have added member "dave@example.com" with role "Developer" to project "{project_id}"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should contain an entry where "user_email" equals "dave@example.com"
      And the response field "members" should contain an entry where "role" equals "Developer"

    Scenario: Multiple members with different roles can all be added to the same project
      Given I have added member "alice@example.com" with role "Admin" to project "{project_id}"
      And I have added member "bob@example.com" with role "Developer" to project "{project_id}"
      And I have added member "carol@example.com" with role "Read-Only" to project "{project_id}"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should have a length of 3
      And the response field "members" should contain an entry where "user_email" equals "alice@example.com" and "role" equals "Admin"
      And the response field "members" should contain an entry where "user_email" equals "bob@example.com" and "role" equals "Developer"
      And the response field "members" should contain an entry where "user_email" equals "carol@example.com" and "role" equals "Read-Only"

    Scenario: Project created with no team members has an empty members array
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should be an empty array

    # ── Email validation (FR-L09) ─────────────────────────────────────────────

    Scenario: Reject add-member with an email that does not contain "@" returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "not-an-email",
          "role": "Developer"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Valid email is required"

    Scenario: Reject add-member with an empty email string returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "",
          "role": "Developer"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Valid email is required"

    Scenario: Reject add-member with a whitespace-only email returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "   ",
          "role": "Developer"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Valid email is required"

    Scenario: Accept an email that contains "@" with no domain validation
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "user@",
          "role": "Developer"
        }
        """
      Then the response status should be 200

    # ── Role validation (FR-L08) — PLANTED BUG #2 — these tests are expected
    #    to FAIL against the current buggy implementation and PASS after fix ───

    Scenario: [BUG-002] Reject add-member with role "GodMode" returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "hacker@example.com",
          "role": "GodMode"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"
      And the response field "detail" should contain "'GodMode'"
      And the response field "detail" should contain "Admin"
      And the response field "detail" should contain "Developer"
      And the response field "detail" should contain "Read-Only"

    Scenario: [BUG-002] Reject add-member with role "Superuser" returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "super@example.com",
          "role": "Superuser"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"
      And the response field "detail" should contain "'Superuser'"

    Scenario: [BUG-002] Reject add-member with empty role string returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "empty-role@example.com",
          "role": ""
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    Scenario: [BUG-002] Reject add-member with role "admin" (wrong case) returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "lowercase@example.com",
          "role": "admin"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    Scenario: [BUG-002] Reject add-member with role "DEVELOPER" (wrong case) returns HTTP 400
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "uppercasedev@example.com",
          "role": "DEVELOPER"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    Scenario: Accepting all three valid roles in separate requests succeeds
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "user-admin@example.com", "role": "Admin"}
        """
      Then the response status should be 200
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "user-dev@example.com", "role": "Developer"}
        """
      Then the response status should be 200
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "user-ro@example.com", "role": "Read-Only"}
        """
      Then the response status should be 200

    # ── Duplicate member prevention (FR-L10) ─────────────────────────────────

    Scenario: Reject duplicate member email returns HTTP 409
      Given I have added member "alice@example.com" with role "Developer" to project "{project_id}"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "alice@example.com",
          "role": "Admin"
        }
        """
      Then the response status should be 409
      And the response field "detail" should equal "Member already in project"

    Scenario: Duplicate email check is case-insensitive
      Given I have added member "alice@example.com" with role "Developer" to project "{project_id}"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "ALICE@EXAMPLE.COM",
          "role": "Admin"
        }
        """
      Then the response status should be 409
      And the response field "detail" should equal "Member already in project"

    # ── Project not found (FR-L14) ────────────────────────────────────────────

    Scenario: Reject add-member to a non-existent project returns HTTP 404
      When I send a POST request to "/api/projects/00000000-0000-0000-0000-000000000000/members" with body:
        """
        {
          "user_email": "ghost@example.com",
          "role": "Developer"
        }
        """
      Then the response status should be 404
      And the response field "detail" should equal "Project not found"

    # ── Remove member (FR-L12/13) — PLANTED BUG #3 ───────────────────────────

    Scenario: [BUG-003] DELETE member returns HTTP 200 with removed email in response
      Given I have added member "alice@example.com" with role "Developer" to project "{project_id}"
      When I send a DELETE request to "/api/projects/{project_id}/members/alice@example.com"
      Then the response status should be 200
      And the response field "status" should equal "ok"
      And the response field "removed" should equal "alice@example.com"

    Scenario: [BUG-003] After DELETE, the removed member does NOT appear in GET /api/projects/{id}
      Given I have added member "alice@example.com" with role "Developer" to project "{project_id}"
      And I have sent a DELETE request to "/api/projects/{project_id}/members/alice@example.com"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should NOT contain any entry where "user_email" equals "alice@example.com"

    Scenario: [BUG-003] After DELETE, the remaining members are still present
      Given I have added member "alice@example.com" with role "Admin" to project "{project_id}"
      And I have added member "bob@example.com" with role "Developer" to project "{project_id}"
      And I have sent a DELETE request to "/api/projects/{project_id}/members/alice@example.com"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should NOT contain any entry where "user_email" equals "alice@example.com"
      And the response field "members" should contain an entry where "user_email" equals "bob@example.com"

    Scenario: DELETE non-existent member returns HTTP 404
      When I send a DELETE request to "/api/projects/{project_id}/members/notamember@example.com"
      Then the response status should be 404
      And the response field "detail" should equal "Member not found"

    Scenario: DELETE member from non-existent project returns HTTP 404
      When I send a DELETE request to "/api/projects/00000000-0000-0000-0000-000000000000/members/test@example.com"
      Then the response status should be 404
      And the response field "detail" should equal "Project not found"

    # ── Empty member list rendering (FR-L15) ─────────────────────────────────

    Scenario: Member list view for a project with no members shows empty state element
      Given I am on the members view with project "{project_id}" selected
      Then the element with data-testid "member-list-empty" should be visible
      And the element with data-testid "member-list-empty" should contain the text "No members yet."

  # ==========================================================================
  @TS-006 @regression
  Rule: Smart Decisions and Narrowed-Down Options Based on Selections

    Context-aware filtering is driven by two mechanisms:
    1. API-level: GET /api/languages?project_type=<type> returns only
       compatible languages from the LANGUAGES_BY_TYPE dict.
    2. UI-level: <select data-testid="input-language"> starts disabled.
       onTypeChange() in app.py's embedded JavaScript fetches
       GET /api/languages and re-populates the language dropdown,
       then calls langSel.disabled = false.
    Server-side POST /api/projects validates the combination independently.
    Implementation: FR-L03.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"

    # ── API filtering: compatible languages only ──────────────────────────────

    Scenario: Language list for Microservice never includes frontend-only options
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response status should be 200
      And the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"

    Scenario: Language list for Batch Job never includes frontend-only options
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response status should be 200
      And the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"

    Scenario: Language list for Data Pipeline never includes frontend-only options
      When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
      Then the response status should be 200
      And the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"

    Scenario: Language list for Library never includes frontend-only options
      When I send a GET request to "/api/languages?project_type=Library"
      Then the response status should be 200
      And the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"

    Scenario: Language list for Frontend App never includes backend-only options
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response status should be 200
      And the response field "languages" should NOT contain "Java/Spring Boot"
      And the response field "languages" should NOT contain "Python/Flask"
      And the response field "languages" should NOT contain "Node.js"
      And the response field "languages" should NOT contain "Shell"
      And the response field "languages" should NOT contain "Scala"

    Scenario: Language list for each type changes as project type selection changes
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response field "languages" should contain "Java/Spring Boot"
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response field "languages" should NOT contain "Java/Spring Boot"
      And the response field "languages" should contain "React"

    # ── Server-side cross-validation prevents incompatible combinations ───────

    Scenario Outline: POST /api/projects rejects incompatible type+language combinations
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "compat-test",
          "project_type": "<project_type>",
          "language": "<language>"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "not valid for project type"

      Examples:
        | project_type  | language         |
        | Microservice  | React            |
        | Microservice  | Angular          |
        | Microservice  | Vue              |
        | Batch Job     | React            |
        | Batch Job     | Angular          |
        | Batch Job     | TypeScript       |
        | Frontend App  | Java/Spring Boot |
        | Frontend App  | Python/Flask     |
        | Frontend App  | Shell            |
        | Library       | React            |
        | Library       | Shell            |
        | Data Pipeline | React            |
        | Data Pipeline | Java/Spring Boot |

    # ── UI: language dropdown is disabled until a project type is selected ────

    Scenario: Language dropdown starts disabled on wizard load before any type selection
      Given I have navigated to the wizard view at "http://localhost:8000/"
      When no project type has been selected in the element with data-testid "input-type"
      Then the element with data-testid "input-language" should have the "disabled" attribute

    Scenario: Language dropdown becomes enabled after selecting a project type
      Given I have navigated to the wizard view at "http://localhost:8000/"
      When I select "Microservice" in the element with data-testid "input-type"
      And I wait for the onTypeChange AJAX call to complete
      Then the element with data-testid "input-language" should NOT have the "disabled" attribute

    Scenario: After selecting Microservice, language dropdown contains only Microservice-compatible options
      Given I have navigated to the wizard view at "http://localhost:8000/"
      When I select "Microservice" in the element with data-testid "input-type"
      And I wait for the onTypeChange AJAX call to complete
      Then the element with data-testid "input-language" should contain an option with text "Java/Spring Boot"
      And the element with data-testid "input-language" should contain an option with text "Python/Flask"
      And the element with data-testid "input-language" should contain an option with text "Node.js"
      And the element with data-testid "input-language" should NOT contain an option with text "React"
      And the element with data-testid "input-language" should NOT contain an option with text "Angular"

    Scenario: After switching from Microservice to Batch Job, language dropdown updates to Batch Job options
      Given I have navigated to the wizard view at "http://localhost:8000/"
      When I select "Microservice" in the element with data-testid "input-type"
      And I wait for the onTypeChange AJAX call to complete
      And I select "Batch Job" in the element with data-testid "input-type"
      And I wait for the onTypeChange AJAX call to complete
      Then the element with data-testid "input-language" should contain an option with text "Java"
      And the element with data-testid "input-language" should contain an option with text "Python"
      And the element with data-testid "input-language" should contain an option with text "Shell"
      And the element with data-testid "input-language" should NOT contain an option with text "Java/Spring Boot"
      And the element with data-testid "input-language" should NOT contain an option with text "React"

  # ==========================================================================
  @TS-007 @regression
  Rule: Input Validation Before Submission

    All validation is enforced server-side in app.py. The API returns
    structured JSON error responses using FastAPI's default error shape:
    {"detail": "<message>"} (NFR-4). The frontend submits via fetch() in
    submitWizard() / addMember() and displays errors in
    <div data-testid="wizard-error"> or <div data-testid="member-error">.

    Server validation on POST /api/projects:
      - project_name non-empty (after strip)         → 400 "Project name is required"
      - project_name regex ^[A-Za-z0-9-]+$           → 400 "Project name must contain only ASCII letters, digits, and hyphens"
      - project_type in PROJECT_TYPES                → 400 "Unknown project type: '<value>'"
      - language compatible with project_type        → 400 "Language '<v>' is not valid for project type '<v>'. Allowed: [...]"

    Server validation on POST /api/projects/{id}/members:
      - project must exist                           → 404 "Project not found"
      - email must contain "@" (after strip)         → 400 "Valid email is required"
      - role in VALID_ROLES (BUG #2 not enforced)    → 400 "Invalid role '<v>'. Must be one of: Admin, Developer, Read-Only"
      - email not duplicate (case-insensitive)       → 409 "Member already in project"

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state

    # ── POST /api/projects — required field and format ────────────────────────

    Scenario: All-valid payload for POST /api/projects returns HTTP 201
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "valid-project",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 201
      And the response Content-Type should contain "application/json"

    Scenario: Missing project_name field is treated as invalid and returns HTTP 422
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 422

    Scenario: Missing project_type field returns HTTP 422
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "valid-project",
          "language": "Node.js"
        }
        """
      Then the response status should be 422

    Scenario: Missing language field returns HTTP 422
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "valid-project",
          "project_type": "Microservice"
        }
        """
      Then the response status should be 422

    Scenario: Empty request body returns HTTP 422
      When I send a POST request to "/api/projects" with an empty body
      Then the response status should be 422

    Scenario: Empty project name (after strip) returns HTTP 400 with correct detail
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "  ",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Project name is required"

    Scenario: Project name with invalid characters returns HTTP 400 with format message
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "name with spaces",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "only ASCII letters, digits, and hyphens"

    Scenario: Unknown project type returns HTTP 400 with detail containing the unknown value
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "valid-name",
          "project_type": "Blockchain",
          "language": "Solidity"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Unknown project type"
      And the response field "detail" should contain "'Blockchain'"

    Scenario: Language incompatible with project type returns HTTP 400 with detail listing allowed values
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "valid-name",
          "project_type": "Data Pipeline",
          "language": "Node.js"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "'Node.js'"
      And the response field "detail" should contain "'Data Pipeline'"
      And the response field "detail" should contain "Allowed:"

    # ── POST /api/projects/{id}/members — field validation ───────────────────

    Scenario: All-valid payload for POST /api/projects/{id}/members returns HTTP 200
      Given I have successfully created a project named "val-member-project" with type "Library" and language "Python"
      And I have stored the created project ID as "project_id"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "valid@example.com",
          "role": "Developer"
        }
        """
      Then the response status should be 200
      And the response field "status" should equal "ok"

    Scenario: Missing user_email field on add-member returns HTTP 422
      Given I have successfully created a project named "val-member-project-2" with type "Library" and language "Python"
      And I have stored the created project ID as "project_id"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "role": "Developer"
        }
        """
      Then the response status should be 422

    Scenario: Missing role field on add-member returns HTTP 422
      Given I have successfully created a project named "val-member-project-3" with type "Library" and language "Python"
      And I have stored the created project ID as "project_id"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "test@example.com"
        }
        """
      Then the response status should be 422

    Scenario: Invalid email (no "@") on add-member returns HTTP 400 with correct detail
      Given I have successfully created a project named "val-member-project-4" with type "Library" and language "Python"
      And I have stored the created project ID as "project_id"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "invalidemail",
          "role": "Developer"
        }
        """
      Then the response status should be 400
      And the response field "detail" should equal "Valid email is required"

    # ── UI error banner display ───────────────────────────────────────────────

    Scenario: Submitting wizard with empty project name shows error banner in the UI
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Microservice" in the element with data-testid "input-type"
      And I have selected "Node.js" in the element with data-testid "input-language"
      And the element with data-testid "input-name" is empty
      When I click the element with data-testid "btn-submit"
      Then the element with data-testid "wizard-error" should be visible
      And the element with data-testid "wizard-success" should NOT be visible

    Scenario: Submitting wizard with valid inputs shows success banner and hides error banner
      Given I have sent a POST request to "/api/_reset" to clear all state
      And I am on the wizard view at "http://localhost:8000/"
      And I have selected "Microservice" in the element with data-testid "input-type"
      And I have selected "Node.js" in the element with data-testid "input-language"
      And I have entered "success-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      Then the element with data-testid "wizard-success" should be visible
      And the element with data-testid "wizard-error" should NOT be visible
      And the element with data-testid "wizard-success" should contain the text "success-project"

  # ==========================================================================
  @TS-009 @TS-010 @TS-011 @TS-012 @TS-013 @regression
  Rule: Language Compatibility Matrix by Project Type

    The LANGUAGES_BY_TYPE dict in app.py defines the complete compatibility
    matrix. GET /api/languages?project_type=<type> is the public API.
    POST /api/projects enforces the same matrix server-side via
    allowed_languages = LANGUAGES_BY_TYPE[req.project_type] check.
    Reference: FR-L03.

    Compatibility matrix (source of truth in app.py):
      Microservice  : Java/Spring Boot, Python/Flask, Node.js
      Batch Job     : Java, Python, Shell
      Frontend App  : React, Angular, Vue
      Library       : Java, Python, TypeScript
      Data Pipeline : Python, Scala

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"

    # ─────────────────────────────────────────────────────────────────────────
    # TS-009: Microservice project type language compatibility
    # ─────────────────────────────────────────────────────────────────────────

    @TS-009
    Scenario: GET /api/languages for Microservice returns exactly Java/Spring Boot, Python/Flask, Node.js
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java/Spring Boot"
      And the response field "languages" should contain "Python/Flask"
      And the response field "languages" should contain "Node.js"

    @TS-009
    Scenario: Microservice does not allow frontend frameworks
      When I send a GET request to "/api/languages?project_type=Microservice"
      Then the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"
      And the response field "languages" should NOT contain "TypeScript"
      And the response field "languages" should NOT contain "Scala"

    @TS-009
    Scenario: POST /api/projects accepts Java/Spring Boot for Microservice
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "micro-java", "project_type": "Microservice", "language": "Java/Spring Boot"}
        """
      Then the response status should be 201

    @TS-009
    Scenario: POST /api/projects accepts Python/Flask for Microservice
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "micro-py", "project_type": "Microservice", "language": "Python/Flask"}
        """
      Then the response status should be 201

    @TS-009
    Scenario: POST /api/projects accepts Node.js for Microservice
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "micro-node", "project_type": "Microservice", "language": "Node.js"}
        """
      Then the response status should be 201

    @TS-009
    Scenario: POST /api/projects rejects React for Microservice with HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "micro-react", "project_type": "Microservice", "language": "React"}
        """
      Then the response status should be 400
      And the response field "detail" should contain "'React'"
      And the response field "detail" should contain "not valid for project type"
      And the response field "detail" should contain "Allowed:"

    # ─────────────────────────────────────────────────────────────────────────
    # TS-010: Batch Job project type language compatibility — React excluded
    # ─────────────────────────────────────────────────────────────────────────

    @TS-010
    Scenario: GET /api/languages for Batch Job returns exactly Java, Python, Shell
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java"
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "Shell"

    @TS-010
    Scenario: Batch Job does NOT include React (AC-05)
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response field "languages" should NOT contain "React"

    @TS-010
    Scenario: Batch Job does not allow any other frontend framework
      When I send a GET request to "/api/languages?project_type=Batch%20Job"
      Then the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"
      And the response field "languages" should NOT contain "TypeScript"
      And the response field "languages" should NOT contain "Scala"

    @TS-010
    Scenario: POST /api/projects accepts Java for Batch Job
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "batch-java", "project_type": "Batch Job", "language": "Java"}
        """
      Then the response status should be 201

    @TS-010
    Scenario: POST /api/projects accepts Python for Batch Job
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "batch-py", "project_type": "Batch Job", "language": "Python"}
        """
      Then the response status should be 201

    @TS-010
    Scenario: POST /api/projects accepts Shell for Batch Job
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "batch-shell", "project_type": "Batch Job", "language": "Shell"}
        """
      Then the response status should be 201

    @TS-010
    Scenario: POST /api/projects rejects React for Batch Job with HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "batch-react", "project_type": "Batch Job", "language": "React"}
        """
      Then the response status should be 400
      And the response field "detail" should contain "'React'"
      And the response field "detail" should contain "'Batch Job'"

    # ─────────────────────────────────────────────────────────────────────────
    # TS-011: Frontend App project type language compatibility
    # ─────────────────────────────────────────────────────────────────────────

    @TS-011
    Scenario: GET /api/languages for Frontend App returns exactly React, Angular, Vue
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "React"
      And the response field "languages" should contain "Angular"
      And the response field "languages" should contain "Vue"

    @TS-011
    Scenario: Frontend App does not include backend or scripting languages
      When I send a GET request to "/api/languages?project_type=Frontend%20App"
      Then the response field "languages" should NOT contain "Java"
      And the response field "languages" should NOT contain "Python"
      And the response field "languages" should NOT contain "Node.js"
      And the response field "languages" should NOT contain "Shell"
      And the response field "languages" should NOT contain "Scala"
      And the response field "languages" should NOT contain "TypeScript"

    @TS-011
    Scenario: POST /api/projects accepts React for Frontend App
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "fe-react", "project_type": "Frontend App", "language": "React"}
        """
      Then the response status should be 201

    @TS-011
    Scenario: POST /api/projects accepts Angular for Frontend App
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "fe-angular", "project_type": "Frontend App", "language": "Angular"}
        """
      Then the response status should be 201

    @TS-011
    Scenario: POST /api/projects accepts Vue for Frontend App
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "fe-vue", "project_type": "Frontend App", "language": "Vue"}
        """
      Then the response status should be 201

    @TS-011
    Scenario: POST /api/projects rejects Java/Spring Boot for Frontend App with HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "fe-java", "project_type": "Frontend App", "language": "Java/Spring Boot"}
        """
      Then the response status should be 400
      And the response field "detail" should contain "'Java/Spring Boot'"
      And the response field "detail" should contain "'Frontend App'"

    # ─────────────────────────────────────────────────────────────────────────
    # TS-012: Library project type language compatibility
    # ─────────────────────────────────────────────────────────────────────────

    @TS-012
    Scenario: GET /api/languages for Library returns exactly Java, Python, TypeScript
      When I send a GET request to "/api/languages?project_type=Library"
      Then the response status should be 200
      And the response field "languages" should be a list of length 3
      And the response field "languages" should contain "Java"
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "TypeScript"

    @TS-012
    Scenario: Library does not include frontend frameworks or backend-only options
      When I send a GET request to "/api/languages?project_type=Library"
      Then the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Angular"
      And the response field "languages" should NOT contain "Vue"
      And the response field "languages" should NOT contain "Shell"
      And the response field "languages" should NOT contain "Scala"

    @TS-012
    Scenario: POST /api/projects accepts TypeScript for Library
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "lib-ts", "project_type": "Library", "language": "TypeScript"}
        """
      Then the response status should be 201

    @TS-012
    Scenario: POST /api/projects rejects React for Library with HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "lib-react", "project_type": "Library", "language": "React"}
        """
      Then the response status should be 400
      And the response field "detail" should contain "'React'"
      And the response field "detail" should contain "'Library'"

    # ─────────────────────────────────────────────────────────────────────────
    # TS-013: Data Pipeline project type language compatibility
    # ─────────────────────────────────────────────────────────────────────────

    @TS-013
    Scenario: GET /api/languages for Data Pipeline returns exactly Python and Scala
      When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
      Then the response status should be 200
      And the response field "languages" should be a list of length 2
      And the response field "languages" should contain "Python"
      And the response field "languages" should contain "Scala"

    @TS-013
    Scenario: Data Pipeline does not include frontend frameworks or other backend languages
      When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
      Then the response field "languages" should NOT contain "React"
      And the response field "languages" should NOT contain "Java"
      And the response field "languages" should NOT contain "Shell"
      And the response field "languages" should NOT contain "Node.js"
      And the response field "languages" should NOT contain "TypeScript"

    @TS-013
    Scenario: POST /api/projects accepts Python for Data Pipeline
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "dp-python", "project_type": "Data Pipeline", "language": "Python"}
        """
      Then the response status should be 201

    @TS-013
    Scenario: POST /api/projects accepts Scala for Data Pipeline
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "dp-scala", "project_type": "Data Pipeline", "language": "Scala"}
        """
      Then the response status should be 201

    @TS-013
    Scenario: POST /api/projects rejects Angular for Data Pipeline with HTTP 400
      Given I have sent a POST request to "/api/_reset" to clear all state
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "dp-angular", "project_type": "Data Pipeline", "language": "Angular"}
        """
      Then the response status should be 400
      And the response field "detail" should contain "'Angular'"
      And the response field "detail" should contain "'Data Pipeline'"
      And the response field "detail" should contain "Python"
      And the response field "detail" should contain "Scala"

  # ==========================================================================
  @TS-014 @regression
  Rule: Language Dropdown Remains Disabled Until Project Type Is Selected

    In INDEX_HTML (served by GET /), the <select data-testid="input-language">
    element is rendered with the HTML "disabled" attribute. The JavaScript
    function onTypeChange() is bound to the onchange event of
    <select data-testid="input-type">. When the type selection is empty (""),
    onTypeChange() re-applies langSel.disabled = true. When a valid project
    type is chosen, it fetches GET /api/languages?project_type=<type>, fills
    the options, then sets langSel.disabled = false.
    Implementation: FR-L03 in app.py INDEX_HTML / onTypeChange().

    Background:
      Given the Project Provisioning Portal is running at "http://localhost:8000"
      And I have navigated to the wizard view at "http://localhost:8000/"

    # ── Initial state ─────────────────────────────────────────────────────────

    Scenario: Language select element has the "disabled" attribute on page load before any selection
      When the page has loaded and no project type has been selected
      Then the element with data-testid "input-language" should have the attribute "disabled"

    Scenario: Language select initial option text indicates no type has been selected
      When the page has loaded and no project type has been selected
      Then the element with data-testid "input-language" should contain an option with text "— select a project type first —"

    Scenario: Project type select element is NOT disabled on page load
      When the page has loaded
      Then the element with data-testid "input-type" should NOT have the attribute "disabled"

    # ── Transition: disabled → enabled ───────────────────────────────────────

    Scenario: Selecting "Microservice" as project type enables the language dropdown
      When I select "Microservice" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should NOT have the attribute "disabled"

    Scenario: Selecting "Batch Job" as project type enables the language dropdown
      When I select "Batch Job" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should NOT have the attribute "disabled"

    Scenario: Selecting "Frontend App" as project type enables the language dropdown
      When I select "Frontend App" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should NOT have the attribute "disabled"

    Scenario: Selecting "Library" as project type enables the language dropdown
      When I select "Library" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should NOT have the attribute "disabled"

    Scenario: Selecting "Data Pipeline" as project type enables the language dropdown
      When I select "Data Pipeline" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should NOT have the attribute "disabled"
      And the element with data-testid "input-language" should contain an option with text "Python"
      And the element with data-testid "input-language" should contain an option with text "Scala"

    # ── Language options populated per type ───────────────────────────────────

    Scenario: After selecting Microservice, language dropdown contains exactly 3 Microservice-compatible options plus placeholder
      When I select "Microservice" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should contain an option with text "Java/Spring Boot"
      And the element with data-testid "input-language" should contain an option with text "Python/Flask"
      And the element with data-testid "input-language" should contain an option with text "Node.js"
      And the element with data-testid "input-language" should NOT contain an option with text "React"

    Scenario: After selecting Batch Job, language dropdown contains exactly 3 Batch Job-compatible options and NOT React
      When I select "Batch Job" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should contain an option with text "Java"
      And the element with data-testid "input-language" should contain an option with text "Python"
      And the element with data-testid "input-language" should contain an option with text "Shell"
      And the element with data-testid "input-language" should NOT contain an option with text "React"

    Scenario: After selecting Frontend App, language dropdown contains React, Angular, Vue and no backend options
      When I select "Frontend App" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should contain an option with text "React"
      And the element with data-testid "input-language" should contain an option with text "Angular"
      And the element with data-testid "input-language" should contain an option with text "Vue"
      And the element with data-testid "input-language" should NOT contain an option with text "Java"
      And the element with data-testid "input-language" should NOT contain an option with text "Python"

    # ── Transition: enabled → re-disabled after clearing type ────────────────

    Scenario: Re-selecting the blank placeholder in the project type dropdown re-disables the language dropdown
      Given I have selected "Microservice" in the element with data-testid "input-type"
      And I have waited for the onTypeChange fetch to complete
      And the element with data-testid "input-language" does NOT have the attribute "disabled"
      When I select "" in the element with data-testid "input-type"
      And I wait for the onTypeChange to execute
      Then the element with data-testid "input-language" should have the attribute "disabled"

    Scenario: Switching between project types resets and repopulates the language dropdown each time
      Given I have selected "Microservice" in the element with data-testid "input-type"
      And I have waited for the onTypeChange fetch to complete
      When I select "Frontend App" in the element with data-testid "input-type"
      And I wait for the onTypeChange fetch to complete
      Then the element with data-testid "input-language" should contain an option with text "React"
      And the element with data-testid "input-language" should NOT contain an option with text "Java/Spring Boot"
      And the element with data-testid "input-language" should NOT contain an option with text "Node.js"

  # ==========================================================================
  @TS-022 @TS-030 @regression
  Rule: Demo Mode — Immediate In-Memory Provisioning Without External Approval

    This app IS the demo mode described in the BRD. There is no ServiceNow,
    Bitbucket, or Saviynt integration. Project creation is immediate and
    synchronous: POST /api/projects returns HTTP 201 with the full record
    on the same request with no approval gate.

    Storage: the PROJECTS dict in app.py (in-memory Python dict).
    Each entry is keyed by a server-generated UUID (str(uuid.uuid4())).
    All data is lost on restart (NFR persisted storage excluded by BRD).

    POST /api/_reset wipes PROJECTS.clear() — useful between test runs.

    Covered requirements:
      TS-022 (FR-002): Approval is implicit; provisioning occurs on submission.
      TS-030 (FR-003): In-memory persistence with server-generated UUID.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state

    # ── TS-022: Immediate provisioning (no approval gate) ────────────────────

    @TS-022
    Scenario: POST /api/projects returns HTTP 201 immediately with full record — no async approval gate
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "immediate-project",
          "project_type": "Microservice",
          "language": "Node.js"
        }
        """
      Then the response status should be 201
      And the response Content-Type should contain "application/json"
      And the response field "project_name" should equal "immediate-project"
      And the response field "project_type" should equal "Microservice"
      And the response field "language" should equal "Node.js"
      And the response field "id" should be a non-empty string
      And the response does NOT contain a "status" field with value "pending"
      And the response does NOT contain an "approval_required" field

    @TS-022
    Scenario: Provisioned project is immediately visible in GET /api/projects without any approval step
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "auto-approved",
          "project_type": "Library",
          "language": "Python"
        }
        """
      Then the response status should be 201
      When I send a GET request to "/api/projects"
      Then the response status should be 200
      And the response field "projects" should contain an entry with "project_name" equal to "auto-approved"

    @TS-022
    Scenario: No external HTTP calls are made when creating a project (in-memory only, no ServiceNow)
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "no-external-calls",
          "project_type": "Data Pipeline",
          "language": "Scala"
        }
        """
      Then the response status should be 201
      And the project is persisted locally with no external service dependency

    @TS-022
    Scenario: Multiple projects can be created in rapid succession without queuing or waiting for approval
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "rapid-project-1", "project_type": "Microservice", "language": "Java/Spring Boot"}
        """
      Then the response status should be 201
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "rapid-project-2", "project_type": "Batch Job", "language": "Python"}
        """
      Then the response status should be 201
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "rapid-project-3", "project_type": "Frontend App", "language": "React"}
        """
      Then the response status should be 201
      When I send a GET request to "/api/projects"
      Then the response field "projects" should have a length of 3

    # ── TS-030: In-memory persistence details ────────────────────────────────

    @TS-030
    Scenario: Created project ID is a server-generated UUID, not a sequential integer
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "uuid-demo-project",
          "project_type": "Microservice",
          "language": "Python/Flask"
        }
        """
      Then the response status should be 201
      And the response field "id" should match the UUID v4 pattern
        "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

    @TS-030
    Scenario: Each project receives a unique UUID
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "uuid-a", "project_type": "Library", "language": "Java"}
        """
      Then the response status should be 201
      And I store the response field "id" as "id_a"
      When I send a POST request to "/api/projects" with body:
        """
        {"project_name": "uuid-b", "project_type": "Library", "language": "Python"}
        """
      Then the response status should be 201
      And I store the response field "id" as "id_b"
      Then "id_a" should NOT equal "id_b"

    @TS-030
    Scenario: Persisted project record contains all wizard input fields and metadata
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "full-record-check",
          "project_type": "Frontend App",
          "language": "Angular"
        }
        """
      Then the response status should be 201
      And the response field "id" should be a non-empty string
      And the response field "project_name" should equal "full-record-check"
      And the response field "project_type" should equal "Frontend App"
      And the response field "language" should equal "Angular"
      And the response field "members" should be an empty array
      And the response field "created_at" should be a non-empty ISO 8601 timestamp ending in "Z"

    @TS-030
    Scenario: Persisted project is retrievable by its UUID via GET /api/projects/{id}
      Given I have successfully created a project named "retrievable-demo" with type "Batch Job" and language "Shell"
      And I have stored the created project ID as "project_id"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "project_name" should equal "retrievable-demo"
      And the response field "id" should equal "{project_id}"

    @TS-030
    Scenario: POST /api/_reset wipes all in-memory projects
      Given I have successfully created a project named "will-be-reset" with type "Library" and language "TypeScript"
      When I send a POST request to "/api/_reset"
      Then the response status should be 200
      And the response field "status" should equal "ok"
      When I send a GET request to "/api/projects"
      Then the response field "projects" should be an empty array

    @TS-030
    Scenario: GET /api/projects returns projects sorted by created_at in ascending order
      Given I have successfully created a project named "first-sorted" with type "Microservice" and language "Node.js"
      And I have successfully created a project named "second-sorted" with type "Library" and language "Python"
      When I send a GET request to "/api/projects"
      Then the response status should be 200
      And the first entry in "projects" should have "project_name" equal to "first-sorted"
      And the second entry in "projects" should have "project_name" equal to "second-sorted"

    @TS-030
    Scenario: GET /api/projects returns empty projects array when no projects exist
      When I send a GET request to "/api/projects"
      Then the response status should be 200
      And the response field "projects" should be an empty array

    @TS-030
    Scenario: GET /api/projects/{id} with non-existent UUID returns HTTP 404 with detail "Project not found"
      When I send a GET request to "/api/projects/ffffffff-ffff-4fff-bfff-ffffffffffff"
      Then the response status should be 404
      And the response field "detail" should equal "Project not found"

  # ==========================================================================
  @TS-033 @TS-036 @regression
  Rule: Role-Based Access Assignment and In-Memory Access Grant Recording

    VALID_ROLES = ("Admin", "Developer", "Read-Only") is defined in app.py.
    POST /api/projects/{project_id}/members stores {user_email, role} tuples
    in project["members"] (in-memory list). The role is validated by the
    add_member() function (FR-L08 — PLANTED BUG #2: validation is commented out).

    TS-033: Verifies that Admin, Developer, and Read-Only are the only accepted
            roles and that they are stored exactly as specified.
    TS-036: Verifies in-memory storage of access grants as {user_email, role}
            tuples, readable via GET /api/projects/{id}.

    Background:
      Given the Project Provisioning Portal API is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state
      And I have successfully created a project named "role-test-project" with type "Microservice" and language "Java/Spring Boot"
      And I have stored the created project ID as "project_id"

    # ── TS-033: Role values accepted and stored exactly as specified ──────────

    @TS-033
    Scenario: Add member with "Admin" role — role stored exactly as "Admin"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "admin-user@example.com",
          "role": "Admin"
        }
        """
      Then the response status should be 200
      And the response field "member.role" should equal "Admin"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response field "members[0].role" should equal "Admin"

    @TS-033
    Scenario: Add member with "Developer" role — role stored exactly as "Developer"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "dev-user@example.com",
          "role": "Developer"
        }
        """
      Then the response status should be 200
      And the response field "member.role" should equal "Developer"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response field "members[0].role" should equal "Developer"

    @TS-033
    Scenario: Add member with "Read-Only" role — role stored exactly as "Read-Only"
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "readonly-user@example.com",
          "role": "Read-Only"
        }
        """
      Then the response status should be 200
      And the response field "member.role" should equal "Read-Only"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response field "members[0].role" should equal "Read-Only"

    @TS-033
    Scenario: [BUG-002] Role "GodMode" is rejected with HTTP 400 — only three roles allowed
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "godmode@example.com",
          "role": "GodMode"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"
      And the response field "detail" should contain "'GodMode'"
      And the response field "detail" should contain "Admin"
      And the response field "detail" should contain "Developer"
      And the response field "detail" should contain "Read-Only"

    @TS-033
    Scenario: [BUG-002] Role "Viewer" is rejected — not in the three allowed roles
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "viewer@example.com",
          "role": "Viewer"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    @TS-033
    Scenario: [BUG-002] Role "Owner" is rejected — not in the three allowed roles
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "owner@example.com",
          "role": "Owner"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    @TS-033
    Scenario: [BUG-002] Role "read-only" (lowercase) is rejected — role matching is case-sensitive
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "lowercase@example.com",
          "role": "read-only"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    @TS-033
    Scenario: [BUG-002] Role "ADMIN" (uppercase) is rejected — role matching is case-sensitive
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "caps@example.com",
          "role": "ADMIN"
        }
        """
      Then the response status should be 400
      And the response field "detail" should contain "Invalid role"

    @TS-033
    Scenario: All three valid roles can be assigned to different users on the same project
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "admin@example.com", "role": "Admin"}
        """
      Then the response status should be 200
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "dev@example.com", "role": "Developer"}
        """
      Then the response status should be 200
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {"user_email": "ro@example.com", "role": "Read-Only"}
        """
      Then the response status should be 200
      When I send a GET request to "/api/projects/{project_id}"
      Then the response field "members" should have a length of 3

    # ── TS-036: In-memory access grants stored as {user_email, role} tuples ──

    @TS-036
    Scenario: Member record contains exactly "user_email" and "role" fields
      Given I have added member "tuple-user@example.com" with role "Developer" to project "{project_id}"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the first member in the response should have field "user_email" equal to "tuple-user@example.com"
      And the first member in the response should have field "role" equal to "Developer"

    @TS-036
    Scenario: Access grant tuple is persisted in the project's members array
      When I send a POST request to "/api/projects/{project_id}/members" with body:
        """
        {
          "user_email": "persisted@example.com",
          "role": "Admin"
        }
        """
      Then the response status should be 200
      When I send a GET request to "/api/projects/{project_id}"
      Then the response field "members" should contain an entry where "user_email" equals "persisted@example.com"
      And the response field "members" should contain an entry where "role" equals "Admin"

    @TS-036
    Scenario: Multiple access grant tuples are all stored in the members array
      Given I have added member "user-one@example.com" with role "Admin" to project "{project_id}"
      And I have added member "user-two@example.com" with role "Developer" to project "{project_id}"
      And I have added member "user-three@example.com" with role "Read-Only" to project "{project_id}"
      When I send a GET request to "/api/projects/{project_id}"
      Then the response status should be 200
      And the response field "members" should have a length of 3
      And the response field "members" should contain an entry with "user_email" equal to "user-one@example.com" and "role" equal to "Admin"
      And the response field "members" should contain an entry with "user_email" equal to "user-two@example.com" and "role" equal to "Developer"
      And the response field "members" should contain an entry with "user_email" equal to "user-three@example.com" and "role" equal to "Read-Only"

    @TS-036
    Scenario: Access grant tuples appear in the UI member list with correct email and role pill
      Given I have added member "ui-member@example.com" with role "Admin" to project "{project_id}"
      When I navigate to the members view for project "{project_id}" at "http://localhost:8000/"
      Then the element with data-testid "member-row" should be visible
      And the element with data-testid "member-email" should contain the text "ui-member@example.com"
      And the element with data-testid "member-role" should contain the text "Admin"

    @TS-036
    Scenario: Access grants are held in memory only — POST /api/_reset clears them
      Given I have added member "temp-user@example.com" with role "Developer" to project "{project_id}"
      When I send a POST request to "/api/_reset"
      Then the response status should be 200
      When I send a GET request to "/api/projects"
      Then the response field "projects" should be an empty array

  # ==========================================================================
  @TS-045 @TS-048 @regression
  Rule: Success Notification After Project Creation

    NOTE: The BRD Out-of-Scope section explicitly excludes email notifications.
    The portal replaces email with inline success/error banners rendered by the
    SPA. The wizard success banner element has data-testid="wizard-success" and
    is populated by setBanner("wizard-success", "success", ...) in submitWizard()
    in app.py's embedded JavaScript. The banner text includes the project name
    and the server-generated project ID (TS-048: summary of provisioned resources).

    Banner message format (from submitWizard()):
      'Project "${data.project_name}" created successfully. ID: ${data.id}'

    Error banner: data-testid="wizard-error" — shown on non-2xx responses.
    Both banners start hidden (style="display:none").
    Implementation: INDEX_HTML in app.py, setBanner() helper.

    Background:
      Given the Project Provisioning Portal is running at "http://localhost:8000"
      And I have sent a POST request to "/api/_reset" to clear all state

    # ── TS-045: Success notification is displayed after provisioning ──────────

    @TS-045
    Scenario: Wizard success banner becomes visible after a successful project creation via the UI
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Microservice" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Node.js" in the element with data-testid "input-language"
      And I have entered "notify-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the element with data-testid "wizard-error" should NOT be visible

    @TS-045
    Scenario: Wizard error banner is shown and success banner is hidden when creation fails
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Microservice" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Node.js" in the element with data-testid "input-language"
      And the element with data-testid "input-name" is empty
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-error" should be visible
      And the element with data-testid "wizard-success" should NOT be visible

    @TS-045
    Scenario: Success banner has CSS class "success" applied by setBanner()
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Library" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "TypeScript" in the element with data-testid "input-language"
      And I have entered "class-check-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should have CSS class "success"
      And the element with data-testid "wizard-success" should NOT have CSS class "error"

    @TS-045
    Scenario: Error banner has CSS class "error" applied by setBanner()
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Data Pipeline" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Python" in the element with data-testid "input-language"
      And I have entered "invalid name!" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-error" should have CSS class "error"
      And the element with data-testid "wizard-success" should NOT be visible

    @TS-045
    Scenario: Success banner is hidden on page load before any submission
      Given I am on the wizard view at "http://localhost:8000/"
      Then the element with data-testid "wizard-success" should have inline style "display:none"

    @TS-045
    Scenario: Error banner is hidden on page load before any submission
      Given I am on the wizard view at "http://localhost:8000/"
      Then the element with data-testid "wizard-error" should have inline style "display:none"

    @TS-045
    Scenario: Submitting a second project after a success clears and re-uses the success banner
      Given I am on the wizard view at "http://localhost:8000/"
      And I have created a project successfully via the wizard with name "first-success"
      When I enter "second-success" in the element with data-testid "input-name"
      And I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the element with data-testid "wizard-success" should contain the text "second-success"

    # ── TS-048: Success message includes summary of provisioned resources ─────

    @TS-048
    Scenario: Success banner text contains the project name
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Frontend App" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "React" in the element with data-testid "input-language"
      And I have entered "summary-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the element with data-testid "wizard-success" should contain the text "summary-project"

    @TS-048
    Scenario: Success banner text contains the server-generated project ID
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Batch Job" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Java" in the element with data-testid "input-language"
      And I have entered "id-summary-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the element with data-testid "wizard-success" should contain the text "ID:"
      And the text content of data-testid "wizard-success" should match the UUID pattern
        "[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}"

    @TS-048
    Scenario: Success banner text follows the format 'Project "<name>" created successfully. ID: <uuid>'
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Microservice" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Python/Flask" in the element with data-testid "input-language"
      And I have entered "format-check-project" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the text content of data-testid "wizard-success" should match the pattern
        'Project "format-check-project" created successfully\. ID: [0-9a-f\-]+'

    @TS-048
    Scenario: After successful creation, the project name input field is cleared
      Given I am on the wizard view at "http://localhost:8000/"
      And I have selected "Library" in the element with data-testid "input-type"
      And I have waited for the language dropdown to be enabled
      And I have selected "Java" in the element with data-testid "input-language"
      And I have entered "cleared-after-submit" in the element with data-testid "input-name"
      When I click the element with data-testid "btn-submit"
      And I wait for the fetch to complete
      Then the element with data-testid "wizard-success" should be visible
      And the value of the element with data-testid "input-name" should be empty

    # ── API-level success response (backing the notification) ────────────────

    @TS-048
    Scenario: POST /api/projects response body contains project_name and id needed for success message
      When I send a POST request to "/api/projects" with body:
        """
        {
          "project_name": "api-response-project",
          "project_type": "Data Pipeline",
          "language": "Scala"
        }
        """
      Then the response status should be 201
      And the response field "project_name" should equal "api-response-project"
      And the response field "id" should be a non-empty string matching the UUID v4 pattern
      And the response field "project_type" should equal "Data Pipeline"
      And the response field "language" should equal "Scala"
      And the response field "members" should be an empty array
      And the response field "created_at" should be a non-empty string