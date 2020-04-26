*** Settings ***

*** Variables ***
${REGISTERED_POSTINGS}      A list of postings read from the API, set dynamically
${POST_RESPONSE}            A response object to POST request, set dynamically
${OPTIONS_RESPONSE}         A response object to OPTIONS request, set dynamically
${POSTING_SPEC}             A dictionary object, where items are posting fields. Set dynamically
${DELETE_RESPONSE}          A response object to DELETE request, set dynamically
${PRE_SET_POSTINGS}         A list of pre-existing postings in the system before tests with the tag 'CRUD-operations-as-admin' run
${RANDOM_TARGET_POSTING}    A dynamically picked target posting during test run. Set to None at the beginning & end of every test
${TARGET_POSTINGS}          A list of complete postings (i.e. complete: all fields present) \\n
...                         Obtained by subsetting ${REGISTERED_POSTINGS} with ${INCOMPLETE_TARGET_POSTINGS}
${ADMIN_READ_REQUIREMENTS_FILE}          admin_read_requirements.txt

*** Keywords ***
"Registered Postings" Must Comply With "Posting Spec"
    Verify All Postings     postings_to_verify=${REGISTERED_POSTINGS}   posting_spec=${POSTING_SPEC}

"Target Postings" Are Read
    "Registered Postings" Are Read
    @{target_postings} =    Get Subset  subset=${INCOMPLETE_TARGET_POSTINGS}   superset=${REGISTERED_POSTINGS}
    Set Suite Variable      @{TARGET_POSTINGS}     @{target_postings}

"Target Postings" Must Be Registered In The System
    "Target Postings" List Is Not Empty
    ${is_subset} =  Is Subset   subset=${TARGET_POSTINGS}   superset=${INCOMPLETE_TARGET_POSTINGS}
    Should Be True  ${is_subset}