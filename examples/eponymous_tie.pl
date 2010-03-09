#!/usr/bin/perl -W -T
use strict;
use Carp qw();
use SDBM_File;
use Package::Autoloader::Generator::Eponymous_Tie;

use Package::Autoloader sub{eval shift};

# eponymous means the same name as the package file base name,
# which is 'main' in this case (no package name set)
Package::Autoloader::again sub{eval shift}, sub {
	my $generator = Package::Autoloader::Generator::Eponymous_Tie->new($_[0]);
	$_[0]->register_rule($generator, '=', $generator->matcher($_[0]));
};

yn(potentially_defined('hello_worlds'));
yn(potentially_defined('hello_world'));
yn(defined(&hello_world));
hello_world();
yn(defined(&hello_world));
exit(0);

__END__
# thisis now main.pag was created:
use Fcntl;
tie(my %sub_bodies, 'SDBM_File', __PACKAGE__, O_RDWR|O_CREAT, 0640);
$sub_bodies{'yn'} = q{print STDOUT ($_[0] ? 'Yes' : 'No'), "\n";};
$sub_bodies{'hello_world'} = q{print "Hello World.\n";};
$sub_bodies{'hola_mundo'} = q{print "Hola Mundo.\n";};
$sub_bodies{'salut_monde'} = q{print "Salut Monde.\n";};
