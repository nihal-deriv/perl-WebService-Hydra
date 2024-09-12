package WebService::Hydra::Exception::TokenExchangeFailed;
use strict;
use warnings;
use Object::Pad;

## VERSION

class WebService::Hydra::Exception::TokenExchangeFailed :isa(WebService::Hydra::Exception) {
    

    sub BUILDARGS {
        my ($class, %args) = @_;
        
        $args{message}  //= 'Token exchange failed';
        $args{category} //= 'client';
        
        return %args;
    }
}

1;
