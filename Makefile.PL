use ExtUtils::MakeMaker;
use Config;

require 5.005;

BEGIN {
    if ($Config{archname} eq 'darwin' &&
	$Config{osvers} <= 6.0 &&
	$] <= 5.00600) {
	warn <<__EOF__;
*** NOTE!!! ***
***
*** The combination of your system ($Config{archname} $Config{osvers}) and Perl ($])
*** is known to have problems running the tests of this module.  If you get
*** something like this from the test phase:
***
***    syntax error at code.pl line 0, near "use Devel::CallStack="
***
*** you have the problems.  You may choose to ignore the test failures and
*** install the module anyway.
***
__EOF__
    }
}

WriteMakefile(
	      NAME		=> 'Devel::CallStack',
	      VERSION_FROM	=> 'lib/Devel/CallStack.pm',
	      PREREQ_PM		=>
	      	{
		    'Test::More'	=> 0,
		},
	      PL_FILES		=> {},
	      dist		=> {
		  COMPRESS => 'gzip',
		  SUFFIX   => 'gz' },
	      );
