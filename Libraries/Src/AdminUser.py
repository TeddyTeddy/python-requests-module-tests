from LibraryLoader import LibraryLoader
from robot.api.deco import keyword
from Utilities import get_uri, get_csrfmiddlewaretoken, populate_request_headers
from robot.api import logger
import requests
from collections import ChainMap


class AdminUser:
    """
    This Robot Library makes requests to BlogPostAPI as Admin User.
    It contains private methods for CRUD Requests as well as OPTIONS request.
    It exposes keywords to operate on postings
    """
    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'

    def __init__(self):
        self._loader = LibraryLoader.get_instance()  # singleton
        # read all necessary variables from CommonVariables.py
        self._admin = self._loader.builtin.get_variable_value("${ADMIN}")
        self._api_base_url = self._loader.builtin.get_variable_value("${API_BASE_URL}")
        self._postings_uri = self._loader.builtin.get_variable_value("${POSTINGS_URI}")
        self._invalid_postings_uri = self._loader.builtin.get_variable_value("${INVALID_POSTINGS_URI}")
        self._accept_text_html_header = self._loader.builtin.get_variable_value("${ACCEPT_TEXT_HTML_HEADER}")
        self._additional_put_cookie_tabstyle = self._loader.builtin.get_variable_value("${ADDITIONAL_PUT_COOKIE_TABSTYLE}")
        self._content_type_is_form_header = self._loader.builtin.get_variable_value("${CONTENT_TYPE_IS_FORM_HEADER}")
        self._expected_options_response_headers = self._admin["OPTIONS_RESPONSE_HEADERS"]
        self._admin_login_uri = self._loader.builtin.get_variable_value("${ADMIN_LOGIN_URI}")
        self._admin_login_query_params = self._loader.builtin.get_variable_value("${ADMIN_LOGIN_QUERY_PARAMS}")

        # Session holds sessionid & csrftoken in its cookies, which is shared accross all the requests made through the session
        # Note that there are 2 alternative ways to make authorized requests:
        # (1) Using session & login mechanism
        # (2) Passing Authorization header in all requests
        # (2) is not recognized by the API. That's why we use (1).
        self._session = requests.Session()  # NOTE: session is necessary to keep sessionid & csrftoken in cookie header accross all requests
        self.login_as_admin()

    def _make_login_page_request(self, login_url):
        # request the login page in HTML form
        final_get_request_headers = ChainMap( {'Accept' : self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'] )
        login_page_get_response = self._session.get(login_url, params=self._admin_login_query_params, headers=final_get_request_headers )

        assert self._session.cookies['csrftoken']          # the token must not be an empty string
        return login_page_get_response

    def _get_final_post_request_headers(self, login_url):
        referer_url = f'{login_url}{self._admin_login_query_params}'
        overwritten_post_request_headers = {'Referer': referer_url, 'Content-Type': self._content_type_is_form_header }
        return ChainMap(overwritten_post_request_headers, self._admin['POST_REQUEST_HEADERS'])

    def _get_login_form_data(self, csrfmiddlewaretoken):
        return dict(username=self._admin['USERNAME'], password=self._admin['PASSWORD'],
                    csrfmiddlewaretoken=csrfmiddlewaretoken, next='/admin/')

    def login_as_admin(self):
        login_url = f'{self._api_base_url}{self._admin_login_uri}'
        csrfmiddlewaretoken = get_csrfmiddlewaretoken(self._make_login_page_request(login_url).text)

        # make login request by submitting form encoded data
        login_form_post_response = self._session.post(url=login_url,
                                                      data=self._get_login_form_data(csrfmiddlewaretoken),
                                                      headers=self._get_final_post_request_headers(login_url))
        assert login_form_post_response.status_code == 200  # logged in; session has sessionid must be in cookies now
        assert 'sessionid' in self._session.cookies

    def __del__(self):
        self._session.close()

    @keyword
    def make_options_request(self):
        return self._session.options(url=f'{self._api_base_url}{self._postings_uri}', headers=self._admin['OPTIONS_REQUEST_HEADERS'])

    @keyword
    def verify_options_response(self, options_response):
        assert options_response.status_code == 200
        assert options_response.headers['Allow'] == self._expected_options_response_headers['Allow']
        assert options_response.headers['Vary'] == self._expected_options_response_headers['Vary']
        assert options_response.headers['Content-Type'] == self._expected_options_response_headers['Content-Type']
        assert options_response.json() == self._admin['EXPECTED_API_SPEC']

    def get_post_forms_csrfmiddlewaretoken(self):
        # we need to get the posting form in html format provided by the server. The form has the needed csrfmiddlewaretoken in POST request
        final_get_request_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        post_form_get_response = self._session.get(url=f'{self._api_base_url}{self._postings_uri}', headers=final_get_request_headers)

        csrfmiddlewaretoken = get_csrfmiddlewaretoken(post_form_get_response.text)
        return csrfmiddlewaretoken

    # TODO: Change the keyword as create_posting and repeat the same for other keywords
    @keyword
    def make_post_request(self, posting, payload_encoding,  content_type_header):
        if payload_encoding =='Form' and content_type_header == 'JSON':
            csrfmiddlewaretoken = self.get_post_forms_csrfmiddlewaretoken()
            post_form_data = ChainMap( {'csrfmiddlewaretoken': csrfmiddlewaretoken}, posting)
            # note that self._admin['POST_REQUEST_HEADERS']['Content-Type'] is 'application/json'
            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', data=post_form_data, headers=self._admin['POST_REQUEST_HEADERS'])
        elif payload_encoding == 'JSON' and content_type_header == 'Form':
            csrfmiddlewaretoken = self.get_post_forms_csrfmiddlewaretoken()
            additional_and_overwriting_post_request_headers = { 'X-CSRFTOKEN':csrfmiddlewaretoken, 'Content-Type': self._content_type_is_form_header }
            final_post_request_headers = ChainMap( additional_and_overwriting_post_request_headers, self._admin['POST_REQUEST_HEADERS'] )

            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', json=posting, headers=final_post_request_headers)
        else: # this is usual post request, no tricks
            csrfmiddlewaretoken = self.get_post_forms_csrfmiddlewaretoken()
            additional_post_request_headers = {'X-CSRFTOKEN':csrfmiddlewaretoken}
            final_post_request_headers = ChainMap(additional_post_request_headers, self._admin['POST_REQUEST_HEADERS'])

            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', json=posting, headers=final_post_request_headers)

    @keyword
    def make_get_request(self, headers=None):
        if headers is None:
            headers = self._admin['GET_REQUEST_HEADERS']
        return self._session.get(url=f'{self._api_base_url}{self._postings_uri}', headers=headers)

    @keyword
    def make_bad_get_request(self):
        return self._session.get(url=f'{self._api_base_url}{self._invalid_postings_uri}', headers=self._admin['GET_REQUEST_HEADERS'])

    @keyword
    def make_multiple_get_requests_with_different_headers(self, read_requests=None):
        if read_requests is None:
            result = []
            for get_headers_keys, get_headers_combination in populate_request_headers(self._admin['GET_REQUEST_HEADERS']):
                get_response = self.make_get_request(headers=get_headers_combination)
                result.append([get_headers_combination, get_response.status_code])
            return result
        else:
            for item in read_requests:
                get_response = self.make_get_request(headers=item[0])
                if len(item) == 3:
                    item.pop()
                item.insert(2, get_response.status_code)  # modifies read_requests list

    def get_put_forms_csrfmiddlewaretoken(self, posting):
        final_get_request_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        put_form_get_response = self._session.get(url=posting['url'], headers=final_get_request_headers)
        return get_csrfmiddlewaretoken(put_form_get_response.text)

    def get_final_put_request_headers(self, posting):
        overwriting_put_request_headers = {'Referer':posting['url'], 'X-CSRFTOKEN':self.get_put_forms_csrfmiddlewaretoken(posting) }
        return ChainMap( overwriting_put_request_headers, self._admin['PUT_REQUEST_HEADERS'] )

    @keyword
    def make_put_request(self, posting, headers=None):
        if headers is not None:
            final_put_request_headers = headers
        else:
            final_put_request_headers = self.get_final_put_request_headers(posting)

        return self._session.put(url=posting['url'], headers=final_put_request_headers,
                                 json=posting, cookies=self._additional_put_cookie_tabstyle)

    @keyword
    def make_multiple_put_requests_with_different_headers(self, posting):
        result = []
        for put_headers_keys, put_headers_combination in populate_request_headers(self.get_final_put_request_headers(posting)):
            put_response = self.make_put_request(posting, headers=put_headers_combination)
            result.append([put_headers_keys, put_response.status_code])
        return result

    def get_delete_forms_csrfmiddlewaretoken(self, posting):
        final_get_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        delete_posting_form_get_response = self._session.get(url=posting['url'], headers=final_get_headers)
        return get_csrfmiddlewaretoken(delete_posting_form_get_response.text)

    def get_final_put_request_headers(self, posting):
        overwriting_delete_headers = {'X-CSRFTOKEN': self.get_put_forms_csrfmiddlewaretoken(posting), 'Referer': posting['url'] }
        return ChainMap( overwriting_delete_headers, self._admin['DELETE_REQUEST_HEADERS'] )

    @keyword
    def make_delete_request(self, posting):
        return self._session.delete(url=posting['url'], data=posting, headers=self.get_final_put_request_headers(posting))

    @keyword
    def make_post_requests_and_store_the_result_codes(self, item_list):
        for item in item_list:
            post_response = self.make_post_request(posting=item[0], payload_encoding=None,  content_type_header=None)
            if len(item) == 3:
                item.pop()
            item.insert(2, post_response.status_code)   # modifies item_list












