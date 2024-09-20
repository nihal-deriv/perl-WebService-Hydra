use strict;
use warnings;
use Test::More;
use Test::Deep;
use Test::Exception;
use Test::MockModule;
use JSON::MaybeUTF8 qw(:v1);
use HTTP::Tiny;
use WebService::Hydra::Client;

subtest 'Hydra Client Creation' => sub {
    my $admin_url  = "http://dummyhydra.com/admin";
    my $public_url = "http://dummyhydra.com";
    my $client     = WebService::Hydra::Client->new(
        admin_endpoint  => $admin_url,
        public_endpoint => $public_url
    );
    is $client->admin_endpoint,  $admin_url,  'Client created successfully with admin endpoint';
    is $client->public_endpoint, $public_url, 'Client created successfully with public endpoint';
};

subtest 'api_call method' => sub {
    my $mock_http = Test::MockModule->new("HTTP::Tiny");
    my ($code, $mock_http_response, @params);

    $mock_http->redefine(
        'request',
        sub {
            (@params) = @_;
            return {
                status  => $code,
                content => ref $mock_http_response ? encode_json_utf8($mock_http_response) : $mock_http_response
            };
        });
    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    $code               = 200;
    $mock_http_response = {key => 'value'};
    my $expected = {
        code => $code,
        data => $mock_http_response
    };
    my $got = $client->api_call('GET', 'http://dummyhydra.com/oauth2/auth');
    is $params[1], 'GET',                               'Correct http method is used';
    is $params[2], 'http://dummyhydra.com/oauth2/auth', 'Request sent to correct endpoint';
    cmp_deeply($got, $expected, 'Data returned in expected structure');

    $mock_http_response = undef;
    my $payload = {key => 'value'};
    $got = $client->api_call('POST', 'http://dummyhydra.com/oauth2/auth', $payload);
    my $extra_request_params = $params[3];
    is $extra_request_params->{headers}->{'Content-Type'}, 'application/json',         'Content type: JSON used for payload';
    is $extra_request_params->{content},                   encode_json_utf8($payload), 'Payload is set correctly';
    is_deeply $got->{data}, {}, 'Returns an empty hash for Empty payload';

    $mock_http_response = undef;
    $payload            = {
        key  => 'value',
        key2 => 'value2'
    };
    $got                  = $client->api_call('POST', 'http://dummyhdra.com/oauth2/auth', $payload, 'FORM');
    $extra_request_params = $params[3];
    is $extra_request_params->{headers}->{'Content-Type'}, 'application/x-www-form-urlencoded', 'Content type: form-urlencode used for payload';
    is $extra_request_params->{headers}->{'Accept'},       'application/json',                  'Sets JSON as the accepted response content-type';
    is $extra_request_params->{content},                   HTTP::Tiny->new->www_form_urlencode($payload), 'Payload is set correctly';

    $mock_http->redefine(
        'request',
        sub {
            die 'Network issue';
        });

    dies_ok { $client->api_call('GET', 'http://dummyhydra.com/oauth2/auth') } 'Dies if the request fails';
    my $exception = $@;
    ok $exception->isa('WebService::Hydra::Exception::HydraRequestError'), 'Error response on die';

};

subtest 'get_login_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    $mock_api_response = {
        code => 200,
        data => {
            challenge   => 'VALID_CHALLENGE',
            client      => {},
            request_url => 'url',
            skip        => 'true',
            subject     => 'user_id'
        }};
    my $got = $client->get_login_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/login?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_login_request("INVALID_CHALLENGE") } 'Dies if non 200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLoginChallenge->new(
        message  => 'Failed to get login request',
        category => 'client',
        details  => $mock_api_response
    );

    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/login?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_login_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'get_consent_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {
            challenge   => 'VALID_CHALLENGE',
            client      => {},
            request_url => 'url',
            skip        => 'true',
            subject     => 'user_id'
        }};
    my $got = $client->get_consent_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/consent?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for 410 Gone status code
    $mock_api_response = {
        code => 410,
        data => {redirect_to => 'http://dummyhydra.com/redirect'}};
    dies_ok { $client->get_consent_request("HANDLED_CHALLENGE") } 'Dies if 410 status code is received from api_call';
    my $exception = $@;

    my $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message     => 'Consent request has already been handled',
        category    => 'client_redirecting_error',
        redirect_to => $mock_api_response->{data}->{redirect_to});
    is_deeply $exception , $expected_exception, 'Return api_call response for 410 status code';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_consent_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    $exception          = $@;
    $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message  => 'Failed to get consent request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_consent_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'accept_consent_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    my $params = {
        grant_scope                 => ['openid', 'offline'],
        grant_access_token_audience => ['client_id'],
        session                     => {id_token => {sub => 'user'}}};

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {redirect_to => 'http://dummyhydra.com/callback'}};
    my $got = $client->accept_consent_request("VALID_CHALLENGE", $params);
    is $params[1], 'PUT', 'PUT request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $params[3], $params,                    'Request parameters are correct';
    is_deeply $got ,      $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->accept_consent_request("INVALID_CHALLENGE", $params) } 'Dies if non-200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidConsentChallenge->new(
        message  => 'Failed to accept consent request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->accept_consent_request("VALID_CHALLENGE", $params) } 'Dies if http request fails for some reason';
};

subtest 'get_logout_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {
            challenge    => "5511ea26-6334-4f5c-9fe1-d812f5ca4068",
            subject      => "1",
            sid          => "2505a9e4-5e48-4911-9af4-31124c7b2217",
            request_url  => "/oauth2/sessions/logout",
            rp_initiated => 0,
            client       => undef,
        }};
    my $got = $client->get_logout_request("VALID_CHALLENGE");
    is $params[1], 'GET', 'GET request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/logout?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for 410 Gone status code
    $mock_api_response = {
        code => 410,
        data => {redirect_to => 'http://dummyhydra.com/redirect'}};
    dies_ok { $client->get_logout_request("HANDLED_CHALLENGE") } 'Dies if 410 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message     => 'Logout challenge has already been handled',
        category    => 'client_redirecting_error',
        redirect_to => $mock_api_response->{data}->{redirect_to});
    is_deeply $exception , $expected_exception, 'Return api_call response for 410 status code';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->get_logout_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    $exception          = $@;
    $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message  => 'Failed to get logout request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/logout?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->get_logout_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

subtest 'accept_logout_request' => sub {
    my $mock_hydra = Test::MockModule->new('WebService::Hydra::Client');
    my $mock_api_response;
    my @params;
    $mock_hydra->redefine(
        'api_call',
        sub {
            (@params) = @_;
            return $mock_api_response;
        });

    my $client = WebService::Hydra::Client->new(
        admin_endpoint  => 'http://dummyhydra.com/admin',
        public_endpoint => 'http://dummyhydra.com'
    );

    # Test for 200 OK status code
    $mock_api_response = {
        code => 200,
        data => {redirect_to => 'http://dummyhydra.com/callback'}};
    my $got = $client->accept_logout_request("VALID_CHALLENGE");
    is $params[1], 'PUT', 'PUT request method';
    is $params[2], 'http://dummyhydra.com/admin/admin/oauth2/auth/requests/logout/accept?challenge=VALID_CHALLENGE',
        'Request URL built with correct parameters';
    is_deeply $got , $mock_api_response->{data}, 'api_call response correctly parsed';

    # Test for other non-200 status codes
    $mock_api_response = {
        code => 400,
        data => {
            error             => "string",
            error_description => "string",
            status_code       => 400
        }};
    dies_ok { $client->accept_logout_request("INVALID_CHALLENGE") } 'Dies if non-200 status code is received from api_call';
    my $exception          = $@;
    my $expected_exception = WebService::Hydra::Exception::InvalidLogoutChallenge->new(
        message  => 'Failed to accept logout request',
        category => 'client',
        details  => $mock_api_response
    );
    is_deeply $exception , $expected_exception, 'Return api_call response for Non 200 status code';

    $mock_hydra->redefine(
        'api_call',
        sub {
            die "Request to http://dummyhydra.com/admin/oauth2/auth/requests/consent/accept?challenge=VALID_CHALLENGE failed - Network issue";
        });

    dies_ok { $client->accept_logout_request("VALID_CHALLENGE") } 'Dies if http request fails for some reason';
};

done_testing();

1;
