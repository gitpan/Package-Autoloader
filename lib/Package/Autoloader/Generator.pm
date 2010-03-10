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

sub failure {
	my ($pkg_name, $sub_name, $what) = @_;
	my @where = caller;
	my $failure = sub {
		my @caller = caller();
		my $msg = sprintf(
			q{Undefined subroutine &%s::%s called at %s line %s.},
			$pkg_name || $caller[0],
			$sub_name,
			$caller[1],
			$caller[2])
			."\n"
			.'(Still undefined even after trying AUTOLOAD via Package::Autoloader'
			."\n"
			.sprintf(' and finally decided by %s.)', $what || $where[0])
			."\n";
		die($msg);
	};
	return($failure);
}

1;