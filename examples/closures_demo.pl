#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('::Closures_Demo', '*', 'calc_(\d+)');
};

sub calc {
	my ($correction, $a, $b) = @_;
	return($a * $correction/100 + $b);
};

package Other;
use Package::Autoloader sub{eval shift};

print calc_5(7, 8), "\n"; # sets $correction = 5
exit(0);