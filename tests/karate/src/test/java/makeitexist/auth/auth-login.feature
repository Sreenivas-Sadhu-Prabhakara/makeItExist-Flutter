Feature: Admin Password Login (Fallback)
  Data-driven tests for POST /api/v1/auth/login

  Background:
    * url baseUrl

  # ─── Data-driven: Invalid login attempts ────────────────────────────

  Scenario Outline: Invalid credentials return 401
    Given path '/auth/login'
    And request { email: '<email>', password: '<password>' }
    When method POST
    Then status 401
    And match response.error == 'login_failed'

    Examples:
      | email                    | password        |
      | nonexistent@aim.edu      | wrongpassword   |
      | admin@aim.edu            | wrongpassword   |
      | fake@gmail.com           | anypassword123  |
      |                          | password123     |
      | notanemail               | password123     |

  # ─── Validation: Missing fields ─────────────────────────────────────

  Scenario: Missing email returns 400
    Given path '/auth/login'
    And request { password: 'test1234' }
    When method POST
    Then status 400
    And match response.error == 'validation_error'

  Scenario: Missing password returns 400
    Given path '/auth/login'
    And request { email: 'test@aim.edu' }
    When method POST
    Then status 400
    And match response.error == 'validation_error'

  Scenario: Empty body returns 400
    Given path '/auth/login'
    And request {}
    When method POST
    Then status 400

  # ─── Positive: Admin login (requires seeded admin) ──────────────────

  @requires-seed
  Scenario: Valid admin credentials return JWT tokens
    Given path '/auth/login'
    And request { email: '#(adminEmail)', password: '#(adminPassword)' }
    When method POST
    Then status 200
    And match response.message == 'Login successful'
    And match response.data.token == '#notnull'
    And match response.data.refresh_token == '#notnull'
    And match response.data.user.email == '#(adminEmail)'
    And match response.data.user.role == '#notnull'
