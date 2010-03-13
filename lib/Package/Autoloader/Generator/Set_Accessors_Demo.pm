package Package::Autoloader::Generator::Set_Accessors_Demo;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub implement {
	my ($self, $pkg, $sub_name) = (shift, shift, shift);

	my $sub_text = sprintf(q{
                        my $self = shift;
                        $self->{%s} = shift;
                }, substr($sub_name, 4));
	
	return($sub_text);
}

1;
