package Devel::CallStack;

use strict;

use vars qw($VERSION
	    $Depth $Full $Reverse $Stdout $Stderr $Out
	    $Import
	    %Cumul);

$VERSION = '0.14';
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
    $Out = "callstack.out" unless defined $Out || $Stdout;
    $Import++; # Import was a success.
}

sub END {
    if ($Import) {
	my $fh;
	if ($Stdout) {
	    $fh = select STDOUT;
	} elsif ($Stderr) {
	    $fh = select STDERR;
	} elsif (defined $Out) {
	    unless (open(OUT, ">$Out")) {
		die qq[Devel::CallStack::END: failed to open "$Out" for writing: $!\n];
	    }
	    $fh = select OUT;
	}
	for my $s (sort keys %Cumul) {
	    my $d = ($s =~ tr/,/,/) + 1;
	    print "$s $d $Cumul{$s}\n";
	}
	select $fh;
    }
}

package DB;

use strict;

sub DB { }

use vars qw($Full $Depth $Reverse %Cumul);

*Depth   = \$Devel::CallStack::Depth;
*Full    = \$Devel::CallStack::Full;
*Reverse = \$Devel::CallStack::Reverse;
*Cumul   = \%Devel::CallStack::Cumul;

sub sub {
    if (my ($p, $s) = ($DB::sub =~ /^(.+)::(.+)/)) {
	my @s;
	if ($Full) {
	    if (my ($f, $l) = ($DB::sub{$DB::sub} =~ /^(.+):(\d+)/)) {
		@s = ( "$f:$l:$p:$s" );
		for (my $i = 0; @s < $Depth; $i++) {
		    my @c = caller($i);
		    last unless @c;
		    push @s, "$c[1]:$c[2]:$c[3]";
		}
	    }
	} else {
	    @s = ( $DB::sub );
	    for (my $i = 0; @s < $Depth; $i++) {
		my @c = caller($i);
		last unless @c;
		push @s, $c[3];
	    }
	}
	$Cumul{
	       join ",", $Reverse ? @s : reverse @s # Ironic, no?
	      }++;
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
times each calling stack is being called.  By default the results are
written to a file called F<callstack.out>.

B<NOTE:> counting the callstacks is a very heavy operation which slows
down the execution of your code easily ten-fold or more: do not
attempt any other code timing or profiling at the same time.  The
gathered information is useful in conjunction with other profiling
tools such as C<Devel::DProf>.

=head1 MOTIVATION

I got frustrated by C<Devel::DProf> results that looked not unlike this:

  Total Elapsed Time = 1.892063 Seconds
    User+System Time = 1.742063 Seconds
  Exclusive Times
  %Time ExclSec CumulS #Calls sec/call Csec/c  Name
   13.8   0.241  0.426   2170   0.0001 0.0002  Foo::_id
   10.3   0.181  0.181   1747   0.0001 0.0001  Foo::Map::has
   9.18   0.160  0.434      3   0.0532 0.1448  main::BEGIN
   8.21   0.143  0.143   5205   0.0000 0.0000  Foo::Map::_has
   7.46   0.130  0.611      1   0.1299 0.6112  Foo::Map::new
   ...

I obviously needed to try cutting down the number of C<Foo::_id> calls
(not to mention the number of C<Foo::Map::_has> and C<Foo::Map::_has>
calls), but the problem was that C<Foo::_id> was being called from
multiple places, there were more than one possible "hot path" that
I needed to locate and "cool down".

=head1 EXAMPLE

For this file, F<code.pl>:

    sub foo { bar(@_) }
    sub bar { zog(@_) if $_[0] % 7 }
    sub zog { }
    for (my $i = 0; $i < 1e3; $i++) {
	$i % 5 ? foo($i) : bar($i);
    }

running C<perl -d:CallStack code.pl> will result in:

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

Using callstack depth two for for our example:

    main::bar 1 200
    main::bar,main::zog 2 857
    main::foo 1 800
    main::foo,main::bar 2 800

Using the depth of one (or zero) gives the number of times each
subroutine was called:

    main::bar 1 1000
    main::foo 1 800
    main::zog 1 857

=head2 Reverse

By default the callstacks go from left to right, that is, the callers
are on the left and the callees are on the right.  With the C<reverse>
parameter you can flip the order, which may fit your brain better.
For our example:

    main::bar 1 200
    main::bar,main::foo 2 800
    main::foo 1 800
    main::zog,main::bar 2 171
    main::zog,main::bar,main::foo 3 686

=head2 Full

By default only the names of the called subroutines are recorded.
To record also the filename and (calling) line in the file, use the
C<full> parameter:

   perl -d:CallStack=full

The filename and the linenumber are prepended to the subname,
for our example:

    code.pl:1:main:foo 1 800
    code.pl:2:main:bar 1 200
    code.pl:5:main::bar,code.pl:3:main:zog 2 171
    code.pl:5:main::foo,code.pl:1:main::bar,code.pl:3:main:zog 3 686
    code.pl:5:main::foo,code.pl:2:main:bar 2 800

=head2 Combining parameters

To use several parameters at the same time, combine the parameters by
using a comma:

   perl -d:CallStack=3,out=my.out,full

=head1 KNOWN PROBLEMS

On Jaguar (X.2.6) with the default Perl (5.6.0) the test suite refuses
to run due to mysterious problems.  The Makefile.PL will warn of this.

=head1 ACKNOWLEDGEMENTS

SE<eacute>bastien Aperghis-Tramoni for bravely testing the code in Jaguar.

=head1 SEE ALSO

L<perlfunc/caller>, L<Devel::CallerItem>, L<Devel::DumpStack>,
L<Devel::StackTrace>, for alternative views of the call stack;
L<Devel::DProf>, L<Devel::Cover>, L<Devel::SmallProf> for time-based
profiling.

=head1 AUTHOR AND COPYRIGHT

Jarkko Hietaniemi <jhi@iki.fi> 2004

=head1 LICENSE

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
