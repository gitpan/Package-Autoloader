package Package::Autoloader::Package;
use strict;
use warnings;
use Carp qw();
use Scalar::Util qw(blessed);

our $CANDEF = 0;

sub ATB_PKG_NAME() { 0 };
sub ATB_VISIT_POINT() { 1 };
sub ATB_SEARCH_PATH() { 2 };

use Package::Autoloader::Rule;
use Package::Autoloader::Pre_Selection;
my $RULES = Package::Autoloader::Pre_Selection->new(); 

my $autoload = q{
	my $object = shift(@_);

	our $AUTOLOAD;
	sub AUTOLOAD {
		my $sub_ref = $object->autoload_generic($AUTOLOAD, @_);
		goto &$sub_ref if (defined($sub_ref));
	}
};
my $candef = q{
	my $object = shift(@_);

	sub potentially_can {
		return(defined(UNIVERSAL::can(@_))
		|| $object->potentially_can(@_));
	}
	sub potentially_defined {
		return($object->potentially_defined(@_));
	}
};

sub package_hierarchy {
	my $name = shift;
	my @hierarchy = ($name);
	while($name =~ s,\w+(::)?$,,s) {
		push(@hierarchy, $name);
	}
	return(\@hierarchy);
}


sub new {
	my ($class, $pkg_name, $visit_point) = @_;

	my $self = [$pkg_name,
		$visit_point,
		package_hierarchy($pkg_name),
	];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	$self->transport(\$autoload, $self);
	$self->transport(\$candef, $self) if ($CANDEF);
	Carp::confess($@) if ($@);

	return($self);
}

sub potentially_candef {
	$_[0]->transport(\$candef, $_[0]);
	return;
}

sub set_visit_point {
	$_[0][ATB_VISIT_POINT] = $_[1];
	return;
}

sub transport {
	my ($self, $code_ref) = (shift, shift);

	unless (defined($code_ref)) {
		Carp::confess("No code.\n");
	}
	unless (ref($code_ref) eq 'SCALAR') {
		Carp::confess("Code not a scalar ref.\n");
	}

	my $rv = $self->[ATB_VISIT_POINT]->($$code_ref, @_);
	if ($@) {
		print STDERR "Offending Code:\n", $$code_ref, "\n";
		Carp::confess($@);
	}
	return($rv);
}

sub register_rule {
	my ($self, $rule) = (shift, shift);

	my $rule_ref = ref($rule);
	my @rules = ();
	if ($rule_ref eq '') {
		my $code = sprintf(q{
sub($$;@) {
	my($pkg, $sub_name, @args) = @_;
	%s
}}, $rule);
		$rule = eval $code;
		Carp::confess($@) if ($@);
		$rule_ref = 'CODE';
	}
	if ($rule_ref eq 'CODE') {
		my @pkg_names = ($self->[ATB_PKG_NAME]);
		my $wildcard = shift;
		if ($wildcard eq '+') {
		} elsif ($wildcard eq '+::*') {
			push(@pkg_names, $pkg_names[0]);
			$pkg_names[1] .= '::';
		} elsif ($wildcard eq '::*') {
			$pkg_names[0] .= '::';
		} elsif ($wildcard eq '*') {
			$pkg_names[0] = '';
		} else {
			Carp::confess("Don't know what to do with wildcard '$wildcard'.\n");
		}
		foreach my $pkg_name (@pkg_names) {
			push(@rules,
				Package::Autoloader::Rule->new($rule, $pkg_name, @_));
		}
	} elsif ($rule_ref eq 'ARRAY') {
		push(@rules, Package::Autoloader::Rule->new(@$rule));
	} else {
		push(@rules, $rule);
	}

	foreach my $rule (@rules) {
		$RULES->register_rule($rule, $rule->pre_select);
	}
	return;
};

my $std_sub = q{
	sub %s { %s };
	return(\&%s);
};
sub run_generator {
	my ($self, $generator, $sub_name) = (shift, shift, shift);

	return(undef) unless (defined($generator));

	my $code = $generator->($self, $sub_name, @_);
	Carp::confess('No code.') unless (defined($code));
	if (ref($code) eq '') {
		unless ($code =~ m,^[\n\t\s]*sub[\n\t\s],) {
			$code = sprintf($std_sub, $sub_name, $code, $sub_name);
		}

		$code = $self->transport(\$code);
	}
	return($code);
};

sub autoload_generic {
	my ($self, $sub_name) = (shift, shift);

	my $pkg_name = $self->[ATB_PKG_NAME];
	if (($sub_name =~ s,^(.*)::,,) and ($pkg_name ne $1)) {
		Carp::confess("($pkg_name ne $1)");
	}
	return(undef) if ($sub_name eq 'DESTROY');
#	return(undef) if ($sub_name eq 'AUTOLOAD');

	my $generator;
	if (blessed($_[0])) {
		my $ISA = mro::get_linear_isa($self->[ATB_PKG_NAME]);
		($self, $generator) = Package::Autoloader::find_generator($ISA, $sub_name, @_);
	} else {
		$generator = $self->find_generator($sub_name, @_);
	}

	unless (defined($generator)) {
		Carp::confess("Unable to create '$sub_name' for $pkg_name (no generator found).");
	}
	my $sub_ref = $self->run_generator($generator, $sub_name, @_);
	unless (defined($sub_ref)) {
		Carp::confess("Unable to create '$sub_name' for $pkg_name (generator failed).");
	}
	return($sub_ref);
}

sub find_generator {
	return($RULES->lookup_rule(
		$_[0][ATB_SEARCH_PATH],
		$_[0][ATB_PKG_NAME],
		$_[1], @_));
}

sub potentially_can {
	my ($self) = (shift);

	my $ISA = mro::get_linear_isa($self->[ATB_PKG_NAME]);
	my ($pkg, $generator) = Package::Autoloader::find_generator($ISA, $_[1], $_[0]);
	return(defined($generator));
}

sub potentially_defined {
	return(defined(shift->find_generator(@_)));
}

#sub DESTROY {
#	use Data::Dumper;
#	print STDERR Dumper($_[0]);
#}

1;