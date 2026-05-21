@TS-009 @regression
Feature: Microservice Project Type Language Compatibility

  Background:
    Given the portal API is running at "http://localhost:8000"
    And all projects have been reset via "POST /api/_reset"

  # ── Happy path ────────────────────────────────────────────

  Scenario: GET /api/languages for Microservice returns exactly 3 languages [DOCUMENTS LANGUAGE BUG]
    # BRD FR-L03 table requires: Java/Spring Boot, Python/Flask, Node.js
    # Actual code omits Node.js — this test will FAIL until the bug is fixed.
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the response JSON field "languages" is an array with exactly 3 items
    And the "languages" array should contain "Java/Spring Boot"
    And the "languages" array should contain "Python/Flask"
    And the "languages" array should contain "Node.js"

  Scenario: GET /api/languages for Microservice does not return frontend frameworks
    When I send a GET request to "/api/languages?project_type=Microservice"
    Then the response status should be 200
    And the "languages" array should NOT contain "React"
    And the "languages" array should NOT contain "Angular"
    And the "languages" array should NOT contain "Vue"
    And the "languages" array should NOT contain "Scala"

  Scenario: POST /api/projects accepts Java/Spring Boot for Microservice
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "svc-java", "project_type": "Microservice", "language": "Java/Spring Boot"}
      """
    Then the response status should be 201
    And the response JSON field "project_type" should equal "Microservice"
    And the response JSON field "language" should equal "Java/Spring Boot"

  Scenario: POST /api/projects accepts Python/Flask for Microservice
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "svc-python", "project_type": "Microservice", "language": "Python/Flask"}
      """
    Then the response status should be 201

  Scenario: POST /api/projects accepts Node.js for Microservice [DOCUMENTS LANGUAGE BUG]
    # Node.js is absent from the in-memory matrix — this POST returns 400 until the bug is fixed.
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "svc-node", "project_type": "Microservice", "language": "Node.js"}
      """
    Then the response status should be 201

  # ── Negative ──────────────────────────────────────────────

  Scenario: POST /api/projects rejects React for Microservice
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "svc-react-invalid", "project_type": "Microservice", "language": "React"}
      """
    Then the response status should be 400

  Scenario: POST /api/projects rejects Scala for Microservice
    When I send a POST request to "/api/projects" with body:
      """
      {"project_name": "svc-scala-invalid", "project_type": "Microservice", "language": "Scala"}
      """
    Then the response status should be 400


# ════════════════════════════════════════════════════════════
# TS-010  Batch Job Project Type Language Compatibility
# Impl:   LANGUAGES_BY_TYPE["Batch Job"] = ["Java","Python","Shell"]
#         FR-L03 explicitly forbids React for Batch Job
# ════════════════════════════════════════════════════════════