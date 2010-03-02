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
	while($name =~ s,(::)\w+$,,s) {
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
		my $pkg_name = $self->[ATB_PKG_NAME];
		$rule = Package::Autoloader::Rule->new($rule, $pkg_name, @_);
	} elsif ($rule_ref eq 'ARRAY') {
		$rule = Package::Autoloader::Rule->new(@$rule);
	}

	$RULES->register_rule($rule, $rule->pre_select);
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
#	if ($DEBUG) {
#		push(@LOG, ['!', (defined($code) ? 'Yes' : 'No')]);
#	}
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
#	if ($DEBUG) {
#		push(@LOG, ['A', time, $pkg_name, $sub_name, @_]);
#	}

	my $generator = $self->has_generator($sub_name, @_);

	unless (defined($generator)) {
		Carp::confess("Unable to create '$sub_name' (no generator found).");
	}
	my $sub_ref = $self->run_generator($generator, $sub_name, @_);
	unless (defined($sub_ref)) {
		Carp::confess("Unable to create '$sub_name' (generator failed).");
	}
	return($sub_ref);
}

sub has_generator {
	my ($self, $sub_name) = (shift, shift);

	return(
		$RULES->lookup_rule(
			$self->[ATB_SEARCH_PATH],
			$self->[ATB_PKG_NAME],
			$sub_name, @_));
}

sub potentially_can {
	return(defined($_[0]->has_generator($_[2], $_[1])));
}

sub potentially_defined {
	return(defined($_[0]->has_generator($_[1])));
}

#sub dump_log {
#	print STDERR join("\n", map(join("\t", @$_), @LOG));
#	print STDERR "\n";
#}

1;
