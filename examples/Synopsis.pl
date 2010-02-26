
package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	my $generator = q{sprintf("Hello %s\n", substr($sub_name, 6))};
	$_[0]->package_hierarchy_rule($generator, 'greet_');
	$_[0]->isa_listed_rule($generator, 'saluer_');
};

print greet_world();


package Synopsis::Desc1;
use Package::Autoloader sub{eval shift};

print greet_mundo();


package Synopsis::Desc2;
our @ISA = ('Synopsis');
use Package::Autoloader sub{eval shift};

my $obj = bless( \(my $o = 0), 'Synopsis::Desc2');
print STDOUT ($obj->can('greet_monde') ? 'Can' : 'Cannot'), "\n";
#print greet_monde();
#print $obj->greet_monde();
print $obj->saluer_monde();
