
*** Variables ***
${REGISTERED_POSTINGS}      A list of postings read from the API, set dynamically
${POST_RESPONSE}            A response object to POST request, set dynamically
${OPTIONS_RESPONSE}         A response object to OPTIONS request, set dynamically
${POSTING_SPEC}             A dictionary object, where items are posting fields. Set dynamically
${DELETE_RESPONSE}          A response object to DELETE request, set dynamically
${PRE_SET_POSTINGS}         A list of pre-existing postings in the system before tests with the tag 'CRUD-operations-as-admin' run
${RANDOM_TARGET_POSTING}    A dynamically picked target posting during test run. Set to None at the beginning & end of every test

${ADMIN_READ_PARAMETERS_FILE}            admin_read_parameters.txt
${ADMIN_UPDATE_PARAMETERS_FILE}          admin_update_parameters.txt
${ADMIN_DELETE_PARAMETERS_FILE}          admin_delete_parameters.txt
${ADMIN_OPTIONS_PARAMETERS_FILE}         admin_options_parameters.txt
${ADMIN_CREATE_PARAMETERS_FILE}          admin_create_parameters.txt

*** Keywords ***
"Registered Postings" Must Comply With "Posting Spec"
    Verify All Postings     postings_to_verify=${REGISTERED_POSTINGS}   posting_spec=${POSTING_SPEC}

"Target Postings" Are Read
    "Registered Postings" Are Read
    @{target_postings} =    Get Subset  subset=${INCOMPLETE_TARGET_POSTINGS}   superset=${REGISTERED_POSTINGS}
    Set Test Variable      @{TARGET_POSTINGS}     @{target_postings}

"Target Postings" Must Have Been Updated In The System
    ${is_subset} =  Is Subset   subset=${TARGET_POSTINGS}    superset=${REGISTERED_POSTINGS}
    Should Be True   ${is_subset}

"Target Postings" List Is Not Empty
    ${is_empty} =  Evaluate     len($TARGET_POSTINGS) == 0
    Should Not Be True  ${is_empty}

"Target Postings" Must Be Registered In The System
    "Target Postings" List Is Not Empty
    ${is_subset} =  Is Subset   subset=${TARGET_POSTINGS}   superset=${INCOMPLETE_TARGET_POSTINGS}
    Should Be True  ${is_subset}

Only "Pre-Set Postings" Are Left In The System
    Should Be True  $REGISTERED_POSTINGS == $PRE_SET_POSTINGS

"Target Postings" Must Not Be Registered In The System
    "Registered Postings" Are Read
    ${none_of_target_postings_found} =  Is None Found  subset=${INCOMPLETE_TARGET_POSTINGS}  superset=${REGISTERED_POSTINGS}
    Should Be True      ${none_of_target_postings_found}
