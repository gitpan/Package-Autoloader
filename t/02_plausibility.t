#!/usr/bin/perl -W -T
use strict;
use Test::Simple tests => 10;

package Basic_Test1;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	ok(ref($_[0]) eq 'Package::Autoloader::Package',
		'T001: Convenience object of right type.');
	ok($_[0]->name eq 'Basic_Test1',
		'T002: Correct name.');
	ok(ref($_[0]->search) eq 'Package::Autoloader::Path_Partition',
		'T003: Search object of right type.');
};
local($@);
eval qq{hello_world();};
ok($@ =~ m/Package::Autoloader/, 'T004: It\'s us who complains.');

package Basic_Test2;
use Test::Simple;

local($@);
eval q{Package::Autoloader->import(sub{eval shift}, []);};
ok($@, 'T004: 2nd argument must be code reference.');

package Basic_Test3;
use Test::Simple;
use Package::Autoloader;

my $a = time;
{
	my $pkg = Package::Autoloader->new(sub{eval shift});
	my $code = 'return($a)';
	my $b = $pkg->transport(\$code);
	ok($a = $b, 'T005: Access lexical via new');
	local($@);
	eval q{$pkg->transport($code);};
	ok($@, 'T006: Normal scalar for transport is error.');
	eval q{$pkg->transport();};
	ok($@, 'T007: Empty transport is error.');
}

my $found = Package::Autoloader::find_generator(['*']);
ok(!defined($found), 'T008: Impossible ISA value');

use Package::Autoloader::Rule;
my $rule = Package::Autoloader::Rule->new(sub{}, '', '');
ok(ref($rule) eq 'Package::Autoloader::Rule',
	'T009: Package::Autoloader::Rule works.');

exit(0);