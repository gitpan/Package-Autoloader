#!/usr/bin/perl -W -T
use strict;

# this works only in the examples directory
use lib '.';

package from_directory;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('From_Directory', '=', '');
};

hello_world();
exit(0);
