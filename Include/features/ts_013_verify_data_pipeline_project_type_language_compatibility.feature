@TS-013 @regression
Feature: Data Pipeline Project Type Language Compatibility

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/languages for Data Pipeline returns exactly 2 languages
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 2 items
    And the "languages" array should contain "Python"
    And the "languages" array should contain "Scala"

  Scenario: GET /api/languages for Data Pipeline excludes all other languages
    When I send a GET request to "/api/languages?project_type=Data%20Pipeline"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Java"
    And the "languages" array should NOT contain "Java/Spring Boot"
    And the "languages" array should NOT contain "Shell"
    And the "languages" array should NOT contain "TypeScript"
    And the "languages" array should NOT contain "Angular"

  Scenario: POST /api/projects accepts Python for Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "pipeline-python", "project_type": "Data Pipeline", "language": "Python"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Scala for Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "pipeline-scala", "project_type": "Data Pipeline", "language": "Scala"}
      """
    Then the response status should be 201

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects rejects Java for Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "pipeline-java-invalid", "project_type": "Data Pipeline", "language": "Java"}
      """
    Then the response status should be 400

  Scenario: POST /api/projects rejects Shell for Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "pipeline-shell-invalid", "project_type": "Data Pipeline", "language": "Shell"}
      """
    Then the response status should be 400

  Scenario: POST /api/projects rejects React for Data Pipeline
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "pipeline-react-invalid", "project_type": "Data Pipeline", "language": "React"}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-014  Language Dropdown Remains Disabled Until Project Type Selected
# Impl:   <select id="input-language" data-testid="input-language" disabled>
#         onTypeChange() in JS: if !type → langSel.disabled = true
#                               else → fetch /api/languages, langSel.disabled = false
# ════════════════════════════════════════════════════════════