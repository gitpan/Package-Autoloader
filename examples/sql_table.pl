#!/usr/bin/perl -W -T
use strict;
use Carp qw();
use DBI;
use Package::Autoloader sub{eval shift};
use Package::Autoloader::Generator::SQL_Table;
warn('See the manual page Package::Autoloader::Generator::SQL_Table');


my $dbh = DBI->connect('DBI:mysql:perlsub', *LOGIN*, *PASSWORD*) ||
	Carp::confess("connect: $DBI::errstr\n");

# another lexical variable visible to hello_world()
my $date = scalar(localtime(time()));

{
	my $pkg = Package::Autoloader->new(sub{eval shift});
	my $generator = Package::Autoloader::Generator::SQL_Table->new($pkg, $dbh);
	$generator->prototypes();
	$pkg->register_rule($generator, '=');
};

yn(potentially_defined('hello_worlds'));
yn(potentially_defined('hello_world'));
yn(defined(&hello_world));
#hello_world(7); also try this to see $date
hello_world();
yn(defined(&hello_world));
exit(0);