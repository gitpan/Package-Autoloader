use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	my $generator = q{
		my $greet = substr($sub_name, 6); #magic
 		return(qq{print 'Hello $greet\n'});
	};
	$_[0]->register_rule($generator, '+::*', 'greet_');
};


package Synopsis::Desc1;
use Package::Autoloader sub{eval shift};

greet_mundo();


package sisponyS::Desc2;
our @ISA = ('Synopsis');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'sisponyS::Desc2');
print STDOUT ($obj->can('greet_monde') ? 'Can' : 'Cannot'), "\n";
print STDOUT ($obj->potentially_can('greet_monde')?'Can':'Cannot'),"\n";
$obj->greet_monde();

sub print_yn($) { print STDOUT (($_[0]) ? 'Yes' : 'No'), "\n"; }
print_yn(defined(&sisponyS::Desc2::greet_monde));
print_yn(defined(&Synopsis::Desc1::greet_monde));
print_yn(defined(&Synopsis::greet_monde));
