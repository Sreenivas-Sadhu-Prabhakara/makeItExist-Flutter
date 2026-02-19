Feature: Health Check API
  Verify the server is alive and responding

  Background:
    * url baseUrl.replace('/api/v1', '')

  Scenario: GET /health returns healthy status
    Given path '/health'
    When method GET
    Then status 200
    And match response.status == 'healthy'
    And match response.service == 'make-it-exist-api'
    And match response.version == '#notnull'
