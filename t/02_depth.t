use Test::More tests => 4;

BEGIN {
    chdir "t" if -d "t";
    use lib qw(. ../lib);
    require "./util.pl";
}

sub cleanup {
    1 while unlink("callstack.out");
}

cleanup();
if (callstack("depth=2")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs2a.out"));
    } else {
	die "failed to create callstack.out\n";
    }
} else {
    die "$0: running perl -d:CallStack failed: ($?)\n";
}

cleanup();
if (callstack("2")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs2a.out"));
    } else {
	die "failed to create callstack.out\n";
    }
} else {
    die "$0: running perl -d:CallStack failed: ($?)\n";
}

cleanup();
if (callstack("1")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs2b.out"));
    } else {
	die "failed to create callstack.out\n";
    }
} else {
    die "$0: running perl -d:CallStack failed: ($?)\n";
}

cleanup();
if (callstack("0")) {
    if (-e "callstack.out") {
	ok(file_equal("callstack.out", "cs2c.out"));
    } else {
	die "failed to create callstack.out\n";
    }
} else {
    die "$0: running perl -d:CallStack failed: ($?)\n";
}

END {
    cleanup();
}

