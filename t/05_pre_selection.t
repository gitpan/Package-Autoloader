#!/usr/bin/perl -W -T
use strict;
use Test::Simple tests => 12;

use Package::Autoloader::Pre_Selection;
my $rules = Package::Autoloader::Pre_Selection->new();
ok(scalar(%$rules) == 0, 'T501: Starting with empty object.');

local($@);
eval q{$rules->register_rule([], 'Basic_Test*', 'asdf');};
ok($@, 'T502: Asterisk in package name is error.');
eval q{$rules->register_rule([], 'Basic_Test', 'asdf*');};
ok($@, 'T503: Asterisk in sub name is error.');

$rules->register_rules(427, ['a', 'b'], ['c', 'd']);
ok(exists($rules->{'a'}), 'T504: found 1st package name.');
ok(exists($rules->{'b'}), 'T505: found 2nd package name.');
ok(exists($rules->{'a'}{'c'}), 'T506: found 1st sub in 1st package name.');
ok(exists($rules->{'a'}{'d'}), 'T507: found 2nd sub in 1st package name.');
ok(exists($rules->{'b'}{'c'}), 'T508: found 1st sub in 1st package name.');
ok(exists($rules->{'b'}{'d'}), 'T509: found 2nd sub in 1st package name.');
delete($rules->{'a'});
delete($rules->{'b'});

$rules->register_rules(427, 'a', 'c');
$rules->register_rules(428, 'a', 'c');
ok(exists($rules->{'a'}), 'T510: found 1st package name.');
ok(exists($rules->{'a'}{'c'}), 'T511: found 1st sub in 1st package name.');
ok(scalar(@{$rules->{'a'}{'c'}}) == 2, 'T512: two rules.');

exit(0);