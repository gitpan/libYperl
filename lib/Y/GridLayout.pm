
package Y::GridLayout;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("GridLayout");
    return $self;
}

sub add_widget {
    my ($self, $child, $x, $y, $w, $h) = @_;
    return unless $child;

    $w = 1 unless defined $w;
    $h = 1 unless defined $h;

    $self->invoke_method(addWidget => $child->get_oid, $x, $y, $w, $h);
    $child->set_parent($self);
    $self->{children}{$child} = $child;
    return;
}

sub remove_widget {
    my ($self, $child) = @_;
    if ($child and $child->get_parent == $self) {
        $self->invode_method(removeWidget => $child->get_oid);
        $child->set_parent(undef);
        delete $self->{children}{$child};
    }
    return;
}


1;

__END__


