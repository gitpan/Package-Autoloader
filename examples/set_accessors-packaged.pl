#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('::Set_Accessors_Demo', '*', 'set_');
};

my $obj = bless( {}, 'main');
$obj->set_world(1);

use Data::Dumper;
print STDERR Dumper($obj);

exit(0);