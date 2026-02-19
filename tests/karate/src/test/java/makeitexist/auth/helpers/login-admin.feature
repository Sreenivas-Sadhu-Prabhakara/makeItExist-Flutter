Feature: Login Admin Helper
  Reusable helper to obtain an admin JWT token

  Background:
    * url baseUrl

  Scenario: Obtain admin token
    Given path '/auth/login'
    And request { email: '#(adminEmail)', password: '#(adminPassword)' }
    When method POST
    Then status 200
    * def token = response.data.token
    * def user = response.data.user
