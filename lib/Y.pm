
package Y;

use vars qw($VERSION %Replies %Objects);
use strict;

$VERSION = '0.0.3';

use POE qw(Filter::Y Wheel::SocketFactory Wheel::ReadWrite);

use Y::Constants qw(:messages);
use Y::Message;
use Y::Reply;

use Socket;
use WeakRef;
use Carp qw(croak);

sub initialise {
    my $class = shift;
    my $event = shift;

    my $session = $poe_kernel->get_active_session;
    POE::Session->create(
        inline_states => {
            _start        => \&handler_start,
            _stop         => \&handler_stop,
            send          => \&handler_send,
            process       => \&handler_process,
            connected     => \&handler_connected,
            socket_error  => \&handler_socket_error,
            connect_error => \&handler_connect_error,
            shutdown      => \&handler_shutdown,
        },
        args => 'Y',
        heap => { parent => $session->ID, start_event => $event }
    );
}

sub find_class_id {
    my $class = shift;
    my $class_name = shift;

    my $req = new Y::Message(
        op   => YMO_FIND_CLASS,
        data => $class_name
    );
    my $rep = $class->send_message($req);

    return $rep->cid;
}

sub create_object {
    my ($class, $cid) = @_;
    my $req = new Y::Message(
        cid  => $cid,
        op   => YMO_INSTANTIATE,
    );
    return $class->send_message($req);
}

sub created_object {
    my ($class, $obj) = @_;
    #warn "Created: ", $obj->get_oid;
    weaken($Objects{$obj->get_oid} = $obj);
    return;
}

sub find_object {
    my ($class, $oid) = @_;
    return exists $Objects{$oid}
        ? $Objects{$oid}
        : undef;
}

sub destroy_object {
    my ($class, $oid) = @_;
    delete $Objects{$oid};
    return;
}

sub process_event {
    my ($class, $ev) = @_;
    if ($ev->cid != 0 and $ev->oid != 0) {
        my $object = $class->find_object($ev->oid);
        if ($object) {
            my $params = $ev->params;
            if ($params and @$params and $params->[0]) {
                $object->on_event(@$params);
            }
            else {
                warn "Invalid params";
            }
        }
        else {
            warn "No object found for ", $ev->oid;
        }
    }
}

sub process_message {
    my ($class, $m) = @_;
    if ($m->seq == 0) {
        return;
    }
    if (exists $Replies{$m->seq}) {
        my $r = $Replies{$m->seq};
        $r->dispatch($m);
    }
    else {
        warn "No reply for message event ", $m->seq;
    }
}

sub detach_reply {
    my ($class, $seq) = @_;
    delete $Replies{$seq};
    return;
}

sub send_message {
    my ($class, $m) = @_;

    $poe_kernel->post($class => send => $m);

    if ($m->expect_reply and $m->seq > 0) {
        my $r = new Y::Reply($class, $m->seq);
        weaken($Replies{$r->seq} = $r);
        return $r;
    }
    return undef;
}

sub run {
    $poe_kernel->run;
}

sub handler_start {
    my ($kernel, $heap, $alias) = @_[KERNEL, HEAP, ARG0];

    $kernel->alias_set($alias);
    $heap->{class} = $alias;

    my $display = $ENV{YDISPLAY};

    unless ($display) {
        $display = "unix:/tmp/.Y-0";
    }

    my $scheme = $1 if $display =~ s/^([^:]+)://;
    $scheme = 'unix' unless defined $scheme;

    if ($scheme eq 'unix') {
        $display = '/tmp/.Y-0' unless defined $display;

        $heap->{socket} = POE::Wheel::SocketFactory->new(
            SocketDomain  => AF_UNIX,
            SocketType    => SOCK_STREAM,
            RemoteAddress => $display,
            SuccessEvent  => 'connected',
            FailureEvent  => 'connect_error'
        );
    }
    elsif ($scheme eq 'tcp') {
        $display = 'localhost' unless defined $display;

        my ($addr, $port) = split /:/, $display;
        $port = 8900 unless defined $port;
        $heap->{socket} = POE::Wheel::SocketFactory->new(
            SocketDomain  => AF_UNIX,
            SocketType    => SOCK_STREAM,
            RemoteAddress => $addr,
            RemotePort    => $port,
            SuccessEvent  => 'connected',
            FailureEvent  => 'connect_error'
        );
    }
    else {
        die "Unknown scheme: $scheme";
    }
}

sub handler_shutdown {
    my ($kernel, $heap, $session) = @_[KERNEL, HEAP, SESSION];
    delete $heap->{readwrite};
    delete $heap->{socket};

    for my $alias ($kernel->alias_list($session)) {
        $kernel->alias_remove($alias);
    }
}

sub handler_connected {
    my ($kernel, $heap, $socket) = @_[KERNEL, HEAP, ARG0];

    # Tell our parent session we are ready
    $poe_kernel->post($heap->{parent}, $heap->{start_event});

    $heap->{readwrite} = POE::Wheel::ReadWrite->new(
        Handle       => $socket,
        Filter       => POE::Filter::Y->new,
        InputEvent   => 'process',
        ErrorEvent   => 'socket_error'
    );
}

sub handler_send {
    my ($kernel, $heap, $ev) = @_[KERNEL, HEAP, ARG0];
    #warn ">>> ", join(" ", @{$ev->params}), "\n";
    $heap->{readwrite}->put($ev);
}

sub handler_stop {
    %Replies  = ();
    %Objects  = ();
}

sub handler_process {
    my ($kernel, $heap, $ev) = @_[KERNEL, HEAP, ARG0];

    #warn "<<< ", join(" ", @{$ev->params}), "\n";
    if ($ev->op == YMO_EVENT) {
        $heap->{class}->process_event($ev);
    }
    elsif ($ev->op != YMO_NO_OPERATION) {
        $heap->{class}->process_message($ev);
    }
}

sub handler_socket_error {
    my ($kernel, $operation, $errnum, $errstr, $wheel_id) = @_[KERNEL, ARG0 .. ARG3];
    warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
    $kernel->yield('shutdown');
}

sub handler_connect_error {
    my ($kernel, $operation, $errnum, $errstr, $wheel_id) = @_[KERNEL, ARG0 .. ARG3];
    warn "Wheel $wheel_id generated $operation error $errnum: $errstr\n";
    $kernel->yield('shutdown');
}

sub handler_check_event {
    my ($kernel, $object, $context, $signal_name, @params) = @_[KERNEL, ARG0 .. $#_];

    unless ($context->handled) {
        my $parent = $object->get_parent;
        if ($parent) {
            $parent->dispatch_event($signal_name, @params);
        }
    }
}

1;

__END__

=head1 NAME

Y - POE client to the Y windowing system.

=head1 SYNOPSIS

    use Y;
    use Y::Window;
    use Y::Label;
    use POE;

    POE::Session->create(
        inline_states => {
            _start    => sub { Y->initialize('connected') },
            close     => sub { $_[KERNEL]->post(Y => "shutdown") },
            connected => sub {
                my $window = new Y::Window;
                $window->set_property(title => "Test Window");

                my $label = new Y::Label;
                $label->set_property(text => "Hello, World!");

                $window->set_child($label);

                $window->connect_signal(requestClose => 'close');

                $window->show;
                $_[HEAP]->{window} = $window;
            },
        }
    );
    $poe_kernel->run;

=head1 DESCRIPTION

Y windows is an X replacement that exposes high level widgets over a network
interface. This is very different from the X protocol which only exposes
low-level drawing methods.

This module gives an object interface to the high-level protocol using POE as
it's event loop.  libYperl was modeled after the C++ interface, libYc++, which
is part of the Y distribution.

See the examples directory in this distribution.

=head1 SEE ALSO

This is a summary of libYperl's modules.

=over 2

=item Y

Y is a set of class methods and POE state handlers. It handles synchronous IO
for messages that need an immediate responce, creation of the POE session,
connection to the Y server.

=item Y::Object

This is a base class for L<Y::Widget>. It handles basic object properties,
event dispatch to sessions and event registration, object hierarchy, object
destruction.

=item Y::Widget

Here you will find all methods common to widgets (currently none). This class
does not do anything yet. It is here simply to provide a means to subclass.

=item Y::Button

=item Y::Canvas

=item Y::CheckBox

=item Y::Console

=item Y::Constants

=item Y::Context

=item Y::GridLayout

=item Y::Label

=item Y::Menu

=item Y::Object

=item Y::Widget

=item Y::Window

=back

=head1 BUGS

Currently these docs are hardly even started.

=head1 AUTHOR

Scott Beck E<lt>sbeck@gossamer-threads.comE<gt>

=head1 COPYRIGHT AND LICENSE

Except where otherwise noted, Y is Copyright 2003-2004 Scott Beck.  All rights
reserved. Y is free software; you may redistribute it and/or modify it under
the same terms as Perl itself.

=cut

