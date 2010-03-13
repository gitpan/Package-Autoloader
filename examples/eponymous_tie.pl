#!/usr/bin/perl -W -T
use strict;
use Carp qw();
use Package::Autoloader::Generator::Eponymous_Tie;

# eponymous means the same name as the package file base name,
# which is 'main' in this case (no package name set)
unless (-f 'main.dbm') {
	print STDERR "Script can only be run from the examples directory or wherever the main.dbm file is.\n";
}

use Package::Autoloader sub{eval shift}, sub {
	my $generator = Package::Autoloader::Generator::Eponymous_Tie->new($_[0]);
	$generator->prototypes();
	$_[0]->register_rule($generator, '=');
};

yn(!potentially_defined('hello_worlds'));
yn(potentially_defined('hello_world'));
yn(!defined(&hello_world));

hello_world();

yn(defined(&hello_world));
exit(0);

__END__
# this is now main.dbm was created:
use GDBM_File;
use Fcntl;
tie(my %sub_bodies, 'GDBM_File', __PACKAGE__.'.dbm',
	O_RDWR|O_CREAT, 0644);
$sub_bodies{'yn'} = q{print STDOUT ($_[0] ? 'Yes' : 'No'), "\n";};
$sub_bodies{'hello_world'} = q{print "Hello World.\n";};
$sub_bodies{'hello_world-prototype'} = q{};
$sub_bodies{'hola_mundo'} = q{print "Hola Mundo.\n";};
$sub_bodies{'salut_monde'} = q{print "Salut Monde.\n";};
