package Y::Reply;

use strict;

use POE;

sub new {
    my $class = shift;
    my $y = shift;
    my $seq = shift;
    return bless {
        y         => $y,
        seq       => $seq,
        got_value => 0,
        v         => {
            op     => undef,
            cid    => 0,
            oid    => 0,
            meta   => 0,
            parsed => undef
        }
    }, $class;
}

sub DESTROY {
    my ($self) = @_;
    $self->{y}->detach_reply($self->{seq});
}

sub dispatch {
    my ($self, $message) = @_;
    $self->{v}{cid} = $message->cid;
    $self->{v}{oid} = $message->oid;
    $self->{v}{op} = $message->op;
    $self->{v}{meta} = $message->meta;
    $self->{v}{parsed} = $message->params;
    $self->{got_value} = 1;
}

sub wait {
    my $self = shift;
    $poe_kernel->run_one_timeslice until $self->{got_value};
}

sub oid {
    my $self = shift;
    $self->wait unless $self->{got_value};
    return $self->{v}{oid};
}

sub cid {
    my $self = shift;
    $self->wait unless $self->{got_value};
    return $self->{v}{cid};
}

sub meta {
    my $self = shift;
    $self->wait unless $self->{got_value};
    return $self->{v}{meta};
}

sub seq { $_[0]->{seq} }

sub value {
    my $self = shift;
    $self->wait unless $self->{got_value};
    return $self->{v}{parsed};
}

1;

__END__


