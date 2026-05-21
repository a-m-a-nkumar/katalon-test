@TS-010 @regression
Feature: Batch Job Project Type Language Compatibility (Excludes React)

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/languages for Batch Job returns exactly 3 languages
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items
    And the "languages" array should contain "Java"
    And the "languages" array should contain "Python"
    And the "languages" array should contain "Shell"

  Scenario: GET /api/languages for Batch Job excludes all frontend frameworks (AC-05)
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"

  Scenario: GET /api/languages for Batch Job excludes TypeScript and Scala
    When I send a GET request to "/api/languages?project_type=Batch%20Job"
    Then the response status should be 200
    And the "languages" array should NOT contain "TypeScript"
    And the "languages" array should NOT contain "Scala"

  Scenario: POST /api/projects accepts Java for Batch Job
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "batch-java", "project_type": "Batch Job", "language": "Java"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Python for Batch Job
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "batch-python", "project_type": "Batch Job", "language": "Python"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Shell for Batch Job
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "batch-shell", "project_type": "Batch Job", "language": "Shell"}
      """
    Then the response status should be 201

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects rejects React for Batch Job (AC-05 variant)
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "batch-react-invalid", "project_type": "Batch Job", "language": "React"}
      """
    Then the response status should be 400
    And the response JSON field "detail" contains "React"
    And the response JSON field "detail" contains "Batch Job"

  Scenario: POST /api/projects rejects TypeScript for Batch Job
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "batch-ts-invalid", "project_type": "Batch Job", "language": "TypeScript"}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-011  Frontend App Project Type Language Compatibility
# Impl:   LANGUAGES_BY_TYPE["Frontend App"] = ["React","Angular","Vue"]
# ════════════════════════════════════════════════════════════