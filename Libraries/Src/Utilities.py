from urllib.parse import urlparse
from robot.api.deco import keyword
import re, os, ast
from LibraryLoader import LibraryLoader
from itertools import combinations
from robot.api import logger


def validate_url(url):
    # https://stackoverflow.com/questions/7160737/python-how-to-validate-a-url-in-python-malformed-or-not
    try:
        result = urlparse(url)
        assert '' not in [result.scheme, result.netloc, result.path]
    except ValueError:
        assert False

def get_csrfmiddlewaretoken(response_text):
    """
        part of response_text
        "<form action=\"/admin/login/\" method=\"post\" id=\"login-form\"><input type=\'hidden\' name=\'csrfmiddlewaretoken\' value=\'N3hEAMRIsVqU7C3FJcBxJe79eRzfBrqegZpfzXgWau36AY4SYqL4TxTiC4g8g7EF\' />"
    """
    pattern = re.compile(r"<input type='(?:hidden)' name='(?:csrfmiddlewaretoken)' value='(.+)' ")
    match = re.search(pattern, response_text)
    if match and len(match.groups()) == 1:  # bingo! a match with the pattern found
        return match.groups()[0]

    raise AssertionError('csrfmiddlewaretoken not found')

def get_csrf_token(response_text):
    """
        part of response_text:
            <script>
                window.drf = {
                csrfHeaderName: "X-CSRFTOKEN",
                csrfToken: "Ii71qEPN5tXhtY4hTiu340cVlQaN550DLJttJmYegcjFerybS3E9iSUW3jmqkzUo"
            };
    """
    pattern = re.compile(r'csrfToken: "(.+)"$', re.M)
    match = re.search(pattern, response_text)
    if match and len(match.groups()) == 1:  # bingo! a match with the pattern found
        return match.groups()[0]

    raise AssertionError('csrfToken not found')

def verify_fields(posting, posting_spec):
    for field in posting_spec:
        assert field in posting
        if field == 'url':
            validate_url(posting['url'])

@keyword
def verify_all_postings(postings_to_verify, posting_spec):
    """
    :param postings_to_verify: a list of postings, where each posting needs to be verified against posting_spec
    :param posting_spec: a dict containing keys, which map to posting fields
    :return: None
    """
    for p in postings_to_verify:
        verify_fields(p, posting_spec)


def is_match(expected_posting, super_set):
    is_match_found = False
    matched_posting = None
    for p in super_set:
        # This will likely increase the test execution speed.
        if 'id' in expected_posting and 'id' in p and expected_posting['id'] == p['id']:
            is_match_found = True
            matched_posting = p
            break

        titles_match = False
        contents_match = False
        title_exists = False
        content_exists = False

        if 'title' in p and 'title' in expected_posting:
            titles_match = p['title'] == expected_posting['title']
            title_exists = True
        if 'content' in p and 'content' in expected_posting:
            contents_match = p['content'] == expected_posting['content']
            content_exists = True
        if 'content' in p and p['content'] is None and 'content' not in expected_posting:
            contents_match = content_exists = True
        if 'title' in p and p['title'] is None and 'title' not in expected_posting:
            titles_match = title_exists = True

        if content_exists and title_exists:
            is_match_found = contents_match and titles_match
        elif content_exists:
            is_match_found = contents_match
        elif title_exists:
            is_match_found = titles_match
        else:
            is_match_found = False

        if is_match_found:
            matched_posting = p
            break

    return is_match_found, matched_posting


@keyword
def delete_matching_posting(iptd):    # iptd: incompleted posting to delete
    loader = LibraryLoader.get_instance()  # singleton
    registered_postings = loader.builtin.get_variable_value("${REGISTERED_POSTINGS}")
    is_match_found, matched_posting = is_match(expected_posting=iptd, super_set=registered_postings)
    if is_match_found:
        loader.builtin.run_keyword('AdminUser.Make Delete Request',  matched_posting)  # TODO: Cannot receive DELETE response


@keyword
def is_subset(subset, superset):
    result = True
    for posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=posting, super_set=superset)
        result = result and is_match_found
        if not result:
            break
    return result

@keyword
def target_postings_are_updated():
    """
    EXPECTED PRECONDITION: Before this method is called, TARGET_POSTINGS must be created (i.e.
    REGISTERED_POSTINGS = PRE_SET_POSTINGS + TARGET_POSTINGS)
    Note that all the postings in TARGET_POSTINGS have all the fields necessary
    (i.e. title , content, url, id, timestamp fields) to make a PUT request
    :return: None
    """
    loader = LibraryLoader.get_instance()  # singleton
    target_postings = loader.builtin.get_variable_value("${TARGET_POSTINGS}")
    for tp in target_postings:  # tp: target_posting
        tp['content'] = 'modified content'
        # test call:
        loader.builtin.run_keyword('Make Put Request',  tp)  # NOTE: Cannot receive put response

    loader.builtin.set_test_variable('${TARGET_POSTINGS}', target_postings)


@keyword
def get_subset(subset, superset):
    result = []
    for partial_posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=partial_posting, super_set=superset)
        if is_match_found:
            result.append(matched_posting)
    return result


@keyword
def is_none_found(subset,  superset):
    result = True
    for partial_posting in subset:
        is_match_found, matched_posting = is_match(expected_posting=partial_posting, super_set=superset)
        result = result and not is_match_found
        if not result:
            break
    return result


@keyword
def delete_postings(candidate_postings_to_delete,  postings_to_skip):
    loader = LibraryLoader.get_instance()  # singleton
    for p in candidate_postings_to_delete:
        if p not in postings_to_skip:
            loader.builtin.run_keyword('Make Delete Request',  p)  # NOTE: Cannot receive DELETE response


@keyword
def extract_postings(item_list, include_expected_create_response_code=None, exclude_expected_create_response_code=None):
    """
        :param  item_list: it is a list where each item is a list:
                Each inner item is in the following format:
                inner item: [posting, expected_post_response_code, (received_post_response_code)]
        :return  a list of postings from the inner items of ${ADMIN}[DOING_CREATE_WITH_PARAMETERS]

        Example:
        ${ADMIN}[DOING_CREATE_WITH_PARAMETERS] = [
            [{'title': '', 'content': ''}, 201],
            [{'title': True, 'content': True}, 400],
        ]

        :return: [
            {'title': '', 'content': ''},
            {'title': True, 'content': True},
        ]
    """
    result = []
    for item in item_list:
        if include_expected_create_response_code is not None and item[1] == include_expected_create_response_code: # extract only included
            result.append(item[0])
        if exclude_expected_create_response_code is not None and item[1] != exclude_expected_create_response_code: # extract only not excluded
            result.append(item[0])
        if include_expected_create_response_code is None and exclude_expected_create_response_code is None:  # extract every posting
            result.append(item[0])
    return result


@keyword
def compare_expected_vs_observed_response_codes(requirements):
    all_expected_vs_observed_response_codes_match = True
    for r in requirements:
        if r[1] == r[2]:  # expected create response code == observed_create_response_code
            logger.info(f"Test passed: Requirement ({r[0]} with expected & observed create response code: {r[1]})")
        else:
            logger.error(f"Test failed: Requirement ({r[0]} with expected create response code: {r[1]}) but observed create response code: {r[2]}")
            all_expected_vs_observed_response_codes_match = False
    return all_expected_vs_observed_response_codes_match


def form_headers(key_combination, original_request_headers):
    result = {}
    for key in key_combination:
        result[key] = original_request_headers[key]
    return result

def populate_request_headers(original_request_headers):
    """
    :param original_request_headers: a dictionary of request headers, from which populated result is derived
    :yield result: a dict of request headers
    """
    # result is created by removing one item at a time from original_request_headers
    keys = list(original_request_headers.keys())
    length = 1
    while length < len(keys):
        # https://www.geeksforgeeks.org/permutation-and-combination-in-python/
        iterator = combinations(keys, length)  # a generator
        for key_combination in iterator:
            yield key_combination, form_headers(key_combination, original_request_headers)
        length+=1

    yield (), {}   # represents a key combination of length zero


def get_path_to_data_folder():
    current_abs_path = os.path.abspath(os.getcwd())     # gets the current abs path to the project folder
    sep = os.path.sep  # get os specific path seperator (either '\' for Windows or '/' for linux)
    return f'{current_abs_path}{sep}Data{sep}'               # forms src_abs_path from the grabbed string

def write_to_file(filename, source):
    data_abs_path = get_path_to_data_folder()
    sep = os.path.sep  # get os specific path seperator (either '\' for Windows or '/' for linux)
    full_path_to_file = f'{data_abs_path}{sep}{filename}'
    f = open(full_path_to_file, "w+")   # overwrites the contents of the file
    if type(source) == str:
        f.write(source)
    else:
        f.write(str(source))
    f.close()


@keyword
def read_file_content(filename):
    """
    https://stackoverflow.com/questions/1894269/convert-string-representation-of-list-to-list
    """
    data_abs_path = get_path_to_data_folder()
    sep = os.path.sep  # get os specific path seperator (either '\' for Windows or '/' for linux)
    full_path_to_file = f'{data_abs_path}{sep}{filename}'
    f = open(full_path_to_file, "r")
    content = f.read()
    f.close()
    return ast.literal_eval(content)


def update_requirements(requirements, first_item, observed_response_code):
    for inner_lst in requirements:
        if inner_lst[0] == first_item:
            if len(inner_lst) == 3:
                inner_lst.pop()
            inner_lst.insert(2, observed_response_code)
            break
