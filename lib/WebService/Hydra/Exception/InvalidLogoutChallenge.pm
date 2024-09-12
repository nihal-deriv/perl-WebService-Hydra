package WebService::Hydra::Exception::InvalidLogoutChallenge;
use strict;
use warnings;
use Object::Pad;

class WebService::Hydra::Exception::InvalidLogoutChallenge :isa(WebService::Hydra::Exception) {
    field $redirect_to :param :reader = undef;

    sub BUILDARGS {
        my ($class, %args) = @_;
        
        $args{message}  //= 'Invalid Logout Challenge';
        $args{category} //= 'client';
        
        return %args;
    }
}

1;
