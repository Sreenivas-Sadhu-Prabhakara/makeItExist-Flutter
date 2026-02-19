Feature: Build Requests CRUD
  Data-driven tests for /api/v1/requests endpoints

  Background:
    * url baseUrl
    # Helper: obtain an auth token via admin login
    * def loginResult = call read('classpath:makeitexist/auth/helpers/login-admin.feature')
    * def authToken = loginResult.token

  # ─── Auth gate: protected endpoints reject unauthenticated calls ────

  Scenario: GET /requests without token returns 401
    Given path '/requests'
    When method GET
    Then status 401

  Scenario: POST /requests without token returns 401
    Given path '/requests'
    And request { title: 'Test', description: 'Test', request_type: 'website', hosting_type: 'vercel' }
    When method POST
    Then status 401

  # ─── Data-driven: Create build requests from JSON file ──────────────

  Scenario Outline: Create request — <title>
    Given path '/requests'
    And header Authorization = 'Bearer ' + authToken
    And request
      """
      {
        "title": "<title>",
        "description": "<description>",
        "request_type": "<request_type>",
        "hosting_type": "<hosting_type>",
        "tech_requirements": "<tech_requirements>",
        "reference_links": "<reference_links>",
        "hosting_email": "<hosting_email>"
      }
      """
    When method POST
    Then status 201
    And match response.data.id == '#uuid'
    And match response.data.title == '<title>'
    And match response.data.request_type == '<request_type>'
    And match response.data.status == 'pending'
    And match response.message == '#notnull'

    Examples:
      | title                   | description                                     | request_type | hosting_type | tech_requirements          | reference_links                 | hosting_email       |
      | Portfolio Website       | Personal portfolio for projects                  | website      | vercel       | React, Tailwind            | https://example.com/portfolio   | student1@aim.edu    |
      | Campus Events App       | Track and RSVP to campus events                  | mobile_app   | replit       | Flutter, Firebase          | https://example.com/events      | student2@aim.edu    |
      | Marketplace Web + App   | Buy/sell platform for students                   | both         | heroku       | Next.js, React Native      | https://example.com/marketplace | student3@aim.edu    |

  # ─── Validation: Missing required fields ────────────────────────────

  Scenario Outline: Missing required field '<field>' returns 400
    Given path '/requests'
    And header Authorization = 'Bearer ' + authToken
    And request <body>
    When method POST
    Then status 400
    And match response.error == 'validation_error'

    Examples:
      | field        | body                                                                                    |
      | title        | { "description": "Desc", "request_type": "website", "hosting_type": "vercel" }          |
      | description  | { "title": "Test", "request_type": "website", "hosting_type": "vercel" }                |
      | request_type | { "title": "Test", "description": "Desc", "hosting_type": "vercel" }                   |
      | hosting_type | { "title": "Test", "description": "Desc", "request_type": "website" }                  |

  # ─── Data-driven: Invalid request_type values ───────────────────────

  Scenario Outline: Invalid request_type '<badType>' returns 400
    Given path '/requests'
    And header Authorization = 'Bearer ' + authToken
    And request { title: 'Test', description: 'Desc', request_type: '<badType>', hosting_type: 'vercel' }
    When method POST
    Then status 400

    Examples:
      | badType     |
      | desktop     |
      | api_only    |
      | blockchain  |
      |             |

  # ─── List & Get ─────────────────────────────────────────────────────

  Scenario: List my requests returns array
    Given path '/requests'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 200
    And match response.data == '#[]'

  Scenario: Get request by invalid UUID returns 400
    Given path '/requests/not-a-uuid'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 400

  Scenario: Get non-existent request returns 404
    Given path '/requests/00000000-0000-0000-0000-000000000000'
    And header Authorization = 'Bearer ' + authToken
    When method GET
    Then status 404
