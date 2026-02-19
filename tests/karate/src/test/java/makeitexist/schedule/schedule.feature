Feature: Schedule API
  Tests for /api/v1/schedule endpoints

  Background:
    * url baseUrl
    * def loginResult = call read('classpath:makeitexist/auth/helpers/login-admin.feature')
    * def authToken = loginResult.token

  # ─── Auth guard ─────────────────────────────────────────────────────

  Scenario: GET /schedule without token returns 401
    Given path '/schedule'
    When method GET
    Then status 401

  Scenario: GET /schedule/slots without token returns 401
    Given path '/schedule/slots'
    When method GET
    Then status 401

  # ─── Authenticated access ───────────────────────────────────────────

  Scenario: GET /schedule returns schedule data
    Given path '/schedule'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 200

  Scenario: GET /schedule/slots returns upcoming weekend slots
    Given path '/schedule/slots'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 200
    And match response.data == '#[]'

  # ─── Data-driven: Various query parameters ──────────────────────────

  Scenario Outline: Schedule with date filter '<param>'
    Given path '/schedule'
    And header Authorization = 'Bearer ' + authToken
    And param date = '<param>'
    When method GET
    Then status <expected>

    Examples:
      | param        | expected |
      | 2026-03-07   | 200      |
      | 2026-03-14   | 200      |
      | not-a-date   | 200      |
