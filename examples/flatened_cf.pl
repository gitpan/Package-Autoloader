#!/usr/bin/perl -W -T
use strict;

package Parent_Class;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Flatened', '=', 'ATB_', undef, 1,
		qw(HELLO1 65 WORLD1 97));
};

package Child_Class;
BEGIN {our @ISA = ('Parent_Class')}; # more like 'use parent ...'
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Flatened', '=', 'ATB_', '^', undef,
		qw(HELLO2 333  WORLD2 12));
};

sub yn($) { print STDERR ($_[0] ? 'Yes' : 'No'), "\n"; };

yn(defined(&ATB_HELLO1));
yn(potentially_defined('ATB_HELLO1'));

print STDOUT 'Symbolic Attribute Names: ', ATB_HELLO2, ATB_WORLD2, "\n";

exit(0);
