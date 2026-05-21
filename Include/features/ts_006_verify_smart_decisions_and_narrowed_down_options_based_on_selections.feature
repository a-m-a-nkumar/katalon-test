@TS-006 @regression
Feature: Context-Aware Language Filtering Based on Project Type Selection

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: Selecting Microservice type filters languages to Java/Spring Boot and Python/Flask
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the "languages" array should contain "Java/Spring Boot"
    And the "languages" array should contain "Python/Flask"
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"
    And the "languages" array should NOT contain "Scala"

  Scenario: Selecting Data Pipeline filters to Python and Scala only
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the "languages" array should contain "Python"
    And the "languages" array should contain "Scala"
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Java/Spring Boot"
    And the "languages" array should NOT contain "Shell"

  Scenario: POST /api/projects accepts a language in the type's allowlist (Frontend App + React)
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "frontend-react-valid",
        "project_type": "Frontend App",
        "language": "React"
      }
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Frontend App"
    And the response JSON field "language" should equal "React"

  # ── Edge cases ────────────────────────────────────────────

  Scenario: POST /api/projects rejects a language that is valid for another type but not the selected one
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "frontend-with-java",
        "project_type": "Frontend App",
        "language": "Java/Spring Boot"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "Java/Spring Boot"
    And the response JSON field "detail" contains "Frontend App"

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects with unknown project_type returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "unknown-type-project",
        "project_type": "FullStackApp",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "Unknown project type"
    And the response JSON field "detail" contains "FullStackApp"

  Scenario: POST /api/projects with "Full-Stack App" (not in code) returns 400
    When I send a POST request to "/api/projects" with body:
      """
      {
        "project_name": "full-stack-attempt",
        "project_type": "Full-Stack App",
        "language": "React"
      }
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "Full-Stack App"


# ════════════════════════════════════════════════════════════
# TS-007  Input Validation Before Submission
# Impl:   POST /api/projects  (name, project_type, language)
#         POST /api/projects/{id}/members  (email, role)
#         All validation is server-side (FastAPI/Pydantic + manual checks)
# ════════════════════════════════════════════════════════════