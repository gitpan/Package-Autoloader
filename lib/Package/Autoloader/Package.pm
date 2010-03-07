package Package::Autoloader::Package;
use strict;
use warnings;
use Carp qw();
use Scalar::Util qw(blessed);
use mro qw();

our $CANDEFINED = 0;

sub ATB_PKG_NAME() { 0 };
sub ATB_VISIT_POINT() { 1 };
sub ATB_SEARCH_PATH() { 2 };
sub ATB_PATH_PARTITION() { 3 };

use Package::Autoloader::Rule;
use Package::Autoloader::Pre_Selection;
use Package::Autoloader::Path_Partition;
use Package::Autoloader::Generator;
my $RULES = Package::Autoloader::Pre_Selection->new(); 

my $autoload = q{
	my $object = shift(@_);

	our $AUTOLOAD;
	sub AUTOLOAD {
		my $sub_ref = $object->autoload_generic($AUTOLOAD, @_);
		goto &$sub_ref if (defined($sub_ref));
	}
};
my $can = q{
	my $object = shift(@_);
	sub potentially_can {
		return(defined(UNIVERSAL::can(@_))
		|| $object->potentially_can(@_));
	}
	return(\&potentially_can);
};

my $defined = q{
	my $object = shift(@_);
	sub potentially_defined {
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

	$self->transport(\$autoload, $self);
	$self->potentially_candefined if ($CANDEFINED);

	return($self);
}

sub name { return($_[0][ATB_PKG_NAME]); };

sub search { return($_[0][ATB_PATH_PARTITION]); };

sub potentially_candefined {
	$_[0]->transport(\$can, $_[0]);
	$_[0]->transport(\$defined, $_[0]);
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

	my $rule_ref = ref($rule);
	if ($rule_ref eq '') {
		if ($rule =~ m,^([\w_]+($|::))+,) {
			my $class;
			if($rule =~ m,:,) {
				$class = $rule;
			} else {
				$class = "Package::Autoloader::Generator::$rule";
			}
			# shows the impractical parts of Perl5
			my $class_for_require = $class;
			$class_for_require =~ s,::,/,sg;
			$class_for_require .= '.pm';
			#local $!; # isn't this handled inside require?
			require $class_for_require;
			$rule = $class->new($self);
			$rule_ref = 'Package::Autoloader::Generator';
		} else {
			my $code = sprintf(q{
sub($$;@) {
	my($pkg, $sub_name, @args) = @_;
%s
}}, $rule);
			local $@;
			$rule = eval $code;
			Carp::confess($@) if ($@);
			$rule_ref = 'CODE';
		}
	}

	if ($rule_ref eq 'CODE') {
		if(ref($rule) eq 'CODE') {
			bless($rule, 'Package::Autoloader::Generator');
		}
		$rule_ref = 'Package::Autoloader::Generator';
	}

	if($rule_ref eq 'Package::Autoloader::Generator') {
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
		my $rule = Package::Autoloader::Rule->new(
			$rule, \@pkg_names, @_);
		$RULES->register_rules($rule, $rule->pre_select);
	} elsif ($rule_ref eq 'ARRAY') {
		my $rule = Package::Autoloader::Rule->new(@$rule);
		$RULES->register_rule($rule, $rule->pre_select);
	} else {
		Carp::confess;
		$RULES->register_rule($rule, $rule->pre_select);
	}

	return;
};

sub autoload_generic {
	my ($self, $sub_name) = (shift, shift);

	my $pkg_name = $self->[ATB_PKG_NAME];
	if (($sub_name =~ s,^(.*)::,,) and ($pkg_name ne $1)) {
		Carp::confess("($pkg_name ne $1)");
	}
	return(undef) if ($sub_name eq 'DESTROY');
#	return(undef) if ($sub_name eq 'AUTOLOAD');
	if ($sub_name eq 'potentially_can') {
		return($self->transport(\$can, $self));
	}
	if ($sub_name eq 'potentially_defined') {
		return($self->transport(\$defined, $self));
	}

	my $generator;
	if (blessed($_[0])) {
		my $ISA = mro::get_linear_isa($pkg_name);
		($self, $generator) = Package::Autoloader::find_generator($ISA, $sub_name, @_);
	} else {
		$generator = $self->find_generator($sub_name, @_);
	}

	unless (defined($generator)) {
		Carp::confess("Unable to create '$sub_name' for $pkg_name (no generator found).");
	}
	return($generator->run($self, $pkg_name, $sub_name, @_));
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
