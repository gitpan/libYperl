
package POE::Filter::Y;

# Most of this was taken from POE::Filter::Block
use POE::Preprocessor(isa => "POE::Macro::UseBytes");

use Y::Message;

use strict;
use vars qw($VERSION);

use Carp;

$VERSION = (qw($Revision: 1.11 $ ))[1];

#------------------------------------------------------------------------------

sub new {
    my $type = shift;
    croak "$type must be given an even number of parameters" if @_ & 1;

    my $buff = '';
    my $self = bless { buffer => \$buff }, $type;

    return $self;
}

#------------------------------------------------------------------------------

sub get {
    my ($self, $stream) = @_;
    my @blocks;
    ${$self->{buffer}} .= join '', @{$stream};

    # If a block size is specified, then frame input into blocks of that
    # size.
    while (my $ev = Y::Message->new($self->{buffer})) {
        push @blocks, $ev;
    }

    return \@blocks;
}

#------------------------------------------------------------------------------
# 2001-07-27 RCC: The get_one() variant of get() allows Wheel::Xyz to
# retrieve one filtered block at a time.  This is necessary for filter
# changing and proper input flow control.

sub get_one_start {
    my ($self, $stream) = @_;
    ${$self->{buffer}} .= join '', @$stream;
}

sub get_one {
    my $self = shift;

    my $ev = Y::Message->new($self->{buffer});
    return [ ] unless $ev;
    return [ $ev ];
}

#------------------------------------------------------------------------------

sub put {
    my ($self, $events) = @_;
    my @raw;

    return [ map { $_->serialise } @$events ];
}

#------------------------------------------------------------------------------

###############################################################################
1;

__END__

