#!/usr/bin/perl -W -T
use strict;

package Parent_Class;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Lowered', '=', 'ATB_', undef, 1,
		qw(HELLO1  WORLD1));
};

package Child_Class;
BEGIN {our @ISA = ('Parent_Class')}; # more like 'use parent ...'
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Lowered', '=', 'ATB_', '^', undef,
		qw(HELLO2  WORLD2));
};

sub yn($) { print STDERR ($_[0] ? 'Yes' : 'No'), "\n"; };

yn(defined(&ATB_HELLO1));
yn(potentially_defined('ATB_HELLO1'));

print STDOUT 'Symbolic Attribute Names: ', ATB_HELLO2, ATB_WORLD2, "\n";

exit(0);
