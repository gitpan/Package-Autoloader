#!/usr/bin/perl -W -T
use strict;
use Test::Simple tests => 8;

package Parent_Class;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Enumerated', '=', 'ATB1_', undef, 1,
		qw(FOO1  BAR1));
	$_[0]->instant_cf('::Enumerated', '::*', 'ATB5_', undef,  1,
		 qw(FOO3  BAR4));
	$_[0]->instant_cf('::Random', '::*', 'ATB5_', undef,  1,
		 qw(FOO3  BAR4));
	$_[0]->instant_cf('::Random', '=', 'ATB2_', undef, undef,
		qw(FOO1  BAR1));
	$_[0]->instant_cf('::Lowered', '=', 'ATB3_', undef, undef,
		qw(FOO1  BAR1));
	$_[0]->instant_cf('::Flatened', '=', 'ATB4_', undef, undef,
		FOO1 => 99, BAR1 => 723);
};

ok(ATB1_BAR1 == 1, 'T102: value ATB1_BAR1');
ok(length(ATB2_BAR1) == 8, 'T104: value ATB2_BAR1');
ok(ATB3_BAR1 eq 'atb3_bar1', 'T106: value ATB3_BAR1');
ok(ATB4_BAR1 == 723, 'T108: value ATB4_BAR1');

package Child_Class;
use Test::Simple;
BEGIN {our @ISA = ('Parent_Class')}; # more like 'use parent ...'
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Enumerated', '=', 'ATB1_', '^', undef,
		qw(FOO2  BAR2));
};

ok(ATB1_BAR1 == 1, 'T110: value ATB1_BAR1');
ok(ATB1_BAR2 == 3, 'T112: value ATB1_BAR2');

package Parent_Class::Branch;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->instant_cf('::Enumerated', '=', 'ATB1_', '::', undef,
		qw(FOO2  BAR2));
	$_[0]->instant_cf('::Enumerated', '=', 'ATB5_', '::', undef);
};

ok(ATB5_BAR4 == 1, 'T110: value ATB5_BAR4');
ok(ATB1_BAR2 == 1, 'T112: value ATB1_BAR2');

exit(0);
