package Package::Autoloader::Rule;
use strict;
use warnings;

sub ATB_GENERATOR() { 0 };
sub ATB_PRE_SELECT() { 1 };
sub ATB_PKG_MATCH() { 2 };
sub ATB_SUB_MATCH() { 3 };
sub ATB_ARGC_MATCH() { 4 };
sub ATB_ARGS_MATCH() { 5 };


sub new {
	my ($class, $generator, $pkg_match, $sub_match, $argc_match) =
		(shift, shift, shift, shift, shift);

	my $self = [$generator, undef, undef, undef, $argc_match, [@_]];
	bless($self, $class);

	my $pre_selection = [$pkg_match, ''];
	$pre_selection->[0] =~ s/\w*[^\w\:].*$//s;

	if($sub_match =~ m/^([a-z0-9]*_)/i) {
		$pre_selection->[1] = $1 || '';
	}
	$self->[ATB_PRE_SELECT] = $pre_selection;

	$self->[ATB_PKG_MATCH] = $self->create_matcher($pkg_match, '::');
	$self->[ATB_SUB_MATCH] = $self->create_matcher($sub_match, '_');

	Internals::SvREADONLY(@{$self}, 1);
	return($self);
}


sub pre_select {
	return(@{$_[0][ATB_PRE_SELECT]});
}


sub create_matcher {
	my ($self, $name, $separator) = (shift, shift, shift);

	my $matcher;
	if(length($name) == 0) {
		$matcher = sub { 1 };
	} elsif($name =~ m,[^\w\:],) {
		$matcher = sub { $_[0] =~ m,$name,o };
	} elsif((substr($name, -2, 2) eq $separator)
	or(substr($name, -1, 1) eq $separator)) {
		my $l = length($name);
		$matcher = sub { ($name eq substr($_[0], 0, $l)) };
	} else {
		$matcher = sub { ($_[0] eq $name) };
	}

	return($matcher);
}


sub check {
	my ($self, $pkg_name, $sub_name) = (shift, shift, shift);

	return(undef) unless ($self->[ATB_PKG_MATCH]->($pkg_name));
	return(undef) unless ($self->[ATB_SUB_MATCH]->($sub_name));

	if(defined($self->[ATB_ARGC_MATCH])
	and ($self->[ATB_ARGC_MATCH] != scalar(@_))) {
		return(undef);
	}

	my $args = $self->[ATB_ARGS_MATCH];
	foreach my $i (0 .. $#$args) {
		return(undef) unless(ref($_[$i]) eq $args->[$i]);
	}

	return($self->[ATB_GENERATOR]);
}


1;
