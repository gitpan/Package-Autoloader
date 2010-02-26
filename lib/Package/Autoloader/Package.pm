package Package::Autoloader::Package;
use strict;
use warnings;
use Carp qw();
use Scalar::Util qw(blessed);

#our $DEBUG = 0;

sub ATB_PKG_NAME() { 0 };
sub ATB_VISIT_POINT() { 1 };
sub ATB_PROPERTIES() { 2 };

sub RULE_LISTED() { 0 };
sub RULE_HIERACHY() { 1 };

use Package::Autoloader::Rule;
use Package::Autoloader::Properties;
use Package::Autoloader::Pre_Selection;
my $RULES = [
	Package::Autoloader::Pre_Selection->new(),
	Package::Autoloader::Pre_Selection->new()
]; 


my $autoload = q{
	my $object = shift(@_);

	our $AUTOLOAD;
	our @ISA;
	sub AUTOLOAD {
		my $sub_ref = $object->autoload_generic(\@ISA, $AUTOLOAD, @_);
		goto &$sub_ref if(defined($sub_ref));
	}
	sub can {
		my $sub_ref = UNIVERSAL::can(@_);

		defined($sub_ref)
		? return($sub_ref)
		: return($object->can_generic(\@ISA, @_));
	}
};
sub new {
	my ($class, $pkg_name, $visit_point) = @_;

	my $self = [$pkg_name,
		$visit_point,
		Package::Autoloader::Properties->new()
		];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	$self->transport(\$autoload, $self);
	Carp::confess($@) if($@);

	return($self);
}

sub set_visit_point {
	$_[0][ATB_VISIT_POINT] = $_[1];
	return;
}


sub properties { return($_[0][ATB_PROPERTIES]); }


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


my $register = sub {
	my ($type, $self, $rule) = (shift, shift, shift);

	my $rule_ref = ref($rule);
	if($rule_ref eq '') {
		$rule = eval qq{
sub{
	my(\$pkg, \$sub_name, \@args) = \@_;
	return(sub{ $rule })
}};
		Carp::confess($@) if ($@);
		$rule_ref = 'CODE';
	}
	if($rule_ref eq 'CODE') {
		my $pkg_name = $self->[ATB_PKG_NAME];
		$pkg_name .= '::' if($type == RULE_HIERACHY);
		$rule = Package::Autoloader::Rule->new($rule, $pkg_name, @_);
	} elsif($rule_ref eq 'ARRAY') {
		$rule = Package::Autoloader::Rule->new(@$rule);
	}

	$RULES->[$type]->register_rule($rule, $rule->pre_select);
	return;
};

sub isa_listed_rule { return($register->(RULE_LISTED, @_)); };
sub package_hierarchy_rule { return($register->(RULE_HIERACHY, @_)); };


my $std_sub = q{
	sub %s { %s };
	return(\&%s);
};
my $lookup = sub {
	my ($type, $self, $pkg_list, $sub_name) = (shift, shift, shift, shift);

	unless(exists($RULES->[$type])) {
		Carp::confess("Type '$type' is not valid.\n");
	}
	my $generator = $RULES->[$type]->lookup_rule
		($pkg_list, $self->[ATB_PKG_NAME], $sub_name, @_);
	return(undef) unless(defined($generator));

	my $code = $generator->($self, $sub_name, @_);
	if(ref($code) eq '') {
		unless($code =~ m,^[\n\t\s]*sub[\n\t\s],) {
			$code = sprintf($std_sub, $sub_name, $code, $sub_name);
		}

		$code = $self->transport(\$code);
	}
#	if($DEBUG) {
#		push(@LOG, ['!', (defined($code) ? 'Yes' : 'No')]);
#	}
	return($code);
};


sub package_hierarchy {
	my $path = shift;
	my $hierarchy = [];
	while($path =~ s,\w+(::)?$,,s) {
		push(@$hierarchy, $path);
	}
	return($hierarchy);
}


sub autoload_generic {
	my ($self, $isa, $sub_name) = (shift, shift, shift);

	my $pkg_name = $self->[ATB_PKG_NAME];
	if(($sub_name =~ s,^(.*)::,,) and ($pkg_name ne $1)) {
		Carp::confess("($pkg_name ne $1)");
	}
	return(undef) if($sub_name eq 'DESTROY');
#	return(undef) if($sub_name eq 'AUTOLOAD');
#	if($DEBUG) {
#		push(@LOG, ['A', time, join('+', @$isa), $pkg_name, $sub_name, @_]);
#	}

	my $sub_ref = undef;
	if(blessed($_[0])) { # maybe a method
		my $search = [];
		if($self->properties->is_search_self_isa) {
			push(@$search, $pkg_name);
		}
		push(@$search, @$isa);
		$sub_ref = $lookup->(RULE_LISTED, $self,
			$search, $sub_name, @_); 
	} else {
		my $search = [$pkg_name];
		if($self->properties->is_self_wild_hierarchy) {
			push(@$search, "$pkg_name\::");
		}
		$sub_ref = $lookup->(RULE_HIERACHY, $self,
			$search, $sub_name, @_); 
		return($sub_ref) if(defined($sub_ref));
		
		$sub_ref = $lookup->(RULE_HIERACHY, $self, 
			package_hierarchy($pkg_name), $sub_name, @_); 
	}

	unless(defined($sub_ref)) {
		Carp::confess("Unable to create '$sub_name'.");
	}
	return($sub_ref);
}


sub can_generic {
	my ($self, $isa, $obj, $sub_name) = @_;

#	if($DEBUG) {
#		push(@LOG, ['C', time, join('+', @{$_[0]}), $pkg_name, @_]);
#	}

	my $search = [];
	if($self->properties->is_search_self_isa) {
		push(@$search, ref($obj));
	}
	push(@$search, @$isa);
	my $sub_ref = $lookup->(RULE_LISTED, $self, $search, $sub_name); 
	return($sub_ref);
}




#sub dump_log {
#	print STDERR join("\n", map(join("\t", @$_), @LOG));
#	print STDERR "\n";
#}

1;
