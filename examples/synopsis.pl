use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
# you consume rules ----^=============^  ^====^-- you define rules

	my $generator = q{
		my $greet = substr($sub_name, 6); #magic
		print STDERR "Generating subroutine '$sub_name'.\n";
 		return(qq{print 'Hello $greet\n'});
# subroutine body text ---^====================^
	};

	$_[0]->register_rule($generator, '::*', 'hola_');
# wildcard ------------------------------^===^  ^=====^-- sub name
	$_[0]->register_rule($generator, '=', 'salut_');

	my $yn = q{
 		return(q{print STDERR ($_[0] ? 'Yes' : 'No'), "\n";});
	};
	$_[0]->register_rule($yn, '*', 'yn');
};


package Synopsis::Desc1;
use Package::Autoloader sub{eval shift};

yn(!defined(&hola__mundo));
yn(potentially_defined('hola__mundo'));
hola__mundo();
yn(defined(&hola__mundo));


package sisponyS::Desc2;
our @ISA = ('Synopsis');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'sisponyS::Desc2');

yn(!potentially_defined('hola__mundo'));
yn(!defined(&salut_monde));
yn(!potentially_defined('salut_monde'));
yn(!$obj->can('salut_monde'));
yn($obj->potentially_can('salut_monde'));

$obj->salut_monde();

yn(!defined(&sisponyS::Desc2::salut_monde));
yn(!defined(&Synopsis::Desc1::salut_monde));
yn(defined(&Synopsis::salut_monde));
