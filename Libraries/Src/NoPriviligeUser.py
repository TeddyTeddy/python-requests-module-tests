from LibraryLoader import LibraryLoader
from robot.api.deco import keyword
from Utilities import get_uri
from robot.api import logger
import requests

class NoPriviligeUser:
    """
    This Robot Library makes requests to BlogPostAPI as a User with no rights/priviligies.
    It contains private methods for CRUD Requests as well as OPTIONS request.
    """
    ROBOT_LIBRARY_SCOPE = 'TEST SUITE'

    def __init__(self):
        self._loader = LibraryLoader.get_instance()  # singleton
        # read all necessary variables from CommonVariables.py
        self._user = self._loader.builtin.get_variable_value("${NO_PRIVILIGE_USER}")
        self._api_base_url = self._loader.builtin.get_variable_value("${API_BASE_URL}")
        self._postings_uri = self._loader.builtin.get_variable_value("${POSTINGS_URI}")
        self._invalid_postings_uri = self._loader.builtin.get_variable_value("${INVALID_POSTINGS_URI}")
        self._expected_options_response_headers = self._user["OPTIONS_RESPONSE_HEADERS"]
        self._additional_put_cookie_tabstyle = self._loader.builtin.get_variable_value("${ADDITIONAL_PUT_COOKIE_TABSTYLE}")

        self._session = requests.Session()

    def __del__(self):
        self._session.close()

    @keyword
    def make_options_request(self):
        return self._session.options( url=f'{self._api_base_url}{self._postings_uri}', headers=self._user['OPTIONS_REQUEST_HEADERS'])

    @keyword
    def verify_options_response(self, options_response):
        assert options_response.status_code == 200
        assert options_response.headers['Allow'] == self._expected_options_response_headers['Allow']
        assert options_response.headers['Vary'] == self._expected_options_response_headers['Vary']
        assert options_response.headers['Content-Type'] == self._expected_options_response_headers['Content-Type']
        assert options_response.json() == self._user['EXPECTED_API_SPEC']

    @keyword
    def make_post_request(self, posting):
        return self._session.post( url=f'{self._api_base_url}{self._postings_uri}', headers=self._user['POST_REQUEST_HEADERS'],  json=posting )

    @keyword
    def make_get_request(self):
        return self._session.get( url=f'{self._api_base_url}{self._postings_uri}', headers=self._user['GET_REQUEST_HEADERS'] )

    @keyword
    def make_bad_get_request(self):
        return self._session.get( url=f'{self._api_base_url}{self._invalid_postings_uri}', headers=self._user['GET_REQUEST_HEADERS'] )

    @keyword
    def make_put_request(self, posting):
        self._user['PUT_REQUEST_HEADERS']['Referer'] = posting['url']
        return self._session.put( url=posting['url'], headers=self._user['PUT_REQUEST_HEADERS'],  json=posting,
                                  cookies=self._additional_put_cookie_tabstyle )

    @keyword
    def make_delete_request(self, posting):
        self._user['DELETE_REQUEST_HEADERS']['Referer'] = posting['url']
        return self._session.delete( url=posting['url'], headers=self._user['DELETE_REQUEST_HEADERS'],  data=posting )












