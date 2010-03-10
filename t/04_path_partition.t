#!/usr/bin/perl -W -T
use strict;
use Test::Simple tests => 12;

use Package::Autoloader::Path_Partition;
my @tests = (
	['Plausibility',
	'Abc::Def::Gij', sub {
		}, ['Abc::Def::Gij', 'Abc::Def::', 'Abc::', '']],
	['Single Method: first',
	'Abc::Def::Gij', sub {
		$_[0]->first('Xyz');
		}, ['Xyz', 'Abc::Def::Gij', 'Abc::Def::', 'Abc::', '']],
	['Single Method: first',
	'Abc::Def::Gij', sub {
		$_[0]->second('Xyz');
		}, ['Abc::Def::Gij', 'Xyz', 'Abc::Def::', 'Abc::', '']],
	['Single Method: third',
	'Abc::Def::Gij', sub {
		$_[0]->third('Xyz');
		}, ['Abc::Def::Gij', 'Abc::Def::', 'Abc::', 'Xyz', '']],
	['Single Method: last',
	'Abc::Def::Gij', sub {
		$_[0]->last('Xyz');
		}, ['Abc::Def::Gij', 'Abc::Def::', 'Abc::', '', 'Xyz']],
	['Single Method: not self',
	'Abc::Def::Gij', sub {
		$_[0]->not_self;
		}, ['Abc::Def::', 'Abc::', '']],
	['Single Method: not hierarchy',
	'Abc::Def::Gij', sub {
		$_[0]->not_hierarchy;
		}, ['Abc::Def::Gij', '']],
	['Single Method: not globally',
	'Abc::Def::Gij', sub {
		$_[0]->not_globally;
		}, ['Abc::Def::Gij', 'Abc::Def::', 'Abc::']],
	['All Methods: * (permutation 1)',
	'Abc::Def::Gij', sub {
		$_[0]->third('Xyz3');
		$_[0]->not_self;
		$_[0]->first('Xyz1');
		$_[0]->not_globally;
		$_[0]->second('Xyz2');
		$_[0]->not_hierarchy;
		$_[0]->last('Xyz4');
		}, ['Xyz1', 'Xyz2', 'Xyz3', 'Xyz4']],
	['All Methods: * (permutation 2)',
	'Abc::Def::Gij', sub {
		$_[0]->second('Xyz2');
		$_[0]->third('Xyz3');
		$_[0]->first('Xyz1');
		$_[0]->not_globally;
		$_[0]->not_hierarchy;
		$_[0]->last('Xyz4');
		$_[0]->not_self;
		}, ['Xyz1', 'Xyz2', 'Xyz3', 'Xyz4']],
	['All Methods: * (permutation 3)',
	'Abc::Def::Gij', sub {
		$_[0]->not_hierarchy;
		$_[0]->second('Xyz2');
		$_[0]->third('Xyz3');
		$_[0]->not_globally;
		$_[0]->last('Xyz4');
		$_[0]->not_self;
		$_[0]->first('Xyz1');
		}, ['Xyz1', 'Xyz2', 'Xyz3', 'Xyz4']],
	['All Methods: ** (permutation 1)',
	'Abc::Def::Gij', sub {
		$_[0]->not_self;
		$_[0]->not_hierarchy;
		$_[0]->second('Xyz2');
		$_[0]->third('Xyz3');
		$_[0]->not_hierarchy;
		$_[0]->not_globally;
		$_[0]->last('Xyz4');
		$_[0]->not_self;
		$_[0]->first('Xyz1');
		$_[0]->not_globally;
		}, ['Xyz1', 'Xyz2', 'Xyz3', 'Xyz4']],
);

sub array_equality($$) {
	return(0) unless (scalar(@{$_[0]}) == scalar(@{$_[1]}));
	for (my $i = 0; $i <= $#{$_[0]}; $i++) {
		return(0) unless ($_[0][$i] eq $_[1][$i]);
	}
	return(1);
}
foreach my $test (@tests) {
	my $pp = Package::Autoloader::Path_Partition->new($test->[1]);
	$test->[2]->($pp);
	ok(array_equality($pp->[0], $test->[3]), $test->[0]);
};
exit(0);