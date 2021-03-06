from LibraryLoader import LibraryLoader
from robot.api.deco import keyword
from Utilities import get_csrfmiddlewaretoken, get_csrf_token, update_requirements, populate_request_headers, form_headers
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
        overwritten_post_request_headers = {'Referer': login_url, 'Content-Type': self._content_type_is_form_header }
        final_post_request_headers = ChainMap(overwritten_post_request_headers, self._admin['POST_REQUEST_HEADERS'])
        final_post_request_headers = dict(final_post_request_headers)
        del final_post_request_headers['X-CSRFTOKEN']
        return final_post_request_headers

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
    def make_options_request(self, headers=None):
        if headers:
            final_options_request_headers = headers
        else:
            final_options_request_headers = self._admin['OPTIONS_REQUEST_HEADERS']
        return self._session.options(url=f'{self._api_base_url}{self._postings_uri}', headers=final_options_request_headers)

    def make_multiple_options_requests(self, options_requirements=None):
        if options_requirements:
            for r in options_requirements:
                options_response = self.make_options_request(headers=r[0])
                update_requirements( requirements=options_requirements, first_item=r[0], observed_response_code = options_response.status_code )
        else: # this branch is to create options_requirements
            options_requirements = []
            for options_headers_keys_combo, final_options_headers in populate_request_headers(self._admin['OPTIONS_REQUEST_HEADERS']):
                options_response = self.make_options_request(headers=final_options_headers)
                options_requirements.append([final_options_headers, options_response.status_code])
            return options_requirements

    @keyword
    def verify_options_response(self, options_response):
        assert options_response.status_code == 200
        assert options_response.headers['Allow'] == self._expected_options_response_headers['Allow']
        assert options_response.headers['Vary'] == self._expected_options_response_headers['Vary']
        assert options_response.headers['Content-Type'] == self._expected_options_response_headers['Content-Type']
        assert options_response.json() == self._admin['EXPECTED_API_SPEC']

    def get_post_forms_csrf_token(self):
        # we need to get the post form in html format provided by the server. The form has the needed csrfmiddlewaretoken in POST request
        final_get_request_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        post_form_get_response = self._session.get(url=f'{self._api_base_url}{self._postings_uri}', headers=final_get_request_headers)

        csrf_token = get_csrf_token(post_form_get_response.text)
        return csrf_token

    # TODO: Change the keyword as create_posting and repeat the same for other keywords
    @keyword
    def make_post_request(self, posting, payload_encoding,  content_type_header, headers=None):
        if payload_encoding =='Form' and content_type_header == 'JSON':
            csrf_token = self.get_post_forms_csrf_token()
            post_form_data = ChainMap( {'csrfmiddlewaretoken': csrf_token}, posting)
            # note that self._admin['POST_REQUEST_HEADERS']['Content-Type'] is 'application/json'
            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', data=post_form_data, headers=self._admin['POST_REQUEST_HEADERS'])
        elif payload_encoding == 'JSON' and content_type_header == 'Form':
            csrf_token = self.get_post_forms_csrf_token()
            additional_and_overwriting_post_request_headers = { 'X-CSRFTOKEN':csrf_token, 'Content-Type': self._content_type_is_form_header }
            final_post_request_headers = ChainMap( additional_and_overwriting_post_request_headers, self._admin['POST_REQUEST_HEADERS'] )
            # note that final_post_request_headers['Content-Type'] tells that payload is form encoded, but in fact payload is JSON as below
            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', json=posting, headers=final_post_request_headers)
        else: # this is usual post request, no tricks
            csrf_token = self.get_post_forms_csrf_token()
            additional_post_request_headers = {'X-CSRFTOKEN':csrf_token}
            if headers:
                if 'X-CSRFTOKEN' in headers:
                    final_post_request_headers = ChainMap(additional_post_request_headers, headers)
                else:
                    final_post_request_headers = headers
            else:
                final_post_request_headers = ChainMap(additional_post_request_headers, self._admin['POST_REQUEST_HEADERS'])

            return self._session.post(url=f'{self._api_base_url}{self._postings_uri}', json=posting, headers=final_post_request_headers)

    def make_get_request(self, headers=None):
        if headers is None:
            headers = self._admin['GET_REQUEST_HEADERS']
        return self._session.get(url=f'{self._api_base_url}{self._postings_uri}', headers=headers)

    @keyword
    def make_bad_get_request(self):
        return self._session.get(url=f'{self._api_base_url}{self._invalid_postings_uri}', headers=self._admin['GET_REQUEST_HEADERS'])

    @keyword
    def make_multiple_get_requests(self, get_requirements=None):
        if get_requirements:
            for r in get_requirements:
                get_response = self.make_get_request(headers=r[0])
                update_requirements( requirements=get_requirements, first_item=r[0], observed_response_code= get_response.status_code) # modifies get_requirements
        else: # this is to create get_requirements
            get_requirements = []
            for get_headers_keys, final_get_headers in populate_request_headers(self._admin['GET_REQUEST_HEADERS']):
                get_response = self.make_get_request(headers=final_get_headers)
                get_requirements.append([final_get_headers, get_response.status_code])
            return get_requirements

    def get_put_forms_csrf_token(self, posting):
        final_get_request_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        put_form_get_response = self._session.get(url=posting['url'], headers=final_get_request_headers)
        return get_csrf_token(put_form_get_response.text)

    def get_put_request_headers(self, posting):
        overwriting_put_request_headers = {'Referer':posting['url'], 'X-CSRFTOKEN':self.get_put_forms_csrf_token(posting) }
        # note that self._admin['PUT_REQUEST_HEADERS']['Content-Type'] is 'application/json'
        return ChainMap( overwriting_put_request_headers, self._admin['PUT_REQUEST_HEADERS'] )

    @keyword
    def make_put_request(self, posting, payload_encoding=None, content_type_header=None, headers=None):
        if headers:
            final_put_request_headers = headers
        else:
            final_put_request_headers = self.get_put_request_headers(posting)

        if payload_encoding =='Form' and content_type_header == 'JSON':
            return self._session.put(url=posting['url'], headers=final_put_request_headers, data=posting, cookies=self._additional_put_cookie_tabstyle)
        elif payload_encoding == 'JSON' and content_type_header == 'Form':
            overwriting_put_request_headers = { 'Content-Type': self._content_type_is_form_header }
            final_put_request_headers = ChainMap( overwriting_put_request_headers, final_put_request_headers )
            # note that final_post_request_headers['Content-Type'] tells that payload is form encoded, but in fact payload is JSON as below
            return self._session.put(url=posting['url'], headers=final_put_request_headers, json=posting, cookies=self._additional_put_cookie_tabstyle)
        else:  # this is a usual put request, no tricks
            return self._session.put(url=posting['url'], headers=final_put_request_headers, json=posting, cookies=self._additional_put_cookie_tabstyle)

    @keyword
    def make_multiple_put_requests(self, posting, put_requirements=None):
        if put_requirements:
            for put_headers_keys, final_put_headers in populate_request_headers(self.get_put_request_headers(posting)):
                put_response = self.make_put_request(posting, headers=final_put_headers)
                update_requirements( requirements=put_requirements, first_item=put_headers_keys, observed_response_code = put_response.status_code )
        else: # this branch is to create put_requirements
            put_requirements = []
            for put_headers_keys, final_put_headers in populate_request_headers(self.get_put_request_headers(posting)):
                put_response = self.make_put_request(posting, headers=final_put_headers)
                put_requirements.append([put_headers_keys, put_response.status_code])
            return put_requirements

    def get_delete_forms_csrf_token(self, posting):
        final_get_headers = ChainMap({'Accept':self._accept_text_html_header}, self._admin['GET_REQUEST_HEADERS'])
        delete_posting_form_get_response = self._session.get(url=posting['url'], headers=final_get_headers)
        return get_csrf_token(delete_posting_form_get_response.text)

    def get_delete_request_headers(self, posting):
        overwriting_delete_headers = {'X-CSRFTOKEN': self.get_delete_forms_csrf_token(posting), 'Referer': posting['url'] }
        return ChainMap( overwriting_delete_headers, self._admin['DELETE_REQUEST_HEADERS'] )

    @keyword
    def make_delete_request(self, posting, delete_headers=None):
        if delete_headers:
            final_delete_headers = delete_headers
        else:
            final_delete_headers = self.get_delete_request_headers(posting)

        return self._session.delete(url=posting['url'], data=posting, headers=final_delete_headers)  # 'data': pass posting resource as a form

    @keyword
    def make_post_requests(self, post_requirements):
        for r in post_requirements:
            post_response = self.make_post_request(posting=r[0], payload_encoding=None,  content_type_header=None)
            update_requirements( requirements=post_requirements, first_item=r[0], observed_response_code=post_response.status_code)

    def _create_posting(self, target_posting):
        post_response = self.make_post_request(target_posting, payload_encoding=None,  content_type_header=None)
        assert post_response.status_code == 201  # Created
        return post_response.json()

    @keyword
    def make_multiple_delete_requests(self, target_posting, delete_requirements=None):
        if delete_requirements:
            posting_to_delete_exists = False
            for r in delete_requirements:
                if not posting_to_delete_exists:
                    posting_to_delete = self._create_posting(target_posting)
                final_delete_headers = form_headers(r[0], self.get_delete_request_headers(posting_to_delete))
                # attempt to make delete request with final_delete_headers
                delete_response = self.make_delete_request(posting=posting_to_delete, delete_headers=final_delete_headers)
                update_requirements(requirements=delete_requirements, first_item=r[0], observed_response_code=delete_response.status_code)
                posting_to_delete_exists = not (300 > delete_response.status_code >= 200)

        else: # this branch is to create delete_requirements
            posting_to_delete_exists = False
            delete_requirements = []
            for delete_headers_key_combo, ignored_delete_headers in populate_request_headers(self._admin['DELETE_REQUEST_HEADERS']):
                if not posting_to_delete_exists:
                    posting_to_delete = self._create_posting(target_posting)

                final_delete_headers = form_headers(delete_headers_key_combo, self.get_delete_request_headers(posting_to_delete))
                # attempt to make delete request with final_delete_headers
                delete_response = self.make_delete_request(posting=posting_to_delete, delete_headers=final_delete_headers)
                delete_requirements.append([delete_headers_key_combo, delete_response.status_code])

                # if the delete attempt did not work, posting_to_delete must still exist in the system
                posting_to_delete_exists = not (300 > delete_response.status_code >= 200)
            return delete_requirements

    @keyword
    def make_multiple_create_requests(self, posting_to_create, create_requirements=None):
        if create_requirements:
            posting_to_create_exists = False  # in the System Under Test
            for r in create_requirements:
                if posting_to_create_exists:  # in the System Under Test
                    # API does not allow creation of another posting with the same title; returns 400
                    delete_response = self.make_delete_request(posting_to_create)
                    assert delete_response.status_code == 200
                final_create_headers = form_headers(key_combination=r[0], original_request_headers=self._admin['POST_REQUEST_HEADERS'])
                # attempt to make post request with final_create_headers
                post_response = self.make_post_request(posting=posting_to_create, payload_encoding=None,
                                                       content_type_header=None, headers=final_create_headers)
                update_requirements(requirements=create_requirements, first_item=r[0], observed_response_code=post_response.status_code)
                posting_to_create_exists = (300 > post_response.status_code >= 200)
        else: # this branch is to create create_requirements
            posting_to_create_exists = False  # in the System Under Test
            create_requirements = []
            for create_headers_key_combo, create_headers in populate_request_headers(self._admin['POST_REQUEST_HEADERS']):
                if posting_to_create_exists: # API does not allow creating another posting with the same title; returns 400. If so, then:
                    delete_response = self.make_delete_request(posting_to_create)
                    assert delete_response.status_code == 200

                # attempt to make delete request with final_delete_headers
                post_response = self.make_post_request(posting=posting_to_create, payload_encoding=None,
                                                       content_type_header=None, headers=create_headers)
                create_requirements.append([create_headers_key_combo, post_response.status_code])

                posting_to_create_exists = (300 > post_response.status_code >= 200)
            return create_requirements













