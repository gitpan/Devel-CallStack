use Test::More tests => 1;

BEGIN {
    chdir "t" if -d "t";
    use lib qw(. ../lib);
    require "./util.pl";
}

sub cleanup {
    1 while unlink("callstack.out");
    1 while unlink("out.out");
}

cleanup();
if (callstack("out=out.out")) {
    if (-e "out.out") {
	ok(file_equal("out.out", "cs1.out"));
    } else {
	die "failed to create callstack.out\n";
    }
} else {
    die "$0: running perl -d:CallStack failed: ($?)\n";
}

END {
    cleanup();
}

