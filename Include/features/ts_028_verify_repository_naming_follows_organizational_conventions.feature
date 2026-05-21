@TS-028 @regression
Feature: Project Naming Follows Organizational Convention (ASCII Letters, Digits, Hyphens Only)

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: All-lowercase name is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "myservice", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  Scenario: Mixed-case name is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "MyService", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  Scenario: Name with digits is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "service123", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  Scenario: Name with hyphens is accepted
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "my-service-v2", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  # ── Edge cases ────────────────────────────────────────────

  Scenario: Name consisting of a single hyphen is accepted (regex ^[A-Za-z0-9-]+$ allows it)
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "-", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  Scenario: Duplicate project name returns 409 [DOCUMENTS PLANTED BUG #1]
    # BRD FR-L06 + AC-03: second POST with same name must return 409.
    # Bug #1 causes server to return 201 instead.
    Given I send a POST request to "/api/projects" with body:
      """
      {"project_name": "existing-name", "project_type": "Batch Job", "language": "Java"}
      """
    And the response status should be 201
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "existing-name", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 409
    And the response JSON field "detail" should equal "Project name already exists"

  # ── Negative ──────────────────────────────────────────────

  Scenario: Name with underscore is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "my_service", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Name with space is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "my service", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Name with @ sign is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "service@corp", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Name with dot is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "service.v2", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"

  Scenario: Name with slash is rejected with 400
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "service/v2", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 400
    And the response JSON field "detail" should equal "Project name must contain only ASCII letters, digits, and hyphens"


# ════════════════════════════════════════════════════════════
# TS-030  Demo Mode Replaces Bitbucket with In-Memory Persistence
# Impl:   PROJECTS: Dict[str, dict] — global in-memory store in app.py
#         create_project() persists: id (uuid4), project_name, project_type,
#           language, members=[], created_at (ISO 8601 UTC)
#         GET /api/projects  → {"projects": [...]} ordered by created_at
#         GET /api/projects/{id}  → project record or 404
# ════════════════════════════════════════════════════════════