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

	my $pre_selection = [$pkg_match, $sub_match];

	my $match_ref = ref($pkg_match);
	if($match_ref eq '') {
		$pre_selection->[0] =~ s/\w*[^\w\:].*$//s;
	} elsif ($match_ref eq 'CODE') {
		$pre_selection->[0] = ''; # unless we have a matching object
	}

	$match_ref = ref($sub_match);
	if($match_ref eq '') {
		$pre_selection->[1] = '';
		if ($sub_match =~ m/^([a-z0-9]*_)/i) {
			$pre_selection->[1] = $1 || '';
		}
	} elsif ($match_ref eq 'CODE') {
		$pre_selection->[1] = '';
	}
	$self->[ATB_PRE_SELECT] = $pre_selection;

	$self->[ATB_PKG_MATCH] = $self->create_matcher(0, $pkg_match, '::');
	$self->[ATB_SUB_MATCH] = $self->create_matcher(1, $sub_match, '_');

	Internals::SvREADONLY(@{$self}, 1);
	return($self);
}


sub pre_select {
	return(@{$_[0][ATB_PRE_SELECT]});
}


sub create_matcher {
	my ($self, $i, $name, $separator) = (shift, shift, shift, shift);

	my $matcher;
	my $name_ref = ref($name);
	if ($name_ref eq 'ARRAY') {
		$matcher = sub { scalar(grep($_ eq $_[$i], @$name)) > 0 };
	} elsif ($name_ref eq 'CODE') {
		$matcher = $name;
	} elsif (length($name) == 0) {
		$matcher = sub { 1 };
	} elsif ($name =~ m,[^\w\:],) {
		$matcher = sub { $_[$i] =~ m,$name,o };
	} elsif ($matcher = length($separator)
	and (substr($name, -$matcher, $matcher) eq $separator)) {
		my $l = length($name);
		$matcher = sub { ($name eq substr($_[$i], 0, $l)) };
	} else {
		$matcher = sub { ($_[$i] eq $name) };
	}

	return($matcher);
}


sub check {
	my ($self, $pkg_name, $sub_name) = (shift, shift, shift);

	return(undef) unless ($self->[ATB_PKG_MATCH]->($pkg_name, $sub_name, @_));
	return(undef) unless ($self->[ATB_SUB_MATCH]->($pkg_name, $sub_name, @_));

	if (defined($self->[ATB_ARGC_MATCH])
	and ($self->[ATB_ARGC_MATCH] != scalar(@_))) {
		return(undef);
	}

	my $args = $self->[ATB_ARGS_MATCH];
	foreach my $i (0 .. $#$args) {
		return(undef) unless (ref($_[$i]) eq $args->[$i]);
	}

	return($self->[ATB_GENERATOR]);
}


1;
