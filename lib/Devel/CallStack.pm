package Devel::CallStack;

use strict;

use vars qw($VERSION
	    $Depth $Full $Reverse $Stdout $Stderr $Out
	    $Import %Cumul $Pred %Pred %Succ);

$VERSION = '0.10';
$Depth = 1e9;
$Import = 0;

sub import {
    my $class = shift;
    for my $i (@_) {
	if ($i =~ /^(?:depth=)?(\d+)$/) {
	    $Depth = $1;
	} elsif ($i eq 'full') {
	    $Full = 1;
	} elsif ($i eq 'reverse') {
	    $Reverse = 1;
	} elsif ($i eq 'stdout') {
	    $Stdout = 1;
	} elsif ($i eq 'stderr') {
	    $Stderr = 1;
	} elsif ($i =~ /^out=(.+)/) {
	    $Out = $1;
	} else {
	    die "Devel::CallStack::import: '$i' unknown\n";
	}
    }
    %Cumul = (); # Otherwise we get the import() call stack captured, too.
    %Pred = %Succ = ();
    undef $Pred;
    $Out = "callstack.out" unless defined $Out || $Stdout;
    $Import++;
}

sub END {
    if ($Import) {
	if ($Stdout) {
	    select STDOUT;
	} elsif ($Stderr) {
	    select STDERR;
	} elsif (defined $Out) {
	    unless (open(OUT, ">$Out")) {
		die qq[Devel::CallStack::END: failed to open "$Out" for writing: $!\n];
	    }
	    select OUT;
	}
	for my $s (sort keys %Cumul) {
	    my $d = ($s =~ tr/,/,/) + 1;
	    print "$s $d $Cumul{$s}\n";
	}
    }
}

package DB;

use strict;

sub DB { }

sub sub {
    if (my ($p, $s) = ($DB::sub =~ /^(.+)::(.+)/)) {
	my @s;
	if ($Devel::CallStack::Full) {
	    my ($f, $l) = ($DB::sub{$DB::sub} =~ /^(.+):(\d+)/);
	    @s = ( "$f:$l:$p:$s" );
	} else {
	    @s = ( $DB::sub );
	}
	for (my $i = 0; @s < $Devel::CallStack::Depth; $i++) {
	    my @c = caller($i);
	    last unless @c;
	    if ($Devel::CallStack::Full) {
		$c[3] =~ s/^(.+):://;
		$c[0] = $1;
		push @s, "$c[1]:$c[2]:$c[0]::$c[3]";
	    } else {
		push @s, $c[3];
	    }
	}
	$Devel::CallStack::Cumul{ join ",", $Devel::CallStack::Reverse ? @s : reverse @s }++;
    }
    no strict 'refs';
    &{$DB::sub}(@_);
}

1;
__END__
=pod

=head1 NAME

Devel::CallStack - record the subroutine calling stacks

=head1 SYNOPSIS

    perl -d:CallStack ...

=head1 DESCRIPTION

The Devel::CallStack records the subroutine calling stacks, how many
times each calling stack is being called.  B<NOTE:> this is a very
heavy operation which slows down the execution of your code easily
ten-fold or more: do not attempt any other code profiling at the same
time.  The gathered information is useful in conjunction with other
profiling tools such as C<Devel::DProf>.  By default the results are
written to a file called F<callstack.out>.

=head1 EXAMPLE

For this file, F<test.pl>:

    sub foo { bar(@_) }
    sub bar { zog(@_) if $_[0] % 7 }
    sub zog { }
    for (my $i = 0; $i < 1e3; $i++) {
	$i % 5 ? foo($i) : bar($i);
    }

running C<perl -d:CallStack test.pl> will result in:

    main::bar 1 200
    main::bar,main::zog 2 171
    main::foo 1 800
    main::foo,main::bar 2 800
    main::foo,main::bar,main::zog 3 686

Meaning that C<main::bar> was called 200 times, which makes sense
since every fifth call out of 1000 should have been made to bar().
The callstack C<main::bar,main::zog> was reached 171 times, which is
the number of integers between 0 and 999 (inclusive) that are evenly
divisible both by five and seven.  The numbers in the second column
are the callstack depths.

=head1 PARAMETERS

Parameters are given in the command line after the C<-d:Callstack>
and a C<=>:

    perl -d:CallStack=...

The available parameters are listed in the following.

=head2 Results

The results are written by default to a file called F<callstack.out>.
This can be changed either with

    perl -d:CallStack=out=filename

or

    perl -d:CallStack=out=stdout
    perl -d:CallStack=out=stderr

which will output to a file called F<filename> or the standard output
or the standard error, respectively.

=head2 Depth

By default the calling stacks are walked all the way back to the
beginning.  This may be very expensive if the calling stacks are deep.
To limit the number of frames walked back, supply the C<depth> argument:

   perl -d:CallStack=depth=N

or just

   perl -d:CallStack=N

Using the depth of one (or zero) gives the number of times each
subroutine was called.

=head2 Full

By default only the names of the called subroutines are recorded.
To record also the filename and (calling) line in the file, use the
C<full> parameter:

   perl -d:CallStack=full

The filename and the linenumber are prepended to the subname,
for our example:

    test.pl:1:main:foo 1 800
    test.pl:2:main:bar 1 200
    test.pl:5:main::bar,test.pl:3:main:zog 2 171
    test.pl:5:main::foo,test.pl:1:main::bar,test.pl:3:main:zog 3 686
    test.pl:5:main::foo,test.pl:2:main:bar 2 800

=head2 Reverse

By default the callstacks go from left to right, that is, the callers
are on the left and the callees are on the right.  With the C<reverse>
parameter you can flip the order.  For our example:

    main::bar 1 200
    main::bar,main::foo 2 800
    main::foo 1 800
    main::zog,main::bar 2 171
    main::zog,main::bar,main::foo 3 686

=head2 Combining parameters

To use several parameters at the same time, combine the parameters by
using a comma:

   perl -d:CallStack=3,out=my.out,full

=head1 SEE ALSO

L<perlfunc/caller>, L<Devel::CallerItem>, L<Devel::DumpStack>,
L<Devel::StackTrace>.

=head1 AUTHOR AND COPYRIGHT

Jarkko Hietaniemi <jhi@iki.fi>

=cut
