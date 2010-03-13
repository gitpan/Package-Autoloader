package Package::Autoloader;
use strict;
use warnings;
use Carp qw();

our $VERSION = '0.14';

use Package::Autoloader::Package;
my $PACKAGES = {};

my $obtain = sub {
	my ($pkg_name, $visit_point) = @_;
	if (exists($PACKAGES->{$pkg_name})) {
		$PACKAGES->{$pkg_name}->set_visit_point($visit_point);
	} else {
		$PACKAGES->{$pkg_name} = Package::Autoloader::Package
			->new($pkg_name, $visit_point);
	}
	return($PACKAGES->{$pkg_name});
};

sub new {
	my ($class) = (shift);
	return($obtain->((caller())[0], @_));
}

sub find_generator($@) {
	my ($ISA) = (shift);

	foreach my $pkg_name (@$ISA) {
		next unless (exists($PACKAGES->{$pkg_name}));
		my $generator = $PACKAGES->{$pkg_name}->find_generator(@_);
		if (defined($generator)) {
			return($PACKAGES->{$pkg_name}, $generator);
		}
	}
	return(undef);
}

sub import {
	my ($class) = (shift);

	return unless (exists($_[0]));
	my $pkg = $obtain->((caller)[0], shift);
	if (exists($_[0])) {
		if (ref($_[0]) ne 'CODE') {
			Carp::confess("Don't know what to do with '$_[0]'.\n");
		}
		$_[0]->($pkg);
	}
	return;
}

#sub debug_dump {
#	use Data::Dumper;
#	print STDERR Dumper($PACKAGES);
#}

1;
