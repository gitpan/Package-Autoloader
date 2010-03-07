package Package::Autoloader::Generator;
use strict;
use warnings;

my $std_sub = q{
	sub %s { %s };
	return(\&%s);
};
sub run {
	my ($self, $pkg, $pkg_name, $sub_name) = (shift, shift, shift, shift);

	my $code = $self->($pkg, $sub_name, @_);
	return unless (defined($code));
	if (ref($code) eq '') {
		unless ($code =~ m,^[\n\t\s]*sub[\n\t\s],) {
			$code = sprintf($std_sub, $sub_name, $code, $sub_name);
		}

		$code = $pkg->transport(\$code);
	}

	unless (defined($code)) {
		Carp::confess("Unable to create '$sub_name' for $pkg_name (generator failed).");
	}
	return($code);
};

1;
