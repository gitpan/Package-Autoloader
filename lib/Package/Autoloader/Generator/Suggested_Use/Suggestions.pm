package Package::Autoloader::Generator::Suggested_Use::Suggestions;
use strict;
use warnings;

sub ATB_SUBROUTINES() { 0 };
sub ATB_MODULES() { 1 };
sub ATB_INDICES() { 2 };

sub new {
	my ($class) = @_;

	my $self = [{},[],{}];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	foreach my $line (<DATA>) {
		next if ($line =~ m,^[\s\t]*\#,);
		chomp($line);
		my @suggestion = split(/\t+/, $line, 5);
		$suggestion[1] = '' if ($suggestion[1] eq "''");
		next if (scalar(@suggestion) != 5);
		$self->add(\@suggestion);
	}
	close(DATA);
	return($self);
}

sub add {
	my $self = shift;
	foreach my $suggestion (@_) {
		my ($name, $type, $argc, $load, $module) = @$suggestion;
		unless (exists($self->[ATB_INDICES]{$module})) {
			push(@{$self->[ATB_MODULES]}, [$load, $module]);
			$self->[ATB_INDICES]{$module} = $#{$self->[ATB_MODULES]};
		}
		unless (exists($self->[ATB_SUBROUTINES]{$name})) {
			$self->[ATB_SUBROUTINES]{$name} = {};
		}
		$self->[ATB_SUBROUTINES]{$name}{$type}{$argc} =
			$self->[ATB_INDICES]{$module};
	}
	return;
}

sub lookup {
	my ($self) = shift;

	my $i = $self->lookup_index(@_);
	return(undef) unless (defined($i));
	return($self->[ATB_MODULES][$i]);
}

sub lookup_index {
	my ($self, $name, $type, $argc) = @_;

	unless (exists($self->[ATB_SUBROUTINES]{$name})) {
		return(undef);
	}
	my $candidates = $self->[ATB_SUBROUTINES]{$name};
	if (exists($candidates->{$type})) {
		my $candidates = $candidates->{$type};
		if (exists($candidates->{$argc})) {
			return($candidates->{$argc});
		}
		if (exists($candidates->{'*'})) {
			return($candidates->{'*'});
		}
	}
	if (exists($candidates->{'*'})) {
		my $candidates = $candidates->{'*'};
		if (exists($candidates->{$argc})) {
			return($candidates->{$argc});
		}
		if (exists($candidates->{'*'})) {
			return($candidates->{'*'});
		}
	}

	return(undef);
}

1;

__DATA__
#NAME		TYPE	ARGC	LOAD	MODULE
confess		''	*	use	Carp
croak		*	*	use	Carp
Dumper		*	*	use	Data::Dumper
scheme		OBJECT	*	parent	URI
uri_escape	*	*	use	URI::Escape
uri_unescape	*	*	use	URI::Escape
each_array	*	*	use	List::MoreUtils
each_arrayref	*	*	use	List::MoreUtils
julian_day	*	*	use	Time::Piece
ping_icmp	*	*	use	Net::Ping
soundex_noxs	*	*	use	Text::Soundex
soundex_nara	*	*	use	Text::Soundex
soundex_unicode	*	*	use	Text::Soundex
soundex_nara_unicode	*	*	use	Text::Soundex
pack_U		*	*	use	Unicode::Normalize
h1		*	*	use	CGI
start_html	*	*	use	CGI
cartesian_to_spherical	*	*	use	Math::Trig