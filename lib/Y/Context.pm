package Y::Context;

use strict;

sub new { bless do { $a = ""; \$a }, shift }

sub handled {
    my $self = shift;
    $$self = 1;
}

sub is_handled { $$_[0] }

1;

__END__


