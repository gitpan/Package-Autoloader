#!/usr/bin/perl -W
use strict;
use Test::Simple tests => 7;

package Basic_Test;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	my $i = 0;
	my $generator = sub { 
		$i += 7;
		return(qq{sprintf('$i%s', '$_[1]')});
	};
	$_[0]->register_rule($generator, 'tfrv1');
};


ok((tfrv1() eq '7tfrv1'), 'Available in own package.');

package Basic_Test::P2;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub{
	$_[0]->potentially_candef;
};

ok(!defined(&tfrv1), 'Defined (not) in descendant package.');
ok(potentially_defined('tfrv1'), 'Potential Defined in descendant package.');
ok((tfrv1() eq '14tfrv1'), 'Available in descendant package.');


package Basic_Test::P3;
use strict;
use Test::Simple;
our @ISA = ('Basic_Test');
use Package::Autoloader sub{eval shift}, sub{
	$_[0]->potentially_candef;
};

my $obj = bless( \(my $o = 0), 'Basic_Test::P3');
ok(!$obj->can('tfrv2'), 'Can (not) in subclass package.');
ok(!$obj->potentially_can('tfrv2'), 'Potential Can in subclass package.');
ok(($obj->tfrv1() eq '7tfrv1'), 'Inherited in subclass package.');

exit(0);
