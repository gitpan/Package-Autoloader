use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Package::Autoloader',
	'VERSION_FROM'	=> 'lib/Package/Autoloader.pm',
	'AUTHOR'	=> 'Winfried Trumper <pub+perl@wt.tuxomania.net>',
	'LICENSE'	=> 'perl',
	'PREREQ_PM'	  => { 
		'parent' => 0.01,
		'mro' => 0.01,
		'Test::Simple' => 0.01,
	},
);
