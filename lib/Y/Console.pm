
package Y::Console;

use strict;
use vars qw(@ISA);

use Y::Widget;

use Carp;

@ISA = qw(Y::Widget);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new("Console");
    $self->subscribe_signal("keyPress");
    $self->subscribe_signal("resize");
    return $self;
}

sub on_event {
    my $self = shift;
    my $name = shift;

    if ($name eq 'keyPress' and @_ == 2) {
        $self->dispatch_event($name, @_);
    }
    elsif ($name eq 'resize' and @_ == 2) {
        $self->dispatch_event($name, @_);
    }
    return;
}

sub draw_text {
    my ($self, $col, $row, $mbstring, $length, $height) = @_;
    $self->invoke_method(
        drawText => $col, $row, $mbstring, $length, $height
    );
    return;
}

sub clear_rect {
    my ($self, $scol, $srow, $ecol, $erow) = @_;
    $self->invoke_method(
        clearRect => $scol, $srow, $ecol, $erow
    );
    return;
}

sub set_rendition {
    my ($self, $bold, $blink, $inverse, $underline,
        $forground, $background, $charset) = @_;
    $self->invoke_method(
        setRendition => $bold, $blink, $inverse, $underline,
                        $forground, $background, "$charset\0"
    );
    return;
}

sub swap_video {
    my ($self) = @_;
    $self->invoke_method('swapVideo');
    return;
}

sub ring {
    my ($self) = @_;
    $self->invoke_method('ring');
    return;
}

sub update_cursor_pos {
    my ($self, $col, $row) = @_;
    $self->invoke_method(updateCursorPos => $col, $row);
    return;
}

sub scroll_view {
    my ($self, $dest_row, $src_row, $num_lines) = @_;
    $self->invoke_method(scrollView => $dest_row, $src_row, $num_lines);
    return;
}

1;

__END__


