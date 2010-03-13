package Package::Autoloader::Generator::Constant_Function::Enumerated;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator::Constant_Function
	Package::Autoloader::Generator
);

sub determine {
	my ($self, $prefix, $names) = @_;

	my @values = ();
	my $i = 0;
	foreach my $name (@$names) {
		push(@values, ["$prefix$name", $i++]);
	}
	return(\@values);
}

1;
