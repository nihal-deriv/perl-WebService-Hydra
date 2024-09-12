package WebService::Hydra::Exception::InvalidLoginRequest;
use strict;
use warnings;
use Object::Pad;

class WebService::Hydra::Exception::InvalidLoginRequest :isa(WebService::Hydra::Exception) {
    

    sub BUILDARGS {
        my ($class, %args) = @_;
      
        $args{message}  //= 'Invalid Login Request';
        $args{category} //= 'client';
        
        return %args;
    }
}


1;
