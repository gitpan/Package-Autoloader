package Package::Autoloader::Generator::Closures_Demo;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		$sub_name =~ m,^(\w+)_(\d+)$,;
		my ($sub_base, $fixed_argument) = ($1, $2);
		my $sub_text = sprintf(q{
my ($fixed_argument) = (shift(@_));
sub %s { return(%s::%s($fixed_argument, @_)); };
return(\&%s);
		}, 
		$sub_name, $defining_pkg->name, $sub_base, $sub_name);

		my $sub_ref = $pkg->transport(\$sub_text, $fixed_argument);
 		return($sub_ref);
	};

	bless($generator, $class);
}

1;
