#!/usr/bin/perl -W
use strict;
use Test::Simple tests => 35;

package Basic_Test;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub {
	ok(ref($_[0]) eq 'Package::Autoloader::Package',
		'T101: Convenience object of right type.');
	my $i = 0;
	my $generator = sub { 
		$i += 7;
		return(qq{sprintf('$i%s', '$_[1]')});
	};
	$_[0]->register_rule($generator, '+', 'tfrv1');
	$_[0]->register_rule($generator, '::*', 'tfrv2');
	$_[0]->register_rule($generator, '+', 'tfrv3');
#	$_[0]->potentially_candef;
};

ok(defined(&AUTOLOAD), 'T102: Got AUTOLOAD.');
ok(!defined(&potentially_defined), 'T103: No potentially_defined');
ok(!defined(&potentially_defined), 'T104: No potentially_defined');

ok(!exists(&tfrv1), 'T105: tfrv1 exists (not yet) in defining package.');
ok(!defined(&tfrv1), 'T106: tfrv1 defined (not yet) in defining package.');
ok((tfrv1() eq '7tfrv1'), 'T107: tfrv1 created in defining package.');

package Basic_Test::P2;
use Test::Simple;
use Package::Autoloader sub{eval shift}, sub{
	$_[0]->potentially_candef;
};

ok(defined(&AUTOLOAD), 'T201: Got AUTOLOAD.');
ok(defined(&potentially_defined), 'T202: Defined potentially_defined via ->potentially_candef.');
ok(defined(&potentially_can), 'T203: Defined potentially_can via ->potentially_candef.');

ok(!exists(&tfrv2), 'T204: tfrv2 exists (not yet) in descendant package.');
ok(!defined(&tfrv2), 'T205: tfrv2 defined (not yet) in descendant package.');
ok(potentially_defined('tfrv2'),
	'T206: tfrv2 potentially defined in descendant package.');
ok(!potentially_defined('tfrv1'),
	'T207: tfrv1 not potentially defined in descendant package.');
ok((tfrv2() eq '14tfrv2'), 'T208: tfrv2 created separately in descendant package.');

BEGIN { $Package::Autoloader::Package::CANDEF=1; }
package tseT_cisaB::P3;
use strict;
use Test::Simple;
our @ISA = ('Basic_Test');
use Package::Autoloader sub{eval shift};
BEGIN { $Package::Autoloader::Package::CANDEF=0; }

ok(defined(&AUTOLOAD), 'T301: Got AUTOLOAD.');
ok(defined(&potentially_defined), 'T302: defined potentially_defined via package global.');
ok(defined(&potentially_can), 'T303: defined potentially_can via package global.');

ok(!exists(&tfrv2), 'T304: tfrv2 exists not in subclass package.');
ok(!defined(&tfrv2), 'T305: tfrv2 not defined in subclass package.');
ok(!potentially_defined('tfrv2'), 'T306: tfrv2 not potentially defined in subclass package.');

my $obj = bless( \(my $o = 0), 'tseT_cisaB::P3');
ok($obj->can('tfrv1'), 'T307: Can tfrv1 in subclass package (through inheritance).');
ok($obj->potentially_can('tfrv1'), 'T308: potentially can tfrv1 in subclass package (through inheritance).');

ok(!$obj->can('tfrv2'), 'T309: Can\'t (not yet) tfrv2 in subclass package.');
ok(!$obj->potentially_can('tfrv2'), 'T310: potentially can\'t tfrv2 in subclass package.');

ok(!exists(&tfrv3), 'T311: tfrv3 exists not yet in subclass package.');
ok(!defined(&tfrv3), 'T312: tfrv3 defined not yet in subclass package.');
ok(!potentially_defined('tfrv3'), 'T313: tfrv3 not yet potentially defined in subclass package.');

ok(($obj->tfrv3() eq '21tfrv3'), 'T314: tfrv3 inherited in subclass package.');

ok(!exists(&tfrv3), 'T401: tfrv3 exists (not) in subclass package.');
ok(!defined(&tfrv3), 'T402: tfrv3 defined (not) in subclass package.');

ok(!exists(&Basic_Test::P2::tfrv3), 'T403: tfrv3 exists (not) in descendant package.');
ok(!defined(&Basic_Test::P2::tfrv3), 'T404: tfrv3 defined (not) in descendant package.');

ok(exists(&Basic_Test::tfrv3), 'T405: tfrv3 exists in defining package.');
ok(defined(&Basic_Test::tfrv3), 'T406: tfrv3 defined in defining package.');

exit(0);
