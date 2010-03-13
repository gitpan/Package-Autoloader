package Package::Autoloader::Generator::Constant_Function::Lowered;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator::Constant_Function
	Package::Autoloader::Generator
);

sub determine {
	my ($self, $prefix, $names) = @_;

	my @values = ();
	foreach my $name (@$names) {
		my $value = "$prefix$name";
		push(@values, [$value, lc($value)]);
	}
	return(\@values);
}

1;
