package WebService::Hydra::Exception::HydraRequestError;
use strict;
use warnings;
use Object::Pad;

class WebService::Hydra::Exception::HydraRequestError :isa(WebService::Hydra::Exception) {
    

    sub BUILDARGS {
        my ($class, %args) = @_;

        $args{message}  //= 'Sorry, something went wrong while processing your request';
        $args{category} //= 'hydra';
        
        return %args;
    }
}


1;
