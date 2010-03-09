use ExtUtils::MakeMaker;

WriteMakefile(
	'NAME'		=> 'Package::Autoloader',
	'VERSION_FROM'	=> 'lib/Package/Autoloader.pm',
	'AUTHOR'	=> 'Winfried Trumper <pub+perl@wt.tuxomania.net>',
	'LICENSE'	=> 'perl',
	'PREREQ_PM'	  => { 
		'parent' => 0.00,
		'mro' => 0.00,
		'Test::Simple' => 0.00,
	},
);
