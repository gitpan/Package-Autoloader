#!/usr/bin/perl -W
use strict;
use Test::Simple tests => 4;

package Basic_Test;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	my $i = 0;
	my $generator = sub { 
		$i += 7;
		return(qq{sprintf('$i%s', '$_[1]')});
	};
	$_[0]->package_hierarchy_rule($generator, 'tfrv1');
	$_[0]->isa_listed_rule($generator, 'tfrv2');
};


ok((tfrv1() eq '7tfrv1'), 'Available in own package.');

package Basic_Test::P2;
use Test::Simple;
use Package::Autoloader sub{eval shift};

ok((tfrv1() eq '14tfrv1'), 'Available in descendant package.');


package Basic_Test::P3;
use strict;
use Test::Simple;
our @ISA = ('Basic_Test');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'Basic_Test::P3');
ok($obj->can('tfrv2'), 'Can2 in subclass package.');
ok(($obj->tfrv2() eq '21tfrv2'), 'Available in subclass package.');

exit(0);
