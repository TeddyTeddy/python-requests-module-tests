def get_variables():
    variables = {
        'ADMIN_SESSION': 'Admin Session',
        'API_BASE_URL': 'https://glacial-earth-31542.herokuapp.com',
        'ADMIN_LOGIN_URI': '/admin/login/',
        'ACCEPT_APPLICATION_JSON_HEADER' : 'application/json',
        'ACCEPT_TEXT_HTML_HEADER' : 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
        'ADMIN_LOGIN_QUERY_PARAMS': {'next':'/admin/'},
        'CONTENT_TYPE_IS_FORM_HEADER': 'application/x-www-form-urlencoded',
        'ADDITIONAL_PUT_COOKIE_TABSTYLE': {'tabstyle': 'raw-tab'},
        'ADMIN': {
			'USERNAME': 'hakan',
			'PASSWORD': 'h1a2k3a4',
            'OPTIONS_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Accept': 'application/json',
            },
            'GET_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Accept': 'application/json',  # can be overwritten by ACCEPT_TEXT_HTML_HEADER in ChainMap implementation
            },
            'POST_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Content-Type': 'application/json', # default value for creating a posting, can be overwritten by CONTENT_TYPE_IS_FORM_HEADER in ChainMap implementation
                'Referer': 'https://glacial-earth-31542.herokuapp.com/api/postings/',
            },
            'PUT_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Content-Type': 'application/json',
                'X-CSRFTOKEN': '## DYNAMIC CONTENT ##', # expects the csrfmiddleware token from put posting form
                'Referer': '## DYNAMIC CONTENT ##',  # expects the url of the posting resource here! must be overwritten by url of the posting in ChainMap implementation
            },
            'DELETE_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Accept': 'text/html; q=1.0, */*',
                'X-CSRFTOKEN': '## DYNAMIC CONTENT ##', # expects the csrfmiddleware token from put posting form
                'Referer': '## DYNAMIC CONTENT ##',  # expects the url of the posting resource here! must be overwritten by url of the posting in ChainMap implementation
            },
            'EXPECTED_API_SPEC': {
                'name': 'Blog Post Api',
                'description': '',
                'renders': [
                    'application/json',
                    'text/html'
                ],
                'parses': [
                    'application/json',
                    'application/x-www-form-urlencoded',
                    'multipart/form-data'
                ],
                'actions': {
                    'POST': {
                        'url': {
                            'type': 'field',
                            'required': False,
                            'read_only': True,
                            'label': 'Url'
                        },
                        'id': {
                            'type': 'integer',
                            'required': False,
                            'read_only': True,
                            'label': 'ID'
                        },
                        'user': {
                            'type': 'field',
                            'required': False,
                            'read_only': True,
                            'label': 'User'
                        },
                        'title': {
                            'type': 'string',
                            'required': False,
                            'read_only': False,
                            'label': 'Title',
                            'max_length': 120
                        },
                        'content': {
                            'type': 'string',
                            'required': False,
                            'read_only': False,
                            'label': 'Content',
                            'max_length': 120
                        },
                        'timestamp': {
                            'type': 'datetime',
                            'required': False,
                            'read_only': True,
                            'label': 'Timestamp'
                        }
                    }
                }
            },
            'OPTIONS_RESPONSE_HEADERS': {
                'Allow': 'GET, POST, HEAD, OPTIONS',
                'Vary': 'Accept, Cookie',
                'Content-Type': 'application/json',
            },
            'DOING_CREATE_WITH_PARAMETERS' : [
                # [Posting, expected_POST_result_code, (observed_POST_result_code)]
                [{}, 400],  # empty dictionary as posting
                [{'title': None}, 400],
                [{'content': None}, 400],
                [{'title': None, 'content':None}, 400],
                [{'title': 'Null content posting'}, 400],
                [{'content': 'Null title posting'}, 400],
                [{'title': 'None Content', 'content': None}, 400],
                [{'title': None, 'content': 'None Title'}, 400],
                [{'title': ''}, 400],
                [{'content': ''}, 400],
                [{'title': '', 'content': ''}, 400],
                [{'title': '', 'content': 'Some Content'}, 400],
                [{'title': 'Some title', 'content': ''}, 400],
                [{'title': '', 'content': None}, 400],
                [{'title': None, 'content': ''}, 400],
                [{'title': True, 'content': True}, 400],
                [{'title': 1234, 'content': 3456}, 400],
                [{'title': 'Valid Title', 'content': 'Valid Content'}, 201],
                [{'title': 'Very Very Very Long Title', 'content': 'Very Very Very Long Content'}, 201],
                # TODO: Add more test cases here
            ],
        },
        'NO_PRIVILIGE_USER': {
            'OPTIONS_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Accept': 'application/json',
            },
            'OPTIONS_RESPONSE_HEADERS': {
                'Allow': 'GET, POST, HEAD, OPTIONS',
                'Vary': 'Accept, Cookie',
                'Content-Type': 'application/json',
            },
            'EXPECTED_API_SPEC': {
                "name": "Blog Post Api",
                "description": "",
                "renders": [
                    "application/json",
                    "text/html"
                ],
                "parses": [
                    "application/json",
                    "application/x-www-form-urlencoded",
                    "multipart/form-data"
                ]
            },
            'GET_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Accept': 'application/json',  # Note: this is different from what browser sends to server.
            },
            'POST_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': 'https://glacial-earth-31542.herokuapp.com/api/postings/',
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
            },
           'PUT_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'Content-Type': 'application/json',
                'Accept': 'text/html; q=1.0, */*',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': '## DYNAMIC CONTENT ##',  # expects the url of the posting resource here!
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
            },
            'DELETE_REQUEST_HEADERS': {
                'Host': 'glacial-earth-31542.herokuapp.com',
                'Connection': 'keep-alive',
                'Origin': 'https://glacial-earth-31542.herokuapp.com',
                'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
                'Accept': 'text/html; q=1.0, */*',
                'Sec-Fetch-Dest': 'empty',
                'X-Requested-With': 'XMLHttpRequest',
                'Sec-Fetch-Site': 'same-origin',
                'Sec-Fetch-Mode': 'cors',
                'Referer': '## DYNAMIC CONTENT ##',  # expects the url of the posting resource here!
                'Accept-Encoding': 'gzip, deflate, br',
                'Accept-Language': 'en-US,en;q=0.9,fi;q=0.8',
            },
        },
        'INCOMPLETE_TARGET_POSTINGS': [  # we BAT test CRUD operations on these posts
            {'title': 'Posting 1', 'content': 'Posting 1 content'},
            {'title': 'Posting 2', 'content': 'Posting 2 content'},
            {'title': 'Posting 3', 'content': 'Posting 3 content'},
        ],
        'OVERWRITTEN_TITLE': 'Overwritten title',
        'OVERWRITTEN_CONTENT': 'Overwritten content',
        'POSTINGS_URI': '/api/postings/',
        'INVALID_POSTINGS_URI': '/api/invalid/uri',
    }
    return variables



