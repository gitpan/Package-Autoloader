package Package::Autoloader;
use strict;
use warnings;
use Carp qw();

our $VERSION = '0.01';
our $DEBUG = 0;

sub RULE_LISTED() { 0 };
sub RULE_HIERACHY() { 1 };

use Package::Autoloader::Rule;
use Package::Autoloader::Pre_Selection;
my $RULES = [
	Package::Autoloader::Pre_Selection->new(),
	Package::Autoloader::Pre_Selection->new()
]; 

sub isa_listed_rule { _register(RULE_LISTED, @_); };
sub package_hierarchy_rule { _register(RULE_HIERACHY, @_); };

sub _register {
	my ($type) = (shift);

	my $rule_ref = ref($_[0]);
	my $rule;
	if($rule_ref eq 'ARRAY') {
		$rule = Package::Autoloader::Rule->new(@{$_[0]});
	} elsif($rule_ref eq 'CODE') {
		$rule = Package::Autoloader::Rule->new(@_);
	} else {
		$rule = $_[0];
	}

	unless(exists($RULES->[$type])) {
		Carp::confess("Type '$type' is not valid.\n");
	}
	my $preselection = $RULES->[$type];
	my ($pkg_name, $sub_name) = $rule->preselect;

	$preselection->register_rule($pkg_name, $sub_name, $rule);
	return;
}


my $std_sub = q{
	sub %s { %s };
	return(\&%s);
};
sub _lookup {
	my ($type, $visit_point, $pkg_list, $pkg_name, $sub_name) = 
		(shift, shift, shift, shift, shift);

	unless(exists($RULES->[$type])) {
		Carp::confess("Type '$type' is not valid.\n");
	}
	my $preselection = $RULES->[$type];

	my $generator = $preselection->lookup_rule
		($pkg_list, $pkg_name, $sub_name, @_);
	return(undef) unless(defined($generator));

	my $code = $generator->($visit_point, $pkg_name, $sub_name, @_);
	if(ref($code) eq '') {
		unless($code =~ m,^[\n\t\s]*sub[\n\t\s],) {
			$code = sprintf($std_sub, $sub_name, $code, $sub_name);
		}

#		print STDERR "c: $code\n";
		$code = $visit_point->($code);
		Carp::confess($@) if($@);
	}
	return($code);
}


sub package_hierarchy {
	my $path = shift;
	my $hierarchy = [];
	while($path =~ s,\w+(::)?$,,s) {
		push(@$hierarchy, $path);
	}
	return($hierarchy);
}


sub autoload_generic {
	my ($visit_point, $isa) = (shift, shift);

	$_[1] =~ s,^(.*)::,,;
	my $sub_ref = _lookup(RULE_HIERACHY, $visit_point, [$_[0]], @_); 
	return($sub_ref) if(defined($sub_ref));

	$sub_ref = _lookup(RULE_LISTED, $visit_point, [$_[0], @$isa], @_); 
	return($sub_ref) if(defined($sub_ref));

	$sub_ref = _lookup(RULE_HIERACHY, $visit_point,
		package_hierarchy($_[0]), @_); 
	Carp::confess("Unable to create '$_[1]'.") unless(defined($sub_ref));
	return($sub_ref);
}


sub can_generic {
	my $sub_ref = _lookup(RULE_LISTED, @_); 
	return($sub_ref);
}


my $autoload_generic = q{
unless(exists(&AUTOLOAD)) {
	local($@);
	eval q{
		our $AUTOLOAD;
		our @ISA;
		my $visit_point = sub{eval shift};
		sub AUTOLOAD {
			return if(substr($AUTOLOAD, -7, 7) eq 'DESTROY');
			my $sub_ref = Package::Autoloader::autoload_generic($visit_point, \@ISA, __PACKAGE__, $AUTOLOAD, @_);
			goto &$sub_ref;
		}
	};
	Carp::confess($@) if($@);
}
unless(exists(&can)) {
	local($@);
	eval q{
		our @ISA;
		my $visit_point = sub{eval shift};
		sub can {
			my $sub_ref = Package::Autoloader::can_generic($visit_point, \@ISA, __PACKAGE__, $_[0]);
			return($sub_ref);
		}
	};
	Carp::confess($@) if($@);
}
};
sub import {
	my ($class) = (shift);

	return unless (exists($_[0]));

	unless (ref($_[0]) eq 'CODE') {
		Carp::confess("Don't know what to do with '$_[0]'.\n");
	}
	my $subeval = shift;
	$subeval->($autoload_generic);
	Carp::confess($@) if($@);
}


sub debug {
	use Data::Dumper;
	print STDERR Dumper($RULES);
}


1;
