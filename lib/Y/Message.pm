package Y::Message;

use strict;
use vars qw($SeqNum $Sep);

use Y::Constants qw(:messages);

use Carp;

sub HEADER_SIZE () { 32 }

$Sep = "\x1c";
$SeqNum = 0;

sub new {
    my $class = shift;

    my $self = bless {
        v => {
            to       => 0,
            from     => 0,
            cid      => 0,
            oid      => 0,
            op       => 0,
            meta     => 0,
            seq      => 0,
            len      => 0,
            data     => '',
        },
        got_data => 0,
    }, $class;
    if (@_ == 1) {
        my $buffer = ref($_[0]) ? $_[0] : \$_[0];
        $self->parse_header($buffer) or return undef;
        $self->parse_data($buffer) or return undef;
    }
    elsif (!(@_ & 1)) {
        my %opts = @_;
        $self->{v}{to}   = delete $opts{to}   if exists $opts{to};
        $self->{v}{from} = delete $opts{from} if exists $opts{from};
        $self->{v}{cid}  = delete $opts{cid}  if exists $opts{cid};
        $self->{v}{oid}  = delete $opts{oid}  if exists $opts{oid};
        $self->{v}{op}   = delete $opts{op}   if exists $opts{op};
        $self->{v}{meta} = delete $opts{meta} if exists $opts{meta};
        $self->{v}{seq}  = $class->next_seq;
        if (exists $opts{data}) {
            $self->{got_data} = 1;
            my $d = delete $opts{data};
            if (ref($d) eq 'ARRAY') {
                $self->{v}{data} = join $Sep, @$d;
            }
            else {
                $self->{v}{data} = join($Sep, split(' ', $d));
            }
        }
        croak "Unknown arguments to new(): '", join("', '", sort keys %opts)
            if keys %opts;
    }
    else {
        croak "Invalid arguments to new()";
    }
    return $self;
}

sub next_seq {
    ++$SeqNum;
    $SeqNum = 1 if $SeqNum > 0xFFF_FFF;
    return $SeqNum;
}

sub parse_header {
    my ($self, $buffer) = @_;
    croak "Argument to parse_header() must be a scaler reference, not a ".ref($buffer)
        unless ref($buffer) eq 'SCALAR';

    return undef unless length($$buffer) >= HEADER_SIZE;

    my $header = substr($$buffer, 0, HEADER_SIZE);
    my @head = unpack("N*", $header);
    substr($$buffer, 0, HEADER_SIZE) = '';
    $self->{v} = {
        to   => $head[0],
        from => $head[1],
        cid  => $head[2],
        oid  => $head[3],
        op   => $head[4],
        meta => $head[5],
        seq  => $head[6],
        len  => $head[7],
    };
    return 1;
}

sub parse_data {
    my ($self, $buffer) = @_;
    croak "Argument to parse_data() must be a scaler reference"
        unless ref($buffer) eq 'SCALAR';

    croak "parse_data() called more than once" if $self->{got_data};

    return undef if length($$buffer) < $self->{v}{len};

    # -1 because we do not need a null character
    $self->{v}{data} = substr($$buffer, 0, $self->{v}{len} - 1);

    substr($$buffer, 0, $self->{v}{len}) = '';
    $self->{got_data} = 1;
    return 1;
}

sub serialise {
    my ($self) = @_;

    $self->{v}{data} ||= '';
    $self->{v}{len} = length($self->{v}{data}) + 1;
    return pack("i", unpack("N", pack("i", $self->{v}{to}   || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{from} || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{cid}  || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{oid}  || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{op}   || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{meta} || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{seq}  || 0))) .
           pack("i", unpack("N", pack("i", $self->{v}{len}  || 0))) .
           $self->{v}{data} . "\0"
}

sub expect_reply {
    my ($self) = @_;

    SWITCH: for ($self->{v}{op}) {
        # One-way messages
        $_ == YMO_NO_OPERATION ||
        $_ == YMO_ERROR        ||
        $_ == YMO_QUIT         ||
        $_ == YMO_EVENT       and
            return 0;
        # Replies
        $_ == YMO_SPECIAL_RETURNS   ||
        $_ == YMO_FOUND_CLASS       ||
        $_ == YMO_NEW_OBJECT        ||
        $_ == YMO_METHOD_RETURNS    ||
        $_ == YMO_GOT_PROPERTY      ||
        $_ == YMO_METHODS_LISTED    ||
        $_ == YMO_PROPERTIES_LISTED ||
        $_ == YMO_SET_PROPERTY      ||
        $_ == YMO_SUBSCRIBE_SIGNAL and
            return 0;
        # Messages that expect a reply
        $_ == YMO_INVOKE_SPECIAL   ||
        $_ == YMO_FIND_CLASS       ||
        $_ == YMO_INSTANTIATE      ||
        $_ == YMO_GET_PROPERTY     ||
        $_ == YMO_LIST_METHODS     ||
        $_ == YMO_LIST_PROPERTIES and
            return 1;
        # Messages that might do either, so we need to peek inside them
        $_ == YMO_INVOKE_METHOD and
            return $self->{v}{meta} & 0x01;
    }
    die "Invalid message op $self->{v}{op}";
}

sub params { [ split /$Sep/, $_[0]->{v}{data} ] }
sub to { $_[0]->{v}{to} }
sub from { $_[0]->{v}{from} }
sub cid { $_[0]->{v}{cid} }
sub oid { $_[0]->{v}{oid} }
sub meta { $_[0]->{v}{meta} }
sub seq { $_[0]->{v}{seq} }
sub data { $_[0]->{v}{data} }
sub op { $_[0]->{v}{op} }
sub set_data { $_[0]->{v}{data} = $_[1] }
sub complete { $_[0]->{got_data} }

1;

__END__


