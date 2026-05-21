@TS-011 @regression
Feature: Frontend App Project Type Language Compatibility

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/languages for Frontend App returns exactly 3 frontend frameworks
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items
    And the "languages" array should contain "React"
    And the "languages" array should contain "Angular"
    And the "languages" array should contain "Vue"

  Scenario: GET /api/languages for Frontend App excludes all backend languages
    When I send a GET request to "/api/languages?project_type=Frontend%20App"
    Then the response status should be 200
    And the "languages" array should NOT contain "Java"
    And the "languages" array should NOT contain "Python"
    And the "languages" array should NOT contain "Shell"
    And the "languages" array should NOT contain "Java/Spring Boot"
    And the "languages" array should NOT contain "Scala"

  Scenario: POST /api/projects accepts React for Frontend App
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "fe-react", "project_type": "Frontend App", "language": "React"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Angular for Frontend App
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "fe-angular", "project_type": "Frontend App", "language": "Angular"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Vue for Frontend App
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "fe-vue", "project_type": "Frontend App", "language": "Vue"}
      """
    Then the response status should be 201

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects rejects Python for Frontend App
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "fe-python-invalid", "project_type": "Frontend App", "language": "Python"}
      """
    Then the response status should be 400

  Scenario: POST /api/projects rejects Java/Spring Boot for Frontend App
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "fe-java-invalid", "project_type": "Frontend App", "language": "Java/Spring Boot"}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-012  Library Project Type Language Compatibility
# Impl:   LANGUAGES_BY_TYPE["Library"] = ["Java","Python","TypeScript"]
# ════════════════════════════════════════════════════════════