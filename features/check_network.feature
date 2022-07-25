Feature: Monitor network connectivity

  In order to have confidence that our kubernetes networks are healthy
  As a cluster administrator
  I need to be certain that every host can talk to every other host

  Scenario: Healthy network
    Given a healthy kubernetes network
    When viewing a monitor instance
    Then the monitor should report that the network is healthy

  Scenario: Cannot reach a node
    Given an indicator is unreachable
    When viewing a monitor instance
    Then the monitor should report that it cannot reach the indicator
