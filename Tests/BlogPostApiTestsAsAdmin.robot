*** Settings ***
Documentation    This test suite uses Admin request headers to test BlogPostAPI.
...              For an admin, BlogPostAPI provides GET, POST, PUT, DELETE methods
...              as well as OPTIONS method. The URL of the API is:
...              https://glacial-earth-31542.herokuapp.com/api/postings/
Metadata         Version    1.0
Metadata         OS         Linux
Resource         ../Libraries/Src/CommonLibraryImport.robot
Library          AdminUser
Resource         CommonResource.robot
Suite Setup      Suite Setup
Test Teardown    Test Teardown
Test Setup       Test Setup

# To Run
# python -m robot  --pythonpath Libraries/Src -d Results/ Tests/BlogPostApiTestsAsAdmin.robot

*** Keywords ***
Suite Setup
    ${posting_spec} =   Set Variable    ${ADMIN}[EXPECTED_API_SPEC][actions][POST]
    Set Suite Variable      ${POSTING_SPEC}     ${posting_spec}
    "Pre-Set Postings" Are Cached

Test Setup
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Test Teardown
    Delete Every Posting Except "Pre-Set Postings"
    "Registered Postings" Are Read
    Only "Pre-Set Postings" Are Left In The System
    Set Suite Variable  ${RANDOM_TARGET_POSTING}      ${None}

Delete Every Posting Except "Pre-Set Postings"
    "Registered Postings" Are Read
    Delete Postings  candidate_postings_to_delete=${REGISTERED_POSTINGS}  postings_to_skip=${PRE_SET_POSTINGS}

Create Posting
    [Arguments]       ${posting}    ${payload_encoding}=${None}   ${content_type_header}=${None}
    ${POST_RESPONSE} =  Make Post Request  posting=${posting}   payload_encoding=${payload_encoding}     content_type_header=${content_type_header}
    Set Test Variable   ${POST_RESPONSE}

Verify Post Response Success Code
    Should Be Equal As Integers 	${POST_RESPONSE.status_code} 	201  # Created

"Target Postings" Are Created
    FOR     ${p}    IN  @{INCOMPLETE_TARGET_POSTINGS}
        Create Posting     posting=${p}
        Verify Post Response Success Code
    END

"Target Postings" Are Attempted To Be Re-Created
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{INCOMPLETE_TARGET_POSTINGS}
        Create Posting     posting=${p}
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

All Create Responses Have Status Code "400-Bad Request"
    Should Be True      ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

Non-Registered "Target Postings" Are Attempted To Be Updated
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_404} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Update Posting     posting=${p}
        ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_404} =    Evaluate    $ALL_UPDATE_ATTEMPTS_FAILED_WITH_404 and $PUT_RESPONSE.status_code==404
    END
    Set Test Variable    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_404}

All Update Responses Have Status Code "404-Not-Found"
    Should Be True      ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_404}

"Target Postings" List Is Not Empty
    ${is_empty} =  Evaluate     len($TARGET_POSTINGS) == 0
    Should Not Be True  ${is_empty}

Must Be Registered In The System
    [Arguments]     ${posting}
    "Registered Postings" Are Read
    @{expected_postings}=    Create List    ${posting}
    ${is_subset} =  Is Subset   subset=${expected_postings}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

"Null Title Posting" Must Be Registered In The System
    Must Be Registered In The System    posting=${NULL_TITLE_POSTING}

"Null Content Posting" Must Be Registered In The System
    Must Be Registered In The System    posting=${NULL_CONTENT_POSTING}

"Null Title And Null Content Posting" Must Be Registered In The System
    Must Be Registered In The System    posting=${NULL_TITLE_NULL_CONTENT_POSTING}

"Random Target Posting" Must Be Registered In The System
    "Registered Postings" Are Read
    @{random_target_postings}=    Create List    ${RANDOM_TARGET_POSTING}
    ${is_subset} =  Is Subset   subset=${random_target_postings}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

Update Posting
    [Arguments]        ${posting}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}
    Set Test Variable   ${PUT_RESPONSE}


Delete Posting
    [Arguments]     ${posting}
    ${DELETE_RESPONSE} =     Make Delete Request    posting=${posting}
    Set Test Variable       ${DELETE_RESPONSE}

"Registered Postings" Are Read
    ${GET_RESPONSE} =   Make Get Request
    Should Be Equal As Integers 	${GET_RESPONSE.status_code} 	200
    @{registered_postings} =    Set Variable  ${GET_RESPONSE.json()}
    Set Suite Variable   @{REGISTERED_POSTINGS}     @{registered_postings}

BlogPostAPI Specification Is Correct
    Verify Options Response     options_response=${OPTIONS_RESPONSE}

BlogPostAPI Specification Is Queried
    ${OPTIONS_RESPONSE} =       Make Options Request
    Set Test Variable   ${OPTIONS_RESPONSE}

"Target Postings" Must Have Been Updated In The System
    ${is_subset} =  Is Subset   subset=${TARGET_POSTINGS}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

Verify Delete Response Success Code
    Should Be Equal As Integers 	${DELETE_RESPONSE.status_code} 	200  # OK

"Target Postings" Are Deleted
    FOR     ${ptd}    IN  @{TARGET_POSTINGS}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        Verify Delete Response Success Code
    END

"Target Postings" Are Attempted To Be Deleted
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404} =     Set Variable  ${True}
    FOR     ${ptd}    IN  @{TARGET_POSTINGS}  # ptd: posting_to_delete
        Delete Posting    posting=${ptd}
        ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404} =     Evaluate    $ALL_DELETE_ATTEMPTS_FAILED_WITH_404 and $DELETE_RESPONSE.status_code==404
    END
    Set Test Variable   ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404}

All Delete Responses Have Status Code "404-Not Found"
    Should Be True   ${ALL_DELETE_ATTEMPTS_FAILED_WITH_404}

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Target Postings" Must Not Be Registered In The System
    "Registered Postings" Are Read
    ${none_of_target_postings_found} =  Is None Found  subset=${INCOMPLETE_TARGET_POSTINGS}  superset=${REGISTERED_POSTINGS}
    Should Be True      ${none_of_target_postings_found}

"Pre-Set Postings" Are Cached
    "Registered Postings" Are Read
    Set Suite Variable      @{PRE_SET_POSTINGS}     @{REGISTERED_POSTINGS}

"Target Postings" Must Not Be An Empty List
    ${is_empty} =   Evaluate    len($TARGET_POSTINGS) == 0
    Should Not Be True  ${is_empty}

"Random Target Posting" Is Cached
    "Target Postings" Must Not Be An Empty List
    ${random_index} =   Evaluate   random.randint(0, len($TARGET_POSTINGS)-1)   modules=random
    ${random_posting} =     Set Variable        ${TARGET_POSTINGS}[${random_index}]
    Set Suite Variable      ${RANDOM_TARGET_POSTING}       ${random_posting}

"title" Field Is Removed From "Random Target Posting"
    Remove From Dictionary      ${RANDOM_TARGET_POSTING}       title

"Random Target Posting" Is Updated To The System
    Update Posting      posting=${RANDOM_TARGET_POSTING}

Update Response Has Status Code 200
    ${update_response_has_200} =    Evaluate    $PUT_RESPONSE.status_code == 200
    Should Be True      ${update_response_has_200}

"content" Field Is Modified in "Random Target Posting"
    Set To Dictionary   ${RANDOM_TARGET_POSTING}      content=${OVERWRITTEN_CONTENT}

"content" Field Is Removed From "Random Target Posting"
   Remove From Dictionary      ${RANDOM_TARGET_POSTING}       content

"title" Field Is Modified in "Random Target Posting"
    Set To Dictionary   ${RANDOM_TARGET_POSTING}      title=${OVERWRITTEN_TITLE}

"Null Title Posting" Is Created
    Create Posting  posting=${NULL_TITLE_POSTING}

"Null Content Posting" Is Created
    Create Posting  posting=${NULL_CONTENT_POSTING}

"Null Title And Null Content Posting" Is Created
    Create Posting  posting=${NULL_TITLE_NULL_CONTENT_POSTING}

Bad Read Request Is Made With Invalid URI
    ${GET_RESPONSE} =   Make Bad Get Request
    Set Test Variable   ${GET_RESPONSE}

Read Response Should Be "404-Not Found"
    Should Be True   $GET_RESPONSE.status_code == 404

There Is No "Null Title Posting" Registered In The System
    @{null-title-postings} =    Create List     ${NULL_TITLE_POSTING}
    ${is_none_found} =     Is None Found     subset=${null-title-postings}   superset=${PRE_SET_POSTINGS}
    Should Be True   ${is_none_found}

There Is No "Null Content Posting" Registered In The System
    @{null-content-postings} =    Create List     ${NULL_CONTENT_POSTING}
    ${is_none_found} =     Is None Found     subset=${null-content-postings}   superset=${PRE_SET_POSTINGS}
    Should Be True   ${is_none_found}

There Is No "Null Title And Null Content Posting" Registered In The System
    @{null-title-null-content-postings} =    Create List     ${NULL_TITLE_NULL_CONTENT_POSTING}
    ${is_none_found} =     Is None Found     subset=${null-title-null-content-postings}   superset=${PRE_SET_POSTINGS}
    Should Be True   ${is_none_found}

"Target Postings" Are Attempted To Be Created Using Form Encoding With Content-Type Header Set As JSON
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}     payload_encoding=Form   content_type_header=JSON
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

All Create Responses Have Status Code "400-Bad Request
    Should Be True  ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

*** Test Cases ***
#########################  POSITIVE TESTS ################################################
Checking BlogPostAPI specification
    [Tags]              smoke-as-admin
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct

Querying & Verifying Pre-Set Postings
    [Tags]              smoke-as-admin
    When "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

Creating "Target Postings"
    [Tags]              CRUD-operations-as-admin    CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Created
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Are Read
    Then "Target Postings" Must Be Registered In The System

Updating "Target Postings"
    [Tags]                  CRUD-operations-as-admin    CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When Target Postings Are Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Must Have Been Updated In The System

Deleting "Target Postings"
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When "Target Postings" Are Deleted
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

Updating "Random Target Posting" With Missing "title" Field And Modified "content" Field
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    Given "Random Target Posting" Is Cached
        Given "title" Field Is Removed From "Random Target Posting"
        Given "content" Field Is Modified in "Random Target Posting"
    When "Random Target Posting" Is Updated To The System
    Then Update Response Has Status Code 200
    Then "Random Target Posting" Must Be Registered In The System

Updating "Random Target Posting" With Missing "content" Field And Modified "title" Field
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    Given "Random Target Posting" Is Cached
        Given "content" Field Is Removed From "Random Target Posting"
        Given "title" Field Is Modified in "Random Target Posting"
    When "Random Target Posting" Is Updated To The System
    Then Update Response Has Status Code 200
    Then "Random Target Posting" Must Be Registered In The System

Creating "Null Title Posting"
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given There Is No "Null Title Posting" Registered In The System
    When "Null Title Posting" Is Created
    Then Verify Post Response Success Code
    Then "Null Title Posting" Must Be Registered In The System

Creating "Null Content Posting"
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given There Is No "Null Content Posting" Registered In The System
    When "Null Content Posting" Is Created
    Then Verify Post Response Success Code
    Then "Null Content Posting" Must Be Registered In The System

Creating "Null Title And Null Content Posting"
    [Tags]                  CRUD-operations-as-admin     CRUD-success-as-admin
    Given There Is No "Null Title And Null Content Posting" Registered In The System
    When "Null Title And Null Content Posting" Is Created
    Then Verify Post Response Success Code
    Then "Null Title And Null Content Posting" Must Be Registered In The System

#########################  NEGATIVE TESTS ################################################

Attempting To Delete Non-Existing "Target Postings" Fails
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Are Deleted
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Deleted
    Then All Delete Responses Have Status Code "404-Not Found"

Attempting To Create Already Created "Target Postings" Fails
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When "Target Postings" Are Attempted To Be Re-Created
    Then All Create Responses Have Status Code "400-Bad Request"

Attempting To Update "Non-Existing Postings" Fails
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Are Deleted
    When Non-Registered "Target Postings" Are Attempted To Be Updated
    Then All Update Responses Have Status Code "404-Not-Found"
    Then "Target Postings" Must Not Be Registered In The System
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

Attempting To Read Postings with Invalid URI
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    When Bad Read Request Is Made With Invalid URI
    Then Read Response Should Be "404-Not Found"

"Target Postings" Are Attempted To Be Created Using Form Encoding With Content-Type Header Set As JSON
    [Tags]                  CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Created Using Form Encoding With Content-Type Header Set As JSON
    Then All Create Responses Have Status Code "400-Bad Request"
    Then "Target Postings" Must Not Be Registered In The System
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System




