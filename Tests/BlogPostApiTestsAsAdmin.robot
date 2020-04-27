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
# python -m robot  --pythonpath Libraries/Src --exclude requirements-gathering -d Results/ Tests/BlogPostApiTestsAsAdmin.robot

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

"Random Target Posting" Must Be Registered In The System
    "Registered Postings" Are Read
    @{random_target_postings}=    Create List    ${RANDOM_TARGET_POSTING}
    ${is_subset} =  Is Subset   subset=${random_target_postings}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

Update Posting
    [Arguments]        ${posting}       ${payload_encoding}=${None}   ${content_type_header}=${None}
    ${PUT_RESPONSE} =   Make Put Request  posting=${posting}    payload_encoding=${payload_encoding}    content_type_header=${content_type_header}
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

"Parameterized Postings" Must Not Be Registered In The System
    "Registered Postings" Are Read
    ${PARAMETERIZED_POSTINGS} =     Extract Postings  ${ADMIN}[DOING_CREATE_WITH_PARAMETERS]
    Set Test Variable   ${PARAMETERIZED_POSTINGS}
    ${none_of_parameterized_postings_found} =   Is None Found  subset=${PARAMETERIZED_POSTINGS}  superset=${REGISTERED_POSTINGS}
    Should Be True      ${none_of_parameterized_postings_found}

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

Bad Read Request Is Made With Invalid URI
    ${GET_RESPONSE} =   Make Bad Get Request
    Set Test Variable   ${GET_RESPONSE}

Read Response Should Be "404-Not Found"
    Should Be True   $GET_RESPONSE.status_code == 404

"Target Postings" Are Attempted To Be Updated Using Form Encoded Payload And With JSON "Content-Type" Header
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Update Posting     posting=${p}     payload_encoding=Form   content_type_header=JSON
        ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_UPDATE_ATTEMPTS_FAILED_WITH_400 and $PUT_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400}

All Update Responses Have Status Code "400-Bad Request"
    Should Be True  ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400}

"Target Postings" Are Attempted To Be Updated Using JSON Encoded Payload And With Form "Content-Type" Header
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}     payload_encoding=JSON   content_type_header=Form
        Log     ${POST_RESPONSE.status_code}
        ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_UPDATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_UPDATE_ATTEMPTS_FAILED_WITH_400}

"Target Postings" Are Attempted To Be Created Using Form Encoded Payload And With JSON "Content-Type" Header
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}     payload_encoding=Form   content_type_header=JSON
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

All Create Responses Have Status Code "400-Bad Request
    Should Be True  ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

"Target Postings" Are Attempted To Be Created Using JSON Encoded Payload And With Form "Content-Type" Header
    # TODO: Consider to move the below logic to AdminUser.py
    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Set Variable    ${True}
    FOR     ${p}    IN  @{TARGET_POSTINGS}
        Create Posting     posting=${p}     payload_encoding=JSON   content_type_header=Form
        Log     ${POST_RESPONSE.status_code}
        ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400} =    Evaluate    $ALL_CREATE_ATTEMPTS_FAILED_WITH_400 and $POST_RESPONSE.status_code==400
    END
    Set Test Variable    ${ALL_CREATE_ATTEMPTS_FAILED_WITH_400}

Each Posting In "Parameterized Postings" Is Attempted To Be Created
    Make Post Requests And Store The Result Codes  post_requirements=${ADMIN}[DOING_CREATE_WITH_PARAMETERS]  # modifies ${ADMIN}[DOING_CREATE_WITH_PARAMETERS]

Each Posting In "Parameterized Postings" Got Its Expected Create Response Code
    ${all_expected_vs_observed_create_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${ADMIN}[DOING_CREATE_WITH_PARAMETERS]
    Should Be True  ${all_expected_vs_observed_create_response_codes_match}

Only The Postings Having Expected Create Response Code "201-Created" Got Created In The System
    "Registered Postings" Are Read
    ${201_postings} =      Extract Postings     item_list=${ADMIN}[DOING_CREATE_WITH_PARAMETERS]   include_expected_create_response_code=${201}
    ${are_201_postings_registered} =      Is Subset   subset=${201_postings}     superset=${REGISTERED_POSTINGS}
    Should Be True  ${are_201_postings_registered}

    ${everything_except_201_postings} =      Extract Postings     item_list=${ADMIN}[DOING_CREATE_WITH_PARAMETERS]   exclude_expected_create_response_code=${201}
    Log     ${everything_except_201_postings}
    ${is_none_found} =      Is None Found   subset=${everything_except_201_postings}     superset=${REGISTERED_POSTINGS}
    Should Be True  ${is_none_found}


Multiple Read Requests Are Made With Different Headers
    ${GET_REQUIREMENTS} =     Make Multiple Get Requests With Different Headers
    Set Test Variable   @{GET_REQUIREMENTS}

Read Results Are Stored In Requirements File
    Write To File  filename=${ADMIN_READ_PARAMETERS_FILE}  source=${GET_REQUIREMENTS}

Multiple Read Requests Are Made Based On Read Requirements
    ${GET_REQUIREMENTS} =  Read File Content  filename=${ADMIN_READ_PARAMETERS_FILE}
    Make Multiple Get Requests With Different Headers   get_requirements=${GET_REQUIREMENTS}  # modifies ${GET_REQUIREMENTS}
    Set Test Variable   ${GET_REQUIREMENTS}

Observed Read Respond Codes Match Expected Read Respond Codes
    ${all_expected_vs_observed_read_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${GET_REQUIREMENTS}
    Should Be True  ${all_expected_vs_observed_read_response_codes_match}


Multiple Update Requests On "Random Target Posting" Resource Are Made With Different Headers
    ${PUT_REQUIREMENTS} =    Make Multiple Put Requests With Different Headers   posting=${RANDOM_TARGET_POSTING}
    Set Test Variable   @{PUT_REQUIREMENTS}

Update Results Are Stored In Requirements File
    Write To File  filename=${ADMIN_UPDATE_REQUIREMENTS_FILE}  source=${PUT_REQUIREMENTS}

Multiple Update Requests On "Random Target Posting" Resource Are Made According To Requirements
    ${PUT_REQUIREMENTS} =  Read File Content  filename=${ADMIN_UPDATE_REQUIREMENTS_FILE}
    Make Multiple Put Requests With Different Headers   posting=${RANDOM_TARGET_POSTING}    put_requirements=${PUT_REQUIREMENTS}  # modifies ${PUT_REQUIREMENTS}
    Set Test Variable   ${PUT_REQUIREMENTS}

Observed Update Respond Codes Match Expected Update Respond Codes
    ${all_expected_vs_observed_update_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${PUT_REQUIREMENTS}
    Should Be True  ${all_expected_vs_observed_update_response_codes_match}

Multiple Delete Requests On "Random Target Posting" Resource Are Made With Different Headers
    ${DELETE_REQUIREMENTS} =     Make Multiple Delete Requests With Different Headers     target_posting=${INCOMPLETE_TARGET_POSTINGS}[${1}]
    Set Test Variable   @{DELETE_REQUIREMENTS}

Delete Results Are Stored In Requirements File
    Write To File  filename=${ADMIN_DELETE_REQUIREMENTS_FILE}  source=${DELETE_REQUIREMENTS}

Multiple Delete Requests On "Random Target Posting" Resource Are Made According To Requirements
    ${DELETE_REQUIREMENTS} =  Read File Content  filename=${ADMIN_DELETE_REQUIREMENTS_FILE}
    Make Multiple Delete Requests With Different Headers   target_posting=${INCOMPLETE_TARGET_POSTINGS}[${1}]    delete_requirements=${DELETE_REQUIREMENTS}  # modifies ${DELETE_REQUIREMENTS}
    Set Test Variable   ${DELETE_REQUIREMENTS}

Observed Delete Respond Codes Match Expected Delete Respond Codes
    ${all_expected_vs_observed_delete_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${DELETE_REQUIREMENTS}
    Should Be True  ${all_expected_vs_observed_delete_response_codes_match}

Multiple Options Requests Are Made With Different Headers
    ${OPTIONS_REQUIREMENTS} =     Make Multiple Options Requests With Different Headers
    Set Test Variable   @{OPTIONS_REQUIREMENTS}

Multiple Options Requests Are Made Based On Requirements
    ${OPTIONS_REQUIREMENTS} =  Read File Content  filename=${ADMIN_OPTIONS_REQUIREMENTS_FILE}
    Make Multiple Options Requests With Different Headers   options_requirements=${OPTIONS_REQUIREMENTS}  # modifies ${OPTIONS_REQUIREMENTS}
    Set Test Variable   ${OPTIONS_REQUIREMENTS}

Observed Options Respond Codes Match Expected Options Respond Codes
    ${all_expected_vs_observed_options_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${OPTIONS_REQUIREMENTS}
    Should Be True  ${all_expected_vs_observed_options_response_codes_match}

Options Results Are Stored In Requirements File
    Write To File  filename=${ADMIN_OPTIONS_REQUIREMENTS_FILE}  source=${OPTIONS_REQUIREMENTS}

"Target Postings" Must Not Have Been Updated
    @{TARGET_POSTINGS_B4_UPDATE_ATTEMPT} =   Copy List      ${TARGET_POSTINGS}
    "Target Postings" Are Read
    Should Be True      $TARGET_POSTINGS_B4_UPDATE_ATTEMPT==$TARGET_POSTINGS

Multiple Create Requests On "Random Target Posting" Resource Are Made With Different Headers
    ${CREATE_REQUIREMENTS} =     Make Multiple Create Requests With Different Headers     target_posting=${INCOMPLETE_TARGET_POSTINGS}[${1}]
    Set Test Variable   @{CREATE_REQUIREMENTS}

Create Results Are Stored In Requirements File
    Write To File  filename=${ADMIN_CREATE_REQUIREMENTS_FILE}  source=${CREATE_REQUIREMENTS}

Multiple Create Requests On "Random Target Posting" Resource Are Made According To Requirements
    ${CREATE_REQUIREMENTS} =  Read File Content  filename=${ADMIN_CREATE_PARAMETERS_FILE}
    Make Multiple Create Requests       target_posting=${INCOMPLETE_TARGET_POSTINGS}[${1}]
    ...                                 create_requirements=${CREATE_REQUIREMENTS}  # modifies ${CREATE_REQUIREMENTS}
    Set Test Variable   ${CREATE_REQUIREMENTS}

Observed Create Respond Codes Match Expected Create Respond Codes
    ${all_expected_vs_observed_create_response_codes_match} =  Compare Expected Vs Observed Response Codes  requirements=${CREATE_REQUIREMENTS}
    Should Be True  ${all_expected_vs_observed_create_response_codes_match}

*** Test Cases ***
#########################  POSITIVE TESTS ################################################
Checking BlogPostAPI specification
    [Tags]              BAT-as-admin    smoke-as-admin
    When BlogPostAPI Specification Is Queried
    Then BlogPostAPI Specification Is Correct

Querying & Verifying Pre-Set Postings
    [Tags]              BAT-as-admin    smoke-as-admin
    When "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

Creating "Target Postings"
    [Tags]              BAT-as-admin    CRUD-operations-as-admin    CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Created
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Are Read
    Then "Target Postings" Must Be Registered In The System

Updating "Target Postings"
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin    CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When Target Postings Are Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then "Target Postings" Must Have Been Updated In The System

Deleting "Target Postings"
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-success-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When "Target Postings" Are Deleted
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

Updating "Random Target Posting" With Missing "title" Field And Modified "content" Field
    [Documentation]     Note that title & content are required fields in a create request.
    ...                 This might suggest that title & content can also be required fields in an update request.
    ...                 Currently, this test verifies that posting with partial content can be used in an update request.
    ...                 This might or might not be the desired behaviour.
    ...                 TODO: Clarify the desired behaviour.
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-success-as-admin
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
    [Documentation]     Note that title & content are required fields in a create request.
    ...                 This might suggest that title & content can also be required fields in an update request.
    ...                 Currently, this test verifies that posting with partial content can be used in an update request.
    ...                 This might or might not be the desired behaviour.
    ...                 TODO: Clarify the desired behaviour.
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-success-as-admin
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

#########################  NEGATIVE TESTS ################################################

Attempting To Delete Non-Existing "Target Postings" Fails
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Are Deleted
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Deleted
    Then All Delete Responses Have Status Code "404-Not Found"

Attempting To Create Already Created "Target Postings" Fails
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    When "Target Postings" Are Attempted To Be Re-Created
    Then All Create Responses Have Status Code "400-Bad Request"

Attempting To Update "Non-Existing Postings" Fails
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
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
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    When Bad Read Request Is Made With Invalid URI
    Then Read Response Should Be "404-Not Found"

"Target Postings" Are Attempted To Be Created Using Form Encoded Payload And With JSON "Content-Type" Header
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Created Using Form Encoded Payload And With JSON "Content-Type" Header
    Then All Create Responses Have Status Code "400-Bad Request"
    Then "Target Postings" Must Not Be Registered In The System
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

"Target Postings" Are Attempted To Be Created Using JSON Encoded Payload And With Form "Content-Type" Header
    [Documentation]     The system under test should not allow creation of a posting, which is JSON encoded in POST request
    ...                 and the POST request tells that "Content-Type" is Form. This test should be correct and the system
    ...                 under test must be changed.
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Must Not Be Registered In The System
    When "Target Postings" Are Attempted To Be Created Using JSON Encoded Payload And With Form "Content-Type" Header
    Then All Create Responses Have Status Code "400-Bad Request"
    Then "Target Postings" Must Not Be Registered In The System
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"
    Then Only "Pre-Set Postings" Are Left In The System

"Target Postings" Are Attempted To Be Updated Using Form Encoded Payload And With JSON "Content-Type" Header
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    When "Target Postings" Are Attempted To Be Updated Using Form Encoded Payload And With JSON "Content-Type" Header
    Then All Update Responses Have Status Code "400-Bad Request"
    Then "Target Postings" Must Not Have Been Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

"Target Postings" Are Attempted To Be Updated Using JSON Encoded Payload And With Form "Content-Type" Header
    [Documentation]     The system under test should not allow update of a posting, which is JSON encoded in PUT request,
    ...                 and the PUT request tells that "Content-Type" is Form. This test should be correct and the system
    ...                 under test must be changed.
    [Tags]                  BAT-as-admin    CRUD-operations-as-admin     CRUD-failure-as-admin
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    When "Target Postings" Are Attempted To Be Updated Using JSON Encoded Payload And With Form "Content-Type" Header
    Then All Update Responses Have Status Code "400-Bad Request"
    Then "Target Postings" Must Not Have Been Updated
    Then "Registered Postings" Are Read
    Then "Registered Postings" Must Comply With "Posting Spec"

############    A. POISED-CRUDO Tests #######################################################################################
############    A.1 (P)arameters-CRUDO Tests
Create Postings With Different Items
    [Tags]      admin-parameters-CRUDO    admin-doing-create-with_parameters      parameters-being-items-in-posting
    Given "Parameterized Postings" Must Not Be Registered In The System
    When Each Posting In "Parameterized Postings" Is Attempted To Be Created
    Then Each Posting In "Parameterized Postings" Got Its Expected Create Response Code
    Then Only The Postings Having Expected Create Response Code "201-Created" Got Created In The System
    Then "Registered Postings" Must Comply With "Posting Spec"

Gathering Requirements : Admin Doing Several Create Requests With Parameters
    [Tags]      requirements-gathering      admin-parameters-CRUDO      admin-create-parameters       parametes-being-headers
    Given "Target Postings" Must Not Be Registered In The System
    When Multiple Create Requests On "Random Target Posting" Resource Are Made With Different Headers
    Then Create Results Are Stored In Requirements File

Making Several Create Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    admin-create-parameters       parametes-being-headers
    When Multiple Create Requests On "Random Target Posting" Resource Are Made According To Requirements
    Then Observed Create Respond Codes Match Expected Create Respond Codes

Gathering Requirements : Admin Doing Several Read Requests With Different Headers
    [Tags]      requirements-gathering      admin-parameters-CRUDO      admin-read-requirements     parametes-being-headers
    When Multiple Read Requests Are Made With Different Headers
    Then Read Results Are Stored In Requirements File

Make Several Read Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    admin-doing-reads-with-different-request-headers
    When Multiple Read Requests Are Made Based On Read Requirements
    Then Observed Read Respond Codes Match Expected Read Respond Codes

Gather The Results of Several Update Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    requirements-gathering      admin-update-requirements
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    Given "Random Target Posting" Is Cached
    When Multiple Update Requests On "Random Target Posting" Resource Are Made With Different Headers
    Then Update Results Are Stored In Requirements File

Make Several Update Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    admin-doing-update-with-different-request-headers
    Given "Target Postings" Must Not Be Registered In The System
    Given "Target Postings" Are Created
    Given "Target Postings" Are Read
    Given "Target Postings" Must Be Registered In The System
    Given "Random Target Posting" Is Cached
    When Multiple Update Requests On "Random Target Posting" Resource Are Made According To Requirements
    Then Observed Update Respond Codes Match Expected Update Respond Codes

Gather The Results of Several Delete Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    requirements-gathering      admin-delete-requirements
    Given "Target Postings" Must Not Be Registered In The System
    When Multiple Delete Requests On "Random Target Posting" Resource Are Made With Different Headers
    Then Delete Results Are Stored In Requirements File

Make Several Delete Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    admin-doing-delete-with-different-request-headers
    When Multiple Delete Requests On "Random Target Posting" Resource Are Made According To Requirements
    Then Observed Delete Respond Codes Match Expected Delete Respond Codes

Gather The Results of Several Options Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    requirements-gathering      admin-options-requirements
    When Multiple Options Requests Are Made With Different Headers
    Then Options Results Are Stored In Requirements File

Make Several Options Requests With Different Headers
    [Tags]      admin-parameters-CRUDO    admin-doing-options-with-different-request-headers
    When Multiple Options Requests Are Made Based On Requirements
    Then Observed Options Respond Codes Match Expected Options Respond Codes
