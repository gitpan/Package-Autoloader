package Package::Autoloader::Package;
use strict;
use warnings;
use Carp qw();
use Scalar::Util qw();
#use MRO::Compat;
use mro;

sub ATB_PKG_NAME() { 0 };
sub ATB_VISIT_POINT() { 1 };
sub ATB_SEARCH_PATH() { 2 };
sub ATB_PATH_PARTITION() { 3 };

use Package::Autoloader::Rule;
use Package::Autoloader::Pre_Selection;
use Package::Autoloader::Path_Partition;
use Package::Autoloader::Generator;
#use Package::Autoloader::Instant;
my $RULES = Package::Autoloader::Pre_Selection->new(); 

my $autoloadcan = q{
	my $object = shift(@_);

	our $AUTOLOAD;
	sub AUTOLOAD {
		my $sub_ref = $object->autoload($AUTOLOAD, @_);
		goto &$sub_ref if (defined($sub_ref));
	}
	sub can {
		return(UNIVERSAL::can(@_) // $object->can_already(@_));
	}
};

my $potentially_can = q{
	my $object = shift(@_);
	sub potentially_can {
		return($object->potentially_can(@_));
	}
	return(\&potentially_can);
};

my $potentially_defined = q{
	my $object = shift(@_);
	sub potentially_defined(\&) {
		return($object->potentially_defined(@_));
	}
	return(\&potentially_defined);
};

sub new {
	my ($class, $pkg_name, $visit_point) = @_;

	my $self = [
		$pkg_name, 
		$visit_point,
		Package::Autoloader::Path_Partition->new($pkg_name)
	];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	$visit_point->($autoloadcan, $self);

	return($self);
}

sub name { return($_[0][ATB_PKG_NAME]); };

sub search { return($_[0][ATB_PATH_PARTITION]); };

sub set_visit_point {
	$_[0][ATB_VISIT_POINT] = $_[1];
	return;
}

sub transport {
	my ($self, $code_ref) = (shift, shift);

#	unless (defined($code_ref)) {
#		Carp::confess("No code to transport?\n");
#	}
	unless (ref($code_ref) eq 'SCALAR') {
		Carp::confess("Code not a scalar reference.\n");
	}
	my $sa = $@;
	my $rv = $self->[ATB_VISIT_POINT]->($$code_ref, @_);
	if ($@) {
		my $msg = "Offending Code:\n$$code_ref\n".$@;
		Carp::confess($msg);
	}
	$@ = $sa;
	return($rv);
}

sub register_rule {
	my ($self, $rule) = (shift, shift);

	if (scalar(@_) == 0) { # no further arguments
		if (ref($rule) eq 'ARRAY') {
			$rule = Package::Autoloader::Rule->new(@$rule);
			$RULES->register_rules($rule, $rule->pre_select);
		} elsif (Scalar::Util::blessed($rule)) {
			$RULES->register_rules($rule, $rule->pre_select);
		} else {
			Carp::confess("Wrong type of argument.");
		}
		return($rule);
	}

	my $rule_ref = ref($rule);
	my $generator;
	if ($rule_ref eq '') {
		$generator = $self->create_generator($rule);
	} elsif ($rule_ref eq 'CODE') {
		$generator = Package::Autoloader::Generator->new($rule);
	} else {
		$generator = $rule;
	}
	unless (Scalar::Util::blessed($generator) and $generator->can('run')) {
		Carp::confess("The result does not look like a generator.\n");
	}

	my @pkg_names = ($self->[ATB_PKG_NAME]);
	my $wildcard = shift;
	if ($wildcard eq '=') {
	} elsif ($wildcard eq '=::*') {
		push(@pkg_names, $pkg_names[0]);
		$pkg_names[1] .= '::';
	} elsif ($wildcard eq '::*') {
		$pkg_names[0] .= '::';
	} elsif ($wildcard eq '*') {
		$pkg_names[0] = '';
	} else {
		Carp::confess("Don't know what to do with wildcard '$wildcard'.\n");
	}
	
	unless (defined($_[0])) {
		if ($generator->can('matcher')) {
			$_[0] = $generator->matcher();
		}
	}
	
	$rule = Package::Autoloader::Rule->new($generator, \@pkg_names, @_);
	$RULES->register_rules($rule, $rule->pre_select);

	return($rule);
}

sub create_generator {
	my ($self, $rule) = (shift, shift);

	my $generator;
	if ($rule =~ m,(^|::)([\w_]+($|::))+,) {
		$generator = Package::Autoloader::Generator::new_class($rule, $self);
	} else {
		my $code = sprintf(q{
sub($$;@) {
	my($pkg, $sub_name, @args) = @_;
%s
}}, $rule);
		local $@;
		$rule = eval $code;
		Carp::confess($@) if ($@);
		$generator = Package::Autoloader::Generator->new($rule);
	}
	return($generator);
}


sub instant_cf {
	my ($self, $class, $wild_card, $prefix, $from, $lifespan) =
		(shift, shift, shift, shift, shift, shift);

	my $generator = $self->create_generator("::Constant_Function$class");
	$generator->take_from($from); # if(defined($from));
	$generator->configure(@_);
	my $rule = $self->register_rule($generator, $wild_card, $prefix);
	$self->implement($prefix);
	$rule->release() unless(defined($lifespan));

	return;
}

sub collect_generators {
	my ($self, $how, $sub_name) = (shift, shift, shift);

	my $search_path;
	if($how eq '^') {
		$search_path = mro::get_linear_isa($self->[ATB_PKG_NAME]);
	} else {
		$search_path = $self->[ATB_SEARCH_PATH]; 
	}
	return($RULES->collect_generators(
		$search_path,
		$self->[ATB_PKG_NAME],
		$sub_name, @_));
}

sub implement {
	my ($self, $sub_name) = (shift, shift);

	my $generator = $self->find_generator($sub_name);
	unless (defined($generator)) {
		return(Package::Autoloader::Generator::failure(undef, $sub_name, 'package object: no rule found'));
	}

	return($generator->run($self, $self->[ATB_PKG_NAME], $sub_name));
}

sub autoload {
	my ($self, $sub_name) = (shift, shift);

	my $pkg_name = $self->[ATB_PKG_NAME];
	if (($sub_name =~ s,^(.*)::,,) and ($pkg_name ne $1)) {
		Carp::confess("($pkg_name ne $1)"); # assertion - goes soon
	}
	return(undef) if ($sub_name eq 'DESTROY');
#	return(undef) if ($sub_name eq 'AUTOLOAD');
	if ($sub_name eq 'potentially_can') {
		return($self->transport(\$potentially_can, $self));
	}
	if ($sub_name eq 'potentially_defined') {
		return($self->transport(\$potentially_defined, $self));
	}

	my $generator;
	if (Scalar::Util::blessed($_[0])) {
		my $ISA = mro::get_linear_isa($pkg_name);
		($self, $generator) = Package::Autoloader::find_generator($ISA, $sub_name, @_);
		unless (defined($generator)) {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, 'package object: no rule found'));
		}
	} else {
		$generator = $self->find_generator($sub_name, @_);
		unless (defined($generator)) {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, 'package object: no rule found'));
		}
	}

	return($generator->run($self, $pkg_name, $sub_name, @_));
}

sub find_generator {
	my ($self, $sub_name) = (shift, shift);
	return($RULES->lookup_rule(
		$self->[ATB_SEARCH_PATH],
		$self->[ATB_PKG_NAME],
		$sub_name, @_));
}

sub can_already {
	my ($self) = (shift);

	my $ISA = mro::get_linear_isa($self->[ATB_PKG_NAME]);
	my ($pkg, $generator) = Package::Autoloader::find_generator($ISA, $_[1], $_[0]);
	return unless (defined($generator));
	return($generator->run($pkg, $self->[ATB_PKG_NAME], $_[1], @_));
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
