package Package::Autoloader;
use strict;
use warnings;
use Carp qw();

our $VERSION = '0.03';

use Package::Autoloader::Package;
my $PACKAGES = {};

my $obtain = sub {
	my ($name, $visit_point) = @_;
	unless (exists($PACKAGES->{$name})) {
		$PACKAGES->{$name} = Package::Autoloader::Package->new
			($name, $visit_point);
	}
	return($PACKAGES->{$name});
};


sub new {
	my ($class) = (shift);
	return($obtain->((caller())[0], @_));
}


sub import {
	my ($class) = (shift);

	return unless (exists($_[0]));
	if (ref($_[0]) ne 'CODE') {
		Carp::confess("Don't know what to do with '$_[0]'.\n");
	}
	my $visit_point = shift;

	my $pkg = $obtain->((caller)[0], $visit_point);
	foreach my $arg (@_) {
		if (ref($arg) eq 'CODE') {
			$arg->($pkg, $pkg->properties);
			next;
		}
	}
	return;
}


#sub debug_dump {
#	use Data::Dumper;
#	print STDERR Dumper($PACKAGES);
#}


1;