sub perl {
    my $perl = $^X =~ m/\s/ ? qq{"$^X"} : $^X;
    return $perl;
}

sub arg {
    return qq["$_[0]"];
}

sub callstack {
    my $perl = perl();
    my $arg  = arg(@_ == 1 ? "-d:CallStack=$_[0]" : "-d:CallStack");
    my $code = @_ == 2 ? $_[1] : "code.pl";
    print "# $perl $arg $code\n";
    return system("$perl $arg $code") == 0;
}

sub file_equal {
    my ($fn1, $fn2) = @_;
    my $equal = 1;
    if (open(my $fh1, $fn1)) {
	if (open(my $fh2, $fn2)) {
	    while (defined(my $fl1 = <$fh1>) && defined(my $fl2 = <$fh2>)) {
		$fl1 =~ s/\r?\n?$//;
		$fl2 =~ s/\r?\n?$//;
		if ($fl1 ne $fl2) {
		    $equal = 1;
		    last;
		}
	    }
	} else {
	    return undef;
	}
    } else {
	return undef;
    }
    return 0 unless $equal;
}

1;
