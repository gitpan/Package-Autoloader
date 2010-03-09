package Package::Autoloader::Generator::Export;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		my $sub_text = sprintf(q{
my $sub_ref = \&%s::%s;
*%s = $sub_ref;
return($sub_ref);
		}, $defining_pkg->name, $sub_name, $sub_name);

 		return($pkg->transport(\$sub_text));
	};
	bless($generator, $class);
}

1;
