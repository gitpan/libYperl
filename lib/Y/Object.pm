
# Base class

package Y::Object;

use strict;

use WeakRef;
use POE;

use Y;
use Y::Context;
use Y::Constants qw(:messages);

sub new {
    my $class = shift;
    my $class_name = shift;

    my $self = bless {}, $class;
    $self->set_cid(Y->find_class_id($class_name));
    $self->set_oid(0);
    $self->set_create_reply(Y->create_object($self->get_cid));
    return $self;
}

sub DESTROY {
    my $self = shift;
    Y->destroy_object($self->get_oid);
    return;
}

sub set_property {
    my ($self, $name, $value) = @_;

    my $req = new Y::Message(
        cid  => $self->get_cid,
        oid  => $self->get_oid,
        op   => YMO_SET_PROPERTY,
        data => [$name, $value]
    );
    Y->send_message($req);
}

sub get_property {
    my ($self, $name) = @_;

    my $req = new Y::Message(
        cid  => $self->get_cid,
        oid  => $self->get_oid,
        op   => YMO_GET_PROPERTY,
        data => $name,
    );
    my $reply = Y->send_message($req);
    return $reply->value->[0];
}

sub subscribe_signal {
    my $self = shift;
    my $signal_name = shift;

    my $req = new Y::Message(
        cid  => $self->get_cid,
        oid  => $self->get_oid,
        op   => YMO_SUBSCRIBE_SIGNAL,
        data => $signal_name
    );
    Y->send_message($req);
}

sub invoke_method {
    my ($self, @params) = @_;

    my $req = new Y::Message(
        cid  => $self->get_cid,
        oid  => $self->get_oid,
        op   => YMO_INVOKE_METHOD,
        data => \@params,
        meta => (defined(wantarray) ? 0x01 : 0x00),
    );
    return Y->send_message($req);
}

## Added ##
sub connect_signal {
    my $self = shift;
    my $signal_name = shift;
    my $event = shift;

    my $session = $poe_kernel->get_active_session;
    push @{$self->{registered}{$signal_name}}, [ $session, $event, @_ ];
}

## Added ##
sub dispatch_event {
    my $self = shift;
    my $signal_name = shift;

    return unless exists $self->{registered}{$signal_name};

    my $context = new Y::Context;

    for (@{$self->{registered}{$signal_name}}) {
        $poe_kernel->post(
            $_->[0], $_->[1],
            $context, $signal_name, @_,
            @{$_}[2 .. $#$_]
        );
    }
    $poe_kernel->yield(
        check_event => $self,
        $context, $signal_name, @_,
        @{$_}[2 .. $#$_]
    );
}

sub set_create_reply {
    my $self = shift;
    $self->{create_reply} = shift;
    return;
}

sub get_create_reply { $_[0]->{create_reply} }

sub set_parent {
    my $self = shift;
    weaken($self->{parent} = shift);
    return;
}

sub get_parent { $_[0]->{parent} }

sub set_oid {
    my $self = shift;
    $self->{oid} = shift;
    return;
}

sub get_oid {
    my ($self) = @_;
    if ($self->get_create_reply) {
        $self->{oid} = $self->get_create_reply->oid;
        $self->set_create_reply(undef);
        Y->created_object($self);
    }
    return $self->{oid};
}

sub set_cid {
    my $self = shift;
    $self->{cid} = shift;
    return;
}

sub get_cid { $_[0]->{cid} }

1;

__END__



