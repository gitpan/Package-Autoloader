#!/usr/bin/perl -W -T
use strict;
use Test::Simple tests => 2;

package Basic_Test;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	ok(ref($_[0]) eq 'Package::Autoloader::Package',
		'T001: Convenience object of right type.');
};

my $rule = Package::Autoloader::Rule->new(sub{}, '', '');
ok(ref($rule) eq 'Package::Autoloader::Rule',
	'T002: Package::Autoloader::Rule works.');

exit(0);

