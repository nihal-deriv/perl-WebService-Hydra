requires 'Object::Pad',    '0.56';    # Required modules with specific versions
requires 'JSON::MaybeUTF8', '0';
requires 'Scalar::Util',     '0';
requires 'Log::Any',         '0';

on 'test' => sub {
    requires 'Test::More',     '0';   # Test dependencies
};

on 'develop' => sub {
    requires 'strict',         '0';   # Meta dependencies for development
    requires 'warnings',       '0';
    requires 'Test::Pod',      '1.45';  # Run pod tests (optional)
};
