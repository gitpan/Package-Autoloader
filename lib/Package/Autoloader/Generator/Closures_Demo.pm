package Package::Autoloader::Generator::Closures_Demo;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub calc_generic {
	my ($correction, $a, $b) = @_;
	return($a * $correction/100 + $b);
};

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $generator = sub {
		my ($pkg, $sub_name, $argc) = (shift, shift, shift);
		my $argument = substr($sub_name, 5) || 100;
		my $sub_text = sprintf(q{
my ($calc_generic, $arg1) = (shift(@_), shift(@_));
sub %s { return($calc_generic->($arg1, @_)); };
return(\&%s);
		}, $sub_name, $sub_name);

		my $sub_ref = $pkg->transport(\$sub_text,
			\&calc_generic, $argument);
 		return($sub_ref);
	};

	bless($generator, $class);
}

1;
