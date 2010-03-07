#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('Closures_Demo', '*', 'calc_');
};

print calc_5(7, 8), "\n";
exit(0);
