
package Y::Canvas;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("Canvas");
    $self->subscribe_signal("resize");
    return $self;
}

sub on_event {
    my $self = shift;
    my $name = shift;

    if ($name eq 'resize') {
        $self->dispatch_event($name, @_);
    }
    return;
}

sub save_painter_state {
}

sub restore_painter_state {
}

sub set_blend_mode {
}

sub set_pen_color {
    my ($self, $color) = @_;
    $self->invoke_method('setPenColour', $color);
    return;
}

sub set_fill_color {
    my ($self, $color) = @_;
    $self->invoke_method('setFillColour', $color);
    return;
}

sub reset {
    my ($self) = @_;
    my $rep = $self->invoke_method('reset');
    my $res = $rep->value;
    if (@$res >= 2) {
        return ($res->[0], $res->[1]);
    }
    return;
}

sub clear_rectangle {
}

sub draw_rectangle {
}

sub draw_hline {
}

sub draw_vline {
}

sub draw_line {
    my ($self, $x, $y, $dx, $dy) = @_;
    $self->invoke_method(drawLines => $x, $y, $dx, $dy);
    return;
}

sub draw_hlines {
}

sub draw_vlines {
}

sub draw_lines {
    my ($self, @args) = @_;

    croak "Invalid number of arguments to draw_lines" if @args % 4;

    $self->invoke_method(drawLines => @args);
    return;
}

sub set_buffer_size {
    my ($self, $width, $height) = @_;
    $self->invoke_method(setBufferSize => $width, $height);
    return;
}

sub swap_buffers {
    my ($self) = @_;
    $self->invoke_method('swapBuffers');
    return;
}

sub request_size {
    my ($self, $width, $height) = @_;
    $self->invoke_method(requestSize => $width, $height);
    return;
}

1;

__END__


