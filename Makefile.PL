use ExtUtils::MakeMaker;

require 5.005;

WriteMakefile(
	      NAME            => 'Devel::CallStack',
	      VERSION_FROM    => 'lib/Devel/CallStack.pm',
	      PREREQ_PM	      =>
	      	{
		    'Test::More'	=> 0,
		},
	      );
