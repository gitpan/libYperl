
package Y::CheckBox;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("CheckBox");
    $self->subscribe_signal("clicked");
    return $self;
}

sub on_event {
    my $self = shift;
    my $name = shift;

    if ($name eq 'clicked') {
        $self->dispatch_event($name, @_);
    }
    return;
}

1;

__END__


