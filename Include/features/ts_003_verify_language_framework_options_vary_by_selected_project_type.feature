@TS-003 @regression
Feature: Language Options Are Context-Aware by Selected Project Type

  Background:
    Given the portal API is running at "http://localhost:8000"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Different project types return distinct language arrays
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And I store the response JSON field "languages" as "microservice_langs"
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And I store the response JSON field "languages" as "frontend_langs"
    Then "microservice_langs" should not equal "frontend_langs"

  Scenario: Response for each valid type contains a non-empty "languages" array
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the response JSON field "languages" is an array with at least 1 item

  # ── Edge cases ────────────────────────────────────────────

  Scenario: POST /api/projects rejects a language incompatible with Batch Job
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "batch-react-invalid",
        "project_type": "Batch Job",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "React"
    And the response JSON field "detail" contains "Batch Job"

  Scenario: POST /api/projects rejects a language incompatible with Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "pipeline-angular-invalid",
        "project_type": "Data Pipeline",
        "language": "Angular"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "Angular"
    And the response JSON field "detail" contains "Data Pipeline"

  # ── Negative ──────────────────────────────────────────────

  Scenario: GET /api/languages with unknown project_type returns 400
    When I send a GET request to "/api/languages?project_type=UnknownType"
    Then the response status should be 400
    And the response JSON field "detail" contains "Unknown project type"
    And the response JSON field "detail" contains "UnknownType"

  Scenario: GET /api/languages without project_type query param returns 422
    When I send a GET request to "/api/languages"
    Then the response status should be 422

  Scenario: GET /api/languages with empty project_type string returns 400
    When I send a GET request to "/api/languages?project_type="
    Then the response status should be 400
    And the response JSON field "detail" contains "Unknown project type"


# ════════════════════════════════════════════════════════════
# TS-004  Project Name Collection and Validation
# Impl:   POST /api/projects
#         Validation: name.strip() non-empty → 400 "Project name is required"
#                     re.match(r"^[A-Za-z0-9-]+$", name) → 400 "Project name must
#                       contain only ASCII letters, digits, and hyphens"
# ════════════════════════════════════════════════════════════