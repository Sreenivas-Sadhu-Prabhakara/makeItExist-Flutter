Feature: Admin API
  Data-driven tests for /api/v1/admin endpoints

  Background:
    * url baseUrl
    * def loginResult = call read('classpath:makeitexist/auth/helpers/login-admin.feature')
    * def adminToken = loginResult.token

  # ─── Auth & authorization guard ─────────────────────────────────────

  Scenario: Admin endpoints require authentication
    Given path '/admin/dashboard'
    When method GET
    Then status 401

  Scenario Outline: Admin endpoints reject unauthenticated calls
    Given path '<endpoint>'
    When method GET
    Then status 401

    Examples:
      | endpoint          |
      | /admin/dashboard  |
      | /admin/requests   |
      | /admin/users      |

  # ─── Dashboard ──────────────────────────────────────────────────────

  Scenario: GET /admin/dashboard returns stats
    Given path '/admin/dashboard'
    And header Authorization = 'Bearer ' + adminToken
    When method GET
    Then status 200
    And match response.data == '#notnull'

  # ─── Admin: List requests ───────────────────────────────────────────

  Scenario: GET /admin/requests returns all requests
    Given path '/admin/requests'
    And header Authorization = 'Bearer ' + adminToken
    When method GET
    Then status 200

  # ─── Data-driven: List requests with filters ────────────────────────

  Scenario Outline: Filter admin requests by status '<status>'
    Given path '/admin/requests'
    And header Authorization = 'Bearer ' + adminToken
    And param status = '<status>'
    When method GET
    Then status 200

    Examples:
      | status      |
      | pending     |
      | completed   |
      | rejected    |
      | building    |

  # ─── Admin: List users ──────────────────────────────────────────────

  Scenario: GET /admin/users returns user list
    Given path '/admin/users'
    And header Authorization = 'Bearer ' + adminToken
    When method GET
    Then status 200

  # ─── Data-driven: Paginated user listing ────────────────────────────

  Scenario Outline: Paginated user list — page <page>, limit <limit>
    Given path '/admin/users'
    And header Authorization = 'Bearer ' + adminToken
    And param limit = <limit>
    And param offset = <offset>
    When method GET
    Then status 200

    Examples:
      | page | limit | offset |
      | 1    | 10    | 0      |
      | 2    | 10    | 10     |
      | 1    | 5     | 0      |
      | 1    | 50    | 0      |

  # ─── Admin: Generate schedule slots ─────────────────────────────────

  Scenario: POST /admin/schedule/generate creates weekend slots
    Given path '/admin/schedule/generate'
    And header Authorization = 'Bearer ' + adminToken
    And request { weeks: 4 }
    When method POST
    Then status 200

  # ─── Data-driven: Generate slots with different week counts ─────────

  Scenario Outline: Generate <weeks> weeks of slots
    Given path '/admin/schedule/generate'
    And header Authorization = 'Bearer ' + adminToken
    And request { weeks: <weeks> }
    When method POST
    Then status 200

    Examples:
      | weeks |
      | 1     |
      | 4     |
      | 8     |
      | 12    |

  # ─── Admin: Update request status ──────────────────────────────────

  Scenario: PUT /admin/requests/:id with non-existent ID returns 404
    Given path '/admin/requests/00000000-0000-0000-0000-000000000000'
    And header Authorization = 'Bearer ' + adminToken
    And request { status: 'approved' }
    When method PUT
    Then status 404

  # ─── Admin: Reset password with invalid user ID ─────────────────────

  Scenario: PUT /admin/users/:id/reset-password with bad UUID returns 400
    Given path '/admin/users/not-a-uuid/reset-password'
    And header Authorization = 'Bearer ' + adminToken
    And request { new_password: 'NewPass123!' }
    When method PUT
    Then status 400
