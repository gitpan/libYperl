
package Y::Menu;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("Menu");
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

sub add_item {
    my ($self, $id, $text, $submenu) = @_;

    $self->{children}{$submenu} = $submenu if $submenu;
    $self->invoke_method(
        addItem => $id, $text, ($submenu ? 0 : $submenu->get_oid)
    );
    $submenu->set_parent($self);
    return;
}

sub build_menu {
    my ($class, @menu_structure) = @_;
    return _build_menu($class, { submenu => \@menu_structure }, 0);
}

sub _build_menu {
    my ($class, $struct, $id) = @_;
    my $menu = $class->new;
    if (exists $struct->{event}) {
        my @arg = exists $struct->{event_argument}
            ? $struct->{event_argument}
            : ();
        $menu->connect_signal(clicked => $struct->{event}, @arg);
    }
    elsif (exists $struct->{submenu}) {
        for my $m (@{$struct->{submenu}}) {
            my $submenu = _build_menu($class, $m, $id);
            my $text = exists $m->{text}
                ? $m->{text}
                : '';
            my $id = exists $m->{id}
                ? $m->{id}
                : ++$id;
            $menu->add_item($id, $text, $submenu);
        }
    }
    return $menu;
}

1;

__END__

=cut

    # Plans for when menus are better handled within Y
    my $menu = Y::Menu->build_menu(
        { text => "Menu 1", submenu => [
            { text => "Submenu 1", event => "handler_menu" },
            { text => "Submenu 2", event => "handler_menu" },
            { text => "Submenu 3", submenu => [
                { text => "SubSubmenu 1", event => "handler_menu" },
                { text => "SubSubmenu 2", event => "handler_menu" },
                { text => "SubSubmenu 3", event => "handler_menu" },
            ]
        ]},
        { text => "Menu 2", event => "handler_menu" },
        { text => "Menu 3", event => "handler_menu" },
        { text => "Menu 4", event => "handler_menu" },
    );

=cut
