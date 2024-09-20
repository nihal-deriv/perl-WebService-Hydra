package WebService::Hydra::Exception::HydraServiceUnreachable;
use strict;
use warnings;
use Object::Pad;

## VERSION

class WebService::Hydra::Exception::HydraServiceUnreachable :isa(WebService::Hydra::Exception) {
    

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Hydra service is unreachable';
        $args{category} //= 'hydra';
        
        return %args;
    }
}


1;
