
package Y::Window;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("Window");
    $self->subscribe_signal("requestClose");
    return $self;
}

sub on_event {
    my $self = shift;
    my $name = shift;

    if ($name eq 'requestClose') {
        $self->dispatch_event($name, @_);
    }
    return;
}

sub show {
    my ($self) = @_;
    $self->invoke_method('show');
    return;
}

sub set_child {
    my ($self, $child) = @_;
    return unless $child;

    $self->invoke_method(setChild => $child->get_oid);
    $self->{child} = $child;
    $child->set_parent($self);
    return;
}

sub set_focussed {
    my ($self, $widget) = @_;
    return unless $widget;

    $self->invoke_method(setFocussed => $widget->get_oid);
    return;
}

1;

__END__


