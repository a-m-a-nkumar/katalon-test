@TS-003 @regression @intent-classification
Feature: Customer Intent Classification

  Background:
    Given the Express app mounts API routes under "/api/v1"
    And POST "/api/v1/classify-intent" is handled by IntentController.classify
    And GET "/api/v1/classify-intent/supported" is handled by IntentController.getSupportedIntents
    And IntentClassificationService supports the intent labels "billing_inquiry", "technical_support", "account_management", "product_inquiry", "complaint", "refund_request", "cancellation_request", and "general_inquiry"

  @happy-path
  Scenario Outline: Classify each implemented intent label from the keyword map
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":"<text>"}
      """
    Then the response status should be 200
    And the response field "intent" should equal "<intent>"
    And the response field "confidence" should equal 0.98
    And the response field "secondary_intents" should be present as an array
    And the response field "requires_escalation" should equal <requires_escalation>

    Examples:
      | text                                  | intent                | requires_escalation |
      | billing invoice charge payment balance | billing_inquiry      | false               |
      | error bug crash broken troubleshoot    | technical_support    | false               |
      | account password login username settings | account_management  | false               |
      | product feature plan pricing upgrade   | product_inquiry      | false               |
      | complaint unacceptable awful rude manager | complaint          | true                |
      | refund reimburse credit dispute chargeback | refund_request    | true                |
      | cancel unsubscribe terminate quit leave | cancellation_request | true               |
      | sunshine mountains rivers forests valleys | general_inquiry    | false               |

  @happy-path
  Scenario: Return the supported intent catalog from GET /api/v1/classify-intent/supported
    When I send a GET request to "/api/v1/classify-intent/supported"
    Then the response status should be 200
    And the response field "total" should equal 8
    And the response field "intents" should equal ["billing_inquiry", "technical_support", "account_management", "product_inquiry", "complaint", "refund_request", "cancellation_request", "general_inquiry"]

  @edge-case
  Scenario: Return secondary intents when multiple categories score above zero
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":"refund reimburse credit cancel"}
      """
    Then the response status should be 200
    And the response field "intent" should equal "refund_request"
    And the response field "confidence" should equal 0.98
    And the response field "secondary_intents" should be an array of length 1
    And the first "secondary_intents" entry should have "intent" equal to "cancellation_request"
    And the first "secondary_intents" entry should have "confidence" equal to 0.85
    And the response field "requires_escalation" should equal true

  @edge-case
  Scenario: Reject low-confidence ties as ambiguous_intent
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":"billing login alpha beta gamma delta epsilon zeta eta theta"}
      """
    Then the response status should be 422
    And the response field "code" should equal "ambiguous_intent"
    And the response field "message" should equal "Could not determine intent with sufficient confidence. Please provide more context."
    And the response field "status" should equal 422

  @edge-case
  Scenario: Accept the maximum valid payload length of 5000 characters
    Given I build a request body whose "text" field contains exactly 5000 characters made from repeated "billing " tokens
    When I send the request to "/api/v1/classify-intent"
    Then the response status should be 200
    And the response field "intent" should equal "billing_inquiry"
    And the response field "requires_escalation" should equal false

  @edge-case
  Scenario: Handle concurrent classification requests with independent results
    When I submit the following requests to "/api/v1/classify-intent" concurrently:
      | text                                  | expected_intent        |
      | billing invoice charge payment        | billing_inquiry        |
      | refund reimburse credit dispute       | refund_request         |
      | account password login username       | account_management     |
    Then every response status should be 200
    And each response field "intent" should match its "expected_intent"

  @error-path
  Scenario: Reject an empty text string before intent scoring runs
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":""}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject a whitespace-only text string before intent scoring runs
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":"   "}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject a missing text field as empty_input
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject an unsupported language code before classification
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":"billing invoice charge", "language":"sv"}
      """
    Then the response status should be 422
    And the response field "code" should equal "unsupported_language"
    And the response field "message" should equal "Language \"sv\" is not supported for intent classification."
    And the response field "status" should equal 422

  @error-path
  Scenario: Return the controller fallback when the body exceeds 5000 characters
    Given I build a request body whose "text" field contains exactly 5001 characters made from repeated "billing " tokens
    When I send the request to "/api/v1/classify-intent"
    Then the response status should be 500
    And the response field "code" should equal "classification_failed"
    And the response field "error" should equal "classification_failed"
    And the response field "message" should equal "An unexpected error occurred during intent classification."
    And the response field "status" should equal 500

  @error-path
  Scenario: Return the controller fallback when text is not a string
    When I send a POST request to "/api/v1/classify-intent" with body:
      """
      {"text":123}
      """
    Then the response status should be 500
    And the response field "code" should equal "classification_failed"
    And the response field "error" should equal "classification_failed"
    And the response field "message" should equal "An unexpected error occurred during intent classification."
    And the response field "status" should equal 500