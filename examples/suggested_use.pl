#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('::Suggested_Use', '=');
};

sub yn($) { print STDERR ($_[0] ? 'Yes' : 'No'), "\n"; };

yn(!defined(&anything));
yn(potentially_defined('anything')); # dangerous!

print STDOUT uri_escape('Hello World.'), "\n";

my $uri_base = bless(\(my $o = 'www.perl.org'), 'main');
$uri_base->scheme('http');
print STDOUT "URI: $$uri_base\n";

confess('Bye World.');

exit(0);