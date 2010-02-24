package Synopsis::EX1;
use strict;
use Package::Autoloader sub{eval shift};

my $generator = sub { 
	return(qq{print 'Hello }.substr($_[2], 6).qq{.\n'});
};
Package::Autoloader::package_hierarchy_rule
	($generator, 'Synopsis::', 'hello_');

hello_world();


package Synopsis::EX2;
use strict;
use Package::Autoloader sub{eval shift};

hello_bello();
