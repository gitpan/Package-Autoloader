package Package::Autoloader::Properties;
use strict;
use warnings;
use Carp qw(confess);

my @EXPORT = qw(HRC_SELF_WILD  HRC_SELF_PLAIN  ISA_SEARCH_SELF
	ISA_SEARCH_ONLY  set_bits);

sub PRP_RANGE() { return(4); };

sub HRC_SELF_WILD() { 0+2**1 };
sub HRC_SELF_PLAIN() { 1+2**1 };

sub ISA_SEARCH_SELF() { 0+2**2 };
sub ISA_SEARCH_ONLY() { 1+2**2 };


sub new {
	my ($class, $value) = (shift, shift);

	if (ref($value) eq 'ARRAY') {
		$value = set_bits(1, $value);
	} elsif(not defined($value)) {
		$value = 1;
	}
	my $self = \$value;
	bless($self, $class);

	return($self);
}


sub clone {
	my ($self) = (shift);

	my $class = ref($self);
	my $value = $$self;
	if (exists($_[0]) and (ref($_[0]) eq 'ARRAY')) {
		$value = set_bits($value, $_[0]);
	}
	my $clone = \$value;
	bless($clone, $class);

	return($clone);
}


sub set {
	${$_[0]} = (ref($_[1]) eq 'ARRAY')
		? set_bits(${$_[0]}, $_[1])
		: $_[1];
}


sub has {
	my ($self) = (shift);

	foreach my $property (@_) {
		if($property & 1) {
			return(0) if ((${$_[0]} & $property) < 2);
		} else {
			return(0) if ((${$_[0]} & $property) != 0);
		}
	}
	return(1);
}


sub is_search_self_isa { return((${$_[0]} & ISA_SEARCH_SELF) == 0); }
sub is_search_only_isa { return((${$_[0]} & ISA_SEARCH_ONLY) > 1); }
sub is_self_wild_hierarchy { return((${$_[0]} & HRC_SELF_WILD) == 0); }
sub is_self_plain_hierarchy { return((${$_[0]} & HRC_SELF_PLAIN) == 0); }


sub set_bits($$) {
	my ($result, $properties) = @_;

	return($result) if(! defined($properties));

PROP:	foreach my $property (@$properties) {
		my $value = ($property & 1);
		foreach my $position (PRP_RANGE) {
			next unless ($property & $position);
			if ($value) {
				$result |= $position; 
			} else {
				$result &= ~ $position;
			}
			next PROP;
		}
		Carp::confess("Could not find property '$_[1]'.");
	}
	return($result);
}


sub _import {
	my ($visit_point, $class, $EXPORT) = @_;
	
	my $defines = join("\n",
		map(sprintf('*%s = \&%s::%s; ', $_, $class, $_), 
			@$EXPORT));

	$visit_point->($defines);
	Carp::confess($@) if ($@);
}


sub import {
	return unless(defined($_[1]));
	return(_import($_[1], __PACKAGE__, \@EXPORT));
}


1;
