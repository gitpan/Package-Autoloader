package Package::Autoloader::Search_Path;
use strict;
use warnings;

sub ATB_PATH() { 0 };
sub ATB_123() { 1 };

sub package_hierarchy {
	my $name = shift;
	my @hierarchy = ($name);
	while($name =~ s,\w+(::)?$,,s) {
		push(@hierarchy, $name);
	}
	return(\@hierarchy);
}

sub new {
	my ($class, $pkg_name) = @_;

	my $search = package_hierarchy($pkg_name);
	my $self = [$search, [0, 1, 1, $#$search-1, $#$search, 1]];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

sub path { return($_[0][ATB_PATH]); };

sub first {
	my $self = shift;
	my $count = scalar(@_);
	my $s123 = $self->[ATB_123];
	unshift(@{$self->[ATB_PATH]}, @_);
	$s123->[0] += $count;
	$s123->[2] += $count;
	$s123->[4] += $count;
	return;
}

sub not_self {
	my $self = shift;
	my $s123 = $self->[ATB_123];
	return unless($s123->[1]);
	splice(@{$self->[ATB_PATH]}, $s123->[0], 1);
	$s123->[4] -= 1;
	$s123->[2] -= 1;
	$s123->[1] = 0;
	return;
}

sub second {
	my $self = shift;
	my $s123 = $self->[ATB_123];
	my $count = scalar(@_);
	splice(@{$self->[ATB_PATH]}, $s123->[2], 0, @_);
	$s123->[4] += $count;
	return;
}

sub not_hierarchy {
	my $self = shift;
	my $s123 = $self->[ATB_123];
	return unless($s123->[3]);
	splice(@{$self->[ATB_PATH]}, $s123->[2], $s123->[3]);
	$s123->[4] -= $s123->[3];
	$s123->[3] = 0;
	return;
}

sub third {
	my $self = shift;
	my $count = scalar(@_);
	splice(@{$self->[ATB_PATH]}, $self->[ATB_123][4], 0, @_);
	$self->[ATB_123][4] += $count;
	return;
}

sub not_globally {
	my $self = shift;
	my $s123 = $self->[ATB_123];
	return unless($s123->[5]);
	splice(@{$self->[ATB_PATH]}, $s123->[4], 1);
	$s123->[5] = 0;
	return;
}

sub fourth {
	my $self = shift;
	push(@{$self->[ATB_PATH]}, @_);
	return;
}

#sub DESTROY {
#	use Data::Dumper;
#	print STDERR Dumper($_[0]);
#}

1;
