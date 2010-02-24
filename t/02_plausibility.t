#!/usr/bin/perl -W
use strict;
use Test::Simple tests => 3;

package Basic_Test::P1;
use Test::Simple;
use Package::Autoloader sub{eval shift};

my $i = 0;
my $generator = sub { 
	$i += 7;
	return(qq{ return('$i$_[2]'); });
};

Package::Autoloader::package_hierarchy_rule
	($generator, 'Basic_Test::', 'tfrv1');
Package::Autoloader::isa_listed_rule
	($generator, 'Basic_Test::P1', 'tfrv2');

ok((tfrv1() eq '7tfrv1'), 'Available in own package.');


package Basic_Test::P2;
use Test::Simple;
use Package::Autoloader sub{eval shift};

ok((tfrv1() eq '14tfrv1'), 'Available in neighbour package.');


package Basic_Test::P3;
use strict;
use Test::Simple;
our @ISA = ('Basic_Test::P1');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'Basic_Test::P3');
ok(($obj->tfrv2() eq '21tfrv2'), 'Available in subclass package.');

exit(0);
