use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	my $generator = q{
		my $greet = substr($sub_name, 6); #magic
 		return(qq{return('Hello $greet\n')});
	};
	$_[0]->register_rule($generator, 'greet_');
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
print $obj->greet_monde();
