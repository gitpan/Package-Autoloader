#!/usr/bin/perl -W -T
use strict;
use Carp qw();
use DBI;
use Package::Autoloader::Generator::SQL_Table;
warn('See the manual page Package::Autoloader::Generator::SQL_Table');

use Package::Autoloader sub{eval shift};

my $dbh = DBI->connect('DBI:mysql:perlsub', *LOGIN*, *PASSWORD*) ||
	Carp::confess("connect: $DBI::errstr\n");

# another lexical variable visible to hello_world()
my $date = scalar(localtime(time()));

Package::Autoloader::again sub{eval shift}, sub {
	my $generator = Package::Autoloader::Generator::SQL_Table->new($_[0], $dbh);
	$_[0]->register_rule($generator, '=', $generator->matcher($dbh));
};

yn(potentially_defined('hello_worlds'));
yn(potentially_defined('hello_world'));
yn(defined(&hello_world));
#hello_world(7); also try this to see $date
hello_world();
yn(defined(&hello_world));
exit(0);
