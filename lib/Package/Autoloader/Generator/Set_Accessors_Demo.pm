package Package::Autoloader::Generator::Set_Accessors_Demo;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub new {
	my ($class, $defining_pkg) = (shift, shift);

        my $generator = sub {
		my ($pkg, $sub_name, $argc) = (shift, shift, shift);

                my $name = substr($sub_name, 4);
                my $sub_text = sprintf(q{
                        my $self = shift;
                        $self->{%s} = shift;
                }, $name);

 		return($sub_text);
        };
	bless($generator, $class);
}

1;
