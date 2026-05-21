@TS-012 @regression
Feature: Library Project Type Language Compatibility

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/languages for Library returns exactly 3 languages
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items
    And the "languages" array should contain "Java"
    And the "languages" array should contain "Python"
    And the "languages" array should contain "TypeScript"

  Scenario: GET /api/languages for Library excludes frontend frameworks and Shell
    When I send a GET request to "/api/languages?project_type=Library"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"
    And the "languages" array should NOT contain "Shell"
    And the "languages" array should NOT contain "Scala"

  Scenario: POST /api/projects accepts TypeScript for Library
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "lib-typescript", "project_type": "Library", "language": "TypeScript"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Java for Library
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "lib-java", "project_type": "Library", "language": "Java"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Python for Library
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "lib-python", "project_type": "Library", "language": "Python"}
      """
    Then the response status should be 201

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects rejects Shell for Library
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "lib-shell-invalid", "project_type": "Library", "language": "Shell"}
      """
    Then the response status should be 400

  Scenario: POST /api/projects rejects React for Library
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "lib-react-invalid", "project_type": "Library", "language": "React"}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-013  Data Pipeline Project Type Language Compatibility
# Impl:   LANGUAGES_BY_TYPE["Data Pipeline"] = ["Python","Scala"]
# ════════════════════════════════════════════════════════════