package WebService::Hydra::Exception::InvalidIdToken;
use strict;
use warnings;
use Object::Pad;

class WebService::Hydra::Exception::InvalidIdToken :isa(WebService::Hydra::Exception) {
    

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Invalid token';
        $args{category} //= 'client';

        return %args;
    }
}


1;
