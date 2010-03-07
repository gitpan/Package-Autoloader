package Package::Autoloader::Generator::Hello_Anything;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub new {
	my ($class, $defining_pkg) = (shift, shift);

        my $generator = sub {
		my ($pkg, $sub_name, $argc) = (shift, shift, shift);

                my $sub_body = sprintf(
			qq{print 'Hello %s\n'},
			substr($sub_name, 6));
 		return($sub_body);
        };
	bless($generator, $class);
}

1;
