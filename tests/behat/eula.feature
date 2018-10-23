@plugin @plagiarism @plagiarism_turnitin @plagiarism_turnitin_smoke @plagiarism_turnitin_eula
Feature: Plagiarism plugin works with a Moodle Assignment
  In order to allow students to submit to Moodle, they must accept the EULA.
  As a user
  I need to create an assignment with the plugin enabled and the assignment to launch successfully.

  Background: Set up the plugin
    Given the following "courses" exist:
      | fullname | shortname | category | groupmode |
      | Course 1 | C1        | 0        | 0         |
    And I create a unique user with username "student1"
    And I create a unique user with username "instructor1"
    And the following "course enrolments" exist:
      | user        | course | role    |
      | student1    | C1     | student |
      | instructor1 | C1     | editingteacher |
    And I log in as "admin"
    And I navigate to "Advanced features" in site administration
    And I set the field "Enable plagiarism plugins" to "1"
    And I press "Save changes"
    And I navigate to "Plugins > Plagiarism > Turnitin" in site administration
    And I set the following fields to these values:
      | Enable Turnitin            | 1 |
      | Enable Turnitin for Assign | 1 |
    And I configure Turnitin URL
    And I configure Turnitin credentials
    And I set the following fields to these values:
      | Enable Diagnostic Mode | Yes |
    And I press "Save changes"
    Then the following should exist in the "plugins-control-panel" table:
      | Plugin name         |
      | plagiarism_turnitin |
    # Create Assignment.
    And I am on "Course 1" course homepage with editing mode on
    And I add a "Assignment" to section "1" and I fill the form with:
      | Assignment name                   | Test assignment name |
      | use_turnitin                      | 1                    |
      | plagiarism_compare_student_papers | 1                    |
    Then I should see "Test assignment name"

  @javascript
  Scenario: Student can still submit to Moodle even if declining the EULA. The student can then accept the EULA and the admin can resubmit the file.
    Given I log out
    # Student declines the EULA and submits.
    And I log in as "student1"
    And I am on "Course 1" course homepage
    And I follow "Test assignment name"
    And I press "Add submission"
    Then I should see "To submit a file to Turnitin you must first accept our EULA. Choosing to not accept our EULA will submit your file to Moodle only. Click here to accept."
    And I click on ".pp_turnitin_eula_link" "css_element"
    And I wait until ".cboxIframe" "css_element" exists
    And I switch to iframe with locator ".cboxIframe"
    And I wait until the page is ready
    And I click on ".disagree-button" "css_element"
    And I wait until the page is ready
    And I upload "plagiarism/turnitin/tests/fixtures/testfile.txt" file to "File submissions" filemanager
    And I click on "#id_submitbutton" "css_element" in the "#mform2" "css_element"
    Then I should see "Submitted for grading"
    And I should see "Queued"
    And I should see "Your file has not been submitted to Turnitin. Please click here to accept our EULA."
    # Trigger cron as admin for submission
    And I log out
    And I log in as "admin"
    And I run the scheduled task "plagiarism_turnitin\task\send_submissions"
    # Instructor opens assignment.
    And I log out
    And I log in as "instructor1"
    And I am on "Course 1" course homepage
    And I follow "Test assignment name"
    Then I should see "View all submissions"
    When I navigate to "View all submissions" in current page administration
    Then "student1 student1" row "File submissions" column of "generaltable" table should not contain "Turnitin ID:"
    Given I log out
    # Student accepts the EULA.
    And I log in as "student1"
    And I am on "Course 1" course homepage
    And I follow "Test assignment name"
    And I should see "Your file has not been submitted to Turnitin. Please click here to accept our EULA."
    And I should see "This file has not been submitted to Turnitin because the user has not accepted the Turnitin End User Licence Agreement."
    And I accept the Turnitin EULA if necessary
    # Admin can trigger a resubmission from the errors tab of the settings page.
    And I log out
    And I log in as "admin"
    And I navigate to "Plugins > Plagiarism > Turnitin" in site administration
    And I click on "Errors" "link"
    And I click on ".select_all_checkbox" "css_element"
    And I wait "2" seconds
    And I press "Resubmit Selected Files"
    And I wait "10" seconds
    And I run the scheduled task "plagiarism_turnitin\task\send_submissions"
    # Instructor opens assignment.
    And I log out
    And I log in as "instructor1"
    And I am on "Course 1" course homepage
    And I follow "Test assignment name"
    Then I should see "View all submissions"
    When I navigate to "View all submissions" in current page administration
    Then "student1 student1" row "File submissions" column of "generaltable" table should contain "Turnitin ID:"
    # Trigger cron as admin for report
    And I log out
    And I log in as "admin"
    And I obtain an originality report for "student1 student1" on "assignment" "Test assignment name" on course "Course 1"
    # Instructor opens viewer
    And I log out
    And I log in as "instructor1"
    And I am on "Course 1" course homepage
    And I follow "Test assignment name"
    Then I should see "View all submissions"
    When I navigate to "View all submissions" in current page administration
    Then "student1 student1" row "File submissions" column of "generaltable" table should contain "%"
    And I wait until "[alt='GradeMark']" "css_element" exists
    And I click on "[alt='GradeMark']" "css_element"
    And I switch to "turnitin_viewer" window
    And I wait until the page is ready
    And I accept the Turnitin EULA from the EV if necessary
    And I wait until the page is ready
    Then I should see "testfile.txt"