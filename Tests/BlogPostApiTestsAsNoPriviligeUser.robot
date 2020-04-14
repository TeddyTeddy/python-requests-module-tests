*** Settings ***
Documentation    This test suite uses NoPriviligeUser's request headers to test BlogPostAPI.
...              For a NoPriviligeUser, BlogPostAPI provides GET methods
...              as well as OPTIONS method. Note that  POST,PUT and DELETE methods are not supported.
...              Therefore, we can not make Create nor we cannot Delete as NoPriviligeUser.
...              In any way, to be %100 sure that sytem remains
...              intact, we use AdminUser's rights to Delete "Target Postings" in Test Teardown.
...              The URL of the API is:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
Metadata         Version    1.0
Metadata         OS         Linux
Resource         ../Libraries/Src/CommonLibraryImport.robot
Library          NoPriviligeUser
Library          AdminUser
Resource         CommonResource.robot
Suite Setup      Suite Setup
Test Teardown    Test Teardown

# To Run
# python -m robot  --pythonpath Libraries/Src -d Results/ Tests/BlogPostApiTestsAsNoPriviligeUser.robot

*** Keywords ***
Suite Setup
    ${posting_spec} =   Set Variable    ${ADMIN}[EXPECTED_API_SPEC][actions][POST]
    Set Suite Variable      ${POSTING_SPEC}     ${posting_spec}
    "Target Postings" Are Deleted
    "Pre-Set Postings" Are Cached

Test Teardown
    "Registered Postings" Are Read
    Only "Pre-Set Postings" Are Left In The System

Create Posting
    [Arguments]       ${posting}
    ${POST_RESPONSE} =  NoPriviligeUser.Make Post Request  posting=${posting}
    Set Test Variable   ${POST_RESPONSE}

"Registered Postings" Are Read
    ${GET_RESPONSE} =  NoPriviligeUser.Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}

BlogPostAPI Specification Is Correct
    NoPriviligeUser.Verify Options Response     options_response=${OPTIONS_RESPONSE}

BlogPostAPI Specification Is Queried
    ${OPTIONS_RESPONSE} =       NoPriviligeUser.Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

"Target Postings" Are Deleted
    "Registered Postings" Are Read
    FOR     ${iptd}    IN  @{INCOMPLETE_TARGET_POSTINGS}  # iptd: incomplete_posting_to_delete
        Delete Matching Posting    ${iptd}
    END

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Target Postings" Must Not Be Registered In The System
    "Registered Postings" Are Read
    ${none_of_target_postings_found} =  Is None Found  subset=${INCOMPLETE_TARGET_POSTINGS}  superset=${REGISTERED_POSTINGS}
    Should Be True      ${none_of_target_postings_found}

"Pre-Set Postings" Are Cached
    "Registered Postings" Are Read
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

"Target Postings" Are Attempted To Be Created
    # TODO: Move the logic below to NoPriviligeUser.py
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_401} =     Set Variable  ${True}
    FOR     ${ptc}    IN  @{INCOMPLETE_TARGET_POSTINGS}  # ptc: posting_to_create
        Create Posting    posting=${ptc}
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_401} =     Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_401 and $POST_RESPONSE.status_code==401
    END
    Set Test Variable   ${ALL_CREATE_ATTEMPTS_FAILED_WITH_401}

All Create Responses Must Have Status Code "401-Unauthorized"
    Should Be True  ${ALL_CREATE_ATTEMPTS_FAILED_WITH_401}

Update Posting
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   NoPriviligeUser.Make Put Request  posting=${posting}
    Set Test Variable   ${PUT_RESPONSE}

"Pre-Set Postings" Are Attempted To Be Updated
    # TODO: Move the logic below to NoPriviligeUser.py
    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_401} =     Set Variable  ${True}
    FOR     ${ptu}    IN  @{PRE_SET_POSTINGS}  # ptu: posting_to_update
        Update Posting    posting=${ptu}
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_401} =     Evaluate    $ALL_UPDATE_ATTEMPTS_FAILED_WITH_401 and $PUT_RESPONSE.status_code==401
    END
    Set Test Variable   ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_401}

All Update Responses Must Have Status Code "401-Unauthorized"
    Should Be True  ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_401}

Delete Posting
    [Arguments]     ${posting}
    ${DELETE_RESPONSE} =     NoPriviligeUser.Make Delete Request    posting=${posting}
    Set Test Variable       ${DELETE_RESPONSE}

"Pre-Set Postings" Are Attempted To Be Deleted
    # TODO: Move the logic below to NoPriviligeUser.py
    ${ALL_DELETE_ATTEMPTS_FAILED_WITH_401} =     Set Variable  ${True}
    FOR     ${ptd}    IN  @{PRE_SET_POSTINGS}  # ptu: posting_to_delete
        Delete Posting    posting=${ptd}
        ${ALL_DELETE_ATTEMPTS_FAILED_WITH_401} =     Evaluate    $ALL_DELETE_ATTEMPTS_FAILED_WITH_401 and $DELETE_RESPONSE.status_code==401
    END
    Set Test Variable   ${ALL_DELETE_ATTEMPTS_FAILED_WITH_401}

All Delete Responses Must Have Status Code "401-Unauthorized"
    Should Be True  ${ALL_DELETE_ATTEMPTS_FAILED_WITH_401}

Bad Read Request Is Made With Invalid URI
    ${GET_RESPONSE} =   NoPriviligeUser.Make Bad Get Request
    Set Test Variable   ${GET_RESPONSE}

Read Response Should Be "404-Not Found"
    Should Be True   $GET_RESPONSE.status_code == 404

*** Test Cases ***
#########################  POSITIVE TESTS ################################################
Checking BlogPostAPI specification
    [Tags]              smoke-as-NoPriviligeUser
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct

Querying & Verifying Pre-Set Postings
    [Tags]              smoke-as-NoPriviligeUser
    When "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

#########################  NEGATIVE TESTS ################################################
Attempting To Create "Target Postings" Fails
    [Tags]              CRUD-operations-as-NoPriviligeUser    CRUD-failure-as-NoPriviligeUser
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Created
    Then All Create Responses Must Have Status Code "401-Unauthorized"
    Then "Target Postings" Must Not Be Registered In The System
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

Attempting To Update "Pre-Set Postings" Fails
    [Tags]              CRUD-operations-as-NoPriviligeUser    CRUD-failure-as-NoPriviligeUser
    When "Pre-Set Postings" Are Attempted To Be Updated
    Then All Update Responses Must Have Status Code "401-Unauthorized"

Attempting To Delete "Pre-Set Postings" Fails
    [Tags]              CRUD-operations-as-NoPriviligeUser    CRUD-failure-as-NoPriviligeUser
    When "Pre-Set Postings" Are Attempted To Be Deleted
    Then All Delete Responses Must Have Status Code "401-Unauthorized"

Attempting To Read Postings with Invalid URI Fails
    [Tags]                  CRUD-operations-as-NoPriviligeUser     CRUD-failure-as-NoPriviligeUser
    When Bad Read Request Is Made With Invalid URI   # TODO: make this data-driven
    Then Read Response Should Be "404-Not Found"


