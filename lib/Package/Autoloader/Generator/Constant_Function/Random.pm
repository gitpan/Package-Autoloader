package Package::Autoloader::Generator::Constant_Function::Random;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator::Constant_Function
	Package::Autoloader::Generator
);

my %VALUES = ('FFFFFFFF' => 1);

sub determine {
	my ($self, $prefix, $names) = @_;

	my @values = ();
	my $value = 'FFFFFFFF';
	foreach my $name (@$names) {
                while($VALUES{$value}) {
                        $value = sprintf('%08x', int(rand(2**32-1)));
                }
                $VALUES{$value} = 1;

		push(@values, ["$prefix$name", $value]);
	}
	return(\@values);
}

1;
