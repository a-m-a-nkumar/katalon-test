@TS-001 @regression @language-support
Feature: Language Detection and Support

  Background:
    Given the Express app mounts API routes under "/api/v1"
    And POST "/api/v1/detect-language" is handled by LanguageController.detect
    And GET "/api/v1/detect-language/supported" is handled by LanguageController.getSupportedLanguages
    And LanguageDetectionService supports "en", "es", "fr", "de", "it", "pt", "nl", "ru", "zh", "ja", "ko", and "ar"

  @happy-path
  Scenario Outline: Detect each supported language from the implemented heuristic
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"<text>"}
      """
    Then the response status should be 200
    And the response field "detected_language" should equal "<language>"
    And the response field "language_name" should equal "<language_name>"
    And the response field "supported" should equal true
    And the response field "confidence" should be greater than <min_confidence>

    Examples:
      | text                                   | language | language_name | min_confidence |
      | I need help with my order              | en       | English       | 0.55           |
      | hola necesito ayuda con mi pedido      | es       | Spanish       | 0.60           |
      | bonjour merci aide avec mon compte     | fr       | French        | 0.60           |
      | hallo ich brauche hilfe mit mein konto | de       | German        | 0.60           |
      | ciao ho aiuto con il mio ordine        | it       | Italian       | 0.60           |
      | preciso ajuda com meu pedido           | pt       | Portuguese    | 0.60           |
      | hallo ik heb hulp nodig met mijn bestelling | nl   | Dutch         | 0.60           |
      | Мне нужна помощь с заказом             | ru       | Russian       | 0.70           |
      | 我需要帮助处理订单                      | zh       | Chinese       | 0.70           |
      | こんにちは たすけてください          | ja       | Japanese      | 0.70           |
      | 주문에 대한 도움이 필요합니다          | ko       | Korean        | 0.70           |
      | أحتاج مساعدة في طلبي                   | ar       | Arabic        | 0.70           |

  @happy-path
  Scenario: Return the supported language catalog from GET /api/v1/detect-language/supported
    When I send a GET request to "/api/v1/detect-language/supported"
    Then the response status should be 200
    And the response field "total" should equal 12
    And the response field "languages" should be an array of length 12
    And the response "languages" array should contain entries for "en", "es", "fr", "de", "it", "pt", "nl", "ru", "zh", "ja", "ko", and "ar"

  @edge-case
  Scenario: Accept the minimum valid payload length and fall back to English
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"hi"}
      """
    Then the response status should be 200
    And the response field "detected_language" should equal "en"
    And the response field "confidence" should equal 0.55
    And the response field "supported" should equal true

  @edge-case
  Scenario: Accept the maximum valid payload length of 5000 characters
    Given I build a request body whose "text" field contains exactly 5000 characters made from repeated "help " tokens
    When I send the request to "/api/v1/detect-language"
    Then the response status should be 200
    And the response field "detected_language" should equal "en"
    And the response field "supported" should equal true

  @edge-case
  Scenario: Default to English when Latin-script text contains no configured keyword hints
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"lorem ipsum dolor sit amet consectetur"}
      """
    Then the response status should be 200
    And the response field "detected_language" should equal "en"
    And the response field "confidence" should equal 0.55

  @edge-case
  Scenario Outline: Resolve mixed-language Latin text to the strongest keyword score
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"<text>"}
      """
    Then the response status should be 200
    And the response field "detected_language" should equal "<expected_language>"
    And the response field "supported" should equal true

    Examples:
      | text                      | expected_language |
      | hola need help now        | en                |
      | bonjour merci help account | fr               |

  @edge-case
  Scenario: Handle concurrent detection requests with independent results
    When I submit the following requests to "/api/v1/detect-language" concurrently:
      | text                       | expected_language |
      | hola necesito ayuda        | es                |
      | I need help                | en                |
      | Мне нужна помощь           | ru                |
    Then every response status should be 200
    And each response field "detected_language" should match its "expected_language"

  @error-path
  Scenario: Reject an empty text string before heuristic detection runs
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":""}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject a whitespace-only text string before heuristic detection runs
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"   "}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject a missing text field as empty_input
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {}
      """
    Then the response status should be 400
    And the response field "code" should equal "empty_input"
    And the response field "message" should equal "Input text cannot be empty."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject text shorter than the 2-character minimum
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":"a"}
      """
    Then the response status should be 400
    And the response field "code" should equal "invalid_input"
    And the response field "message" should equal "Input text must be at least 2 characters."
    And the response field "status" should equal 400

  @error-path
  Scenario: Reject text longer than the 5000-character maximum
    Given I build a request body whose "text" field contains exactly 5001 characters made from repeated "a" tokens
    When I send the request to "/api/v1/detect-language"
    Then the response status should be 400
    And the response field "code" should equal "invalid_input"
    And the response field "message" should equal "Input text must not exceed 5000 characters."
    And the response field "status" should equal 400

  @error-path
  Scenario: Return the controller fallback when text is not a string
    When I send a POST request to "/api/v1/detect-language" with body:
      """
      {"text":123}
      """
    Then the response status should be 500
    And the response field "code" should equal "detection_failed"
    And the response field "error" should equal "detection_failed"
    And the response field "message" should equal "An unexpected error occurred during language detection."
    And the response field "status" should equal 500