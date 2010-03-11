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

	$self->transport(\$autoloadcan, $self);

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

	unless (defined($code_ref)) {
		Carp::confess("No code to transport?\n");
	}
	unless (ref($code_ref) eq 'SCALAR') {
		Carp::confess("Code not a scalar reference.\n");
	}
	my $sa = $@;
	my $rv = $self->[ATB_VISIT_POINT]->($$code_ref, @_);
	if ($@) {
		print STDERR "Offending Code:\n", $$code_ref, "\n";
		Carp::confess($@);
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
		return;
	}

	my $rule_ref = ref($rule);
	if ($rule_ref eq '') {
		if ($rule =~ m,(^|::)([\w_]+($|::))+,) {
			my $class;
			if (substr($rule, 0, 2) eq '::') {
				$class = "Package::Autoloader::Generator$rule";
			} else {
				$class = $rule;
			}
			# shows the impractical parts of Perl5
			my $class_for_require = $class;
			$class_for_require =~ s,::,/,sg;
			$class_for_require .= '.pm';
			#local $!; # isn't this handled inside require?
			require $class_for_require;
			$rule = $class->new($self);
		} else {
			my $code = sprintf(q{
sub($$;@) {
	my($pkg, $sub_name, @args) = @_;
%s
}}, $rule);
			local $@;
			$rule = [eval $code];
			Carp::confess($@) if ($@);
			bless($rule, 'Package::Autoloader::Generator');
		}
	} elsif ($rule_ref eq 'CODE') {
		$rule = [$rule];
		bless($rule, 'Package::Autoloader::Generator');
	}

	if (Scalar::Util::blessed($rule) and $rule->can('run')) {
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
			if ($rule->can('matcher')) {
				$_[0] = $rule->matcher();
			}
		}

		my $real_rule = Package::Autoloader::Rule->new(
			$rule, \@pkg_names, @_);
		$RULES->register_rules($real_rule, $real_rule->pre_select);
	}

	return;
};

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