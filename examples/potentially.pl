use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	my $generator = q{
		my $greet = substr($sub_name, 6);
 		return(qq{return('Hello $greet\n')});
	};
	$_[0]->package_hierarchy_rule($generator, 'greet_');
	$_[0]->isa_listed_rule($generator, 'saluer_');
};

print greet_world();


package Synopsis::Desc1;
use Package::Autoloader sub{eval shift}, sub{
	$_[0]->potentially_candef;
};

print greet_mundo();
print STDOUT (defined(&greet_world) ? 'Can' : 'Cannot'), "\n";
print STDOUT (potentially_defined('greet_world') ? 'Can' : 'Cannot'), "\n";


package Synopsis::Desc2;
our @ISA = ('Synopsis');
use Package::Autoloader sub{eval shift}, sub{
	$_[0]->potentially_candef;
};

my $obj = bless( \(my $o = 0), 'Synopsis::Desc2');
print STDOUT ($obj->can('greet_monde') ? 'Can' : 'Cannot'), "\n";
print STDOUT ($obj->potentially_can('greet_monde') ? 'Can' : 'Cannot'), "\n";
#print greet_monde();
#print $obj->greet_monde();
print $obj->saluer_monde();