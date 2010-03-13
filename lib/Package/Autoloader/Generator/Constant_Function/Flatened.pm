package Package::Autoloader::Generator::Constant_Function::Flatened;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator::Constant_Function
	Package::Autoloader::Generator
);

sub determine {
	my ($self, $prefix, $names) = @_;

	my @values = ();
	while (my $name = shift(@$names)) {
		my $value = scalar(shift(@$names));
		$value =~ s,\},\\},sg;
		push(@values, ["$prefix$name", $value]);
	}
	return(\@values);
}

1;
