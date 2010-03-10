#!/usr/bin/perl -W -T
use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->register_rule('::Export', '::*', ['hello_world']);
	$_[0]->register_rule('::Hello_Anything', '=', 'salut_');
};

sub hello_world { print "Hello World.\n"; }


package Synopsis::Desc1;
use Package::Autoloader sub{eval shift};

yn(!defined(&hello_world));
yn(potentially_defined('hello_world'));

hello_world(); # first rule

yn(defined(&hello_world));


package sisponyS::Desc2;
our @ISA = ('Synopsis');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'sisponyS::Desc2');

yn(!potentially_defined('hello_world'));
yn(!defined(&salut_monde));
yn(!potentially_defined('salut_monde'));
yn($obj->potentially_can('salut_monde')); # no autovivification
yn($obj->can('salut_monde')); # with autovivification

$obj->salut_monde(); # second rule

yn(!defined(&sisponyS::Desc2::salut_monde));
yn(!defined(&Synopsis::Desc1::salut_monde));
yn(defined(&Synopsis::salut_monde));

package main;
use Package::Autoloader sub{eval shift}, sub {
	my $yn = q{
 		return(q{print STDOUT ($_[0] ? 'Yes' : 'No'), "\n";});
	};
	$_[0]->register_rule($yn, '*', 'yn');
};

exit(0);