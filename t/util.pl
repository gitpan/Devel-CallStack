use File::Spec;

my $perl;

sub perl {
    unless (defined $perl) {
	my $Makefile = File::Spec->catfile(File::Spec->updir, "Makefile");
	if (open(MAKEFILE, $Makefile)) {
	    while (<MAKEFILE>) {
		if (/^PERL = (.+)/) {
		    $perl = $1;
		    last;
		}
	    }
	    close(MAKEFILE);
	}
	unless (defined $perl) {
	    $perl = $^X;
	    $perl = $perl =~ m/\s/ ? qq{"$perl"} : $perl;
	}
	print "# perl = $perl\n";
    }
    return $perl;
}

sub arg {
    return qq["$_[0]"];
}

sub callstack {
    my $perl = perl();
    my $lib  = arg("-I../lib");
    my $arg  = arg(@_ == 0 ? "-d:CallStack" : "-d:CallStack=$_[0]");
    my $code = @_ == 2 ? $_[1] : "code.pl";
    my $cmd = "$perl $lib $arg $code";
    print "# $cmd\n";
    if (system($cmd) == 0) {
	return 1;
    } else {
	use Cwd;
	my $cwd = getcwd();
	die qq[$0: running '$cmd' failed: ($?) (cwd $cwd)\n];
    }
}

sub file_equal {
    my ($fn1, $fn2) = @_;
    my $equal = 1;
    if (open(my $fh1, $fn1)) {
	if (open(my $fh2, $fn2)) {
	    while (defined(my $fl1 = <$fh1>) && defined(my $fl2 = <$fh2>)) {
		$fl1 =~ s/\r?\n?$//;
		$fl2 =~ s/\r?\n?$//;
		if (lc($fl1) ne lc($fl2)) {
		    $equal = 0;
		    last;
		}
	    }
	    close($fh2);
	} else {
	    return undef;
	}
	close($fh1);
    } else {
	return undef;
    }
    return $equal;
}

1;
