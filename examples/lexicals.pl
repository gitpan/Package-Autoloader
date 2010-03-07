#!/usr/bin/perl -W -T
use strict;

package Synopsis;
use Package::Autoloader sub{eval shift};

my $NOW = time;
Package::Autoloader::assemble sub {
	$_[0]->store({'NOW' => \$NOW}, '::*', '$');
}

package Synopsis::Ex1;
use Package::Autoloader sub{eval shift};

my $NOW;
Package::Autoloader::assemble sub {
	$_[0]->assign('NOW' => $NOW);
}

print "NOW: $$NOW\n";

exit(0);
