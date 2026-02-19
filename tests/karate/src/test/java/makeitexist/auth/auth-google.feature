Feature: Google SSO Authentication
  Data-driven tests for POST /api/v1/auth/google

  Background:
    * url baseUrl
    * def googleClientId = googleAuthClientId

  # ─── Negative / Validation Tests ────────────────────────────────────

  Scenario: Missing id_token field returns 400
    Given path '/auth/google'
    And request {}
    When method POST
    Then status 400
    And match response.error == 'validation_error'

  Scenario: Empty id_token returns 400
    Given path '/auth/google'
    And request { id_token: '' }
    When method POST
    Then status 400

  Scenario Outline: Invalid Google tokens return 401
    Given path '/auth/google'
    And request { id_token: '<token>' }
    When method POST
    Then status 401
    And match response.error == 'sso_login_failed'
    And match response.message == '#notnull'

    Examples:
      | token                                      |
      | totally-not-a-token                        |
      | eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.fake |
      | expired.google.id.token.abc123             |
      | 12345                                      |

  # ─── Data-driven: Various malformed payloads ────────────────────────

  Scenario Outline: Malformed request bodies return error
    Given path '/auth/google'
    And request <body>
    When method POST
    Then status <expectedStatus>

    Examples:
      | body                                  | expectedStatus |
      | { "wrong_field": "abc" }              | 400            |
      | { "id_token": null }                  | 400            |
      | "not-json"                            | 400            |

  # ─── Positive Test (requires real Google token) ─────────────────────
  # This test is tagged @manual — run only when you have a valid token.

  @manual
  Scenario: Valid Google token creates user and returns JWT
    * def validToken = karate.properties['google.test.token'] || 'SKIP'
    * if (validToken == 'SKIP') karate.abort()
    Given path '/auth/google'
    And request { id_token: '#(validToken)' }
    When method POST
    Then status 200
    And match response.message == 'Login successful'
    And match response.data.token == '#notnull'
    And match response.data.refresh_token == '#notnull'
    And match response.data.user.email == '#notnull'
    And match response.data.user.is_verified == true
