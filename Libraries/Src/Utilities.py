from urllib.parse import urlparse
from robot.api.deco import keyword
import re
import CommonVariables
from LibraryLoader import LibraryLoader
from robot.api import logger


def validate_url(url):
    try:
        result = urlparse(url)
        assert all([result.scheme, result.netloc, result.path])
    except ValueError:
        assert False


def get_uri(url):
    # url is for ex: 'https://glacial-earth-31542.herokuapp.com/api/postings/11/'
    api_base_url = CommonVariables.get_variables()['API_BASE_URL']  # 'https://glacial-earth-31542.herokuapp.com'
    pattern = f'{api_base_url}(.+)'
    match = re.match(pattern, url)
    return match.groups()[0]    # /api/postings/11/


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
def delete_null_title_posting():
    loader = LibraryLoader.get_instance()  # singleton
    incomplete_null_title_posting = loader.builtin.get_variable_value("${NULL_TITLE_POSTING}")
    registered_postings = loader.builtin.get_variable_value("${REGISTERED_POSTINGS}")
    is_match_found, matched_posting = is_match(expected_posting=incomplete_null_title_posting, super_set=registered_postings)
    if is_match_found:
        loader.builtin.run_keyword('Make Delete Request',  matched_posting)  # TODO: Cannot receive DELETE response


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
        loader.builtin.run_keyword('Make Put Request',  tp)  # TODO: Cannot receive put response
        
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

