package Package::Autoloader::Pre_Selection;
use strict;
use warnings;
use Carp qw();

sub new { bless({}, __PACKAGE__); }

sub register_rule {
	my ($self, $pkg_name, $sub_name, $rule) = @_;

	if ( length($pkg_name) and ($pkg_name !~ m,^((\w+)($|\:\:))+$,)) {
		Carp::confess("Package name '$pkg_name' is not valid.\n");
	}
	$self->{$pkg_name} = {} unless(exists($self->{$pkg_name}));

	my $pkg_rules = $self->{$pkg_name};
	unless($sub_name =~ m,^\w*$,) {
		Carp::confess("Subroutine name '$sub_name' is not valid.\n");
	}
	$pkg_rules->{$sub_name} = [] unless(exists($pkg_rules->{$sub_name}));
	my $sub_rules = $pkg_rules->{$sub_name};

	push(@$sub_rules, $rule);
	return;
}


sub lookup_rule {
	my ($self, $pkg_list, $pkg_name, $sub_name) =
		(shift, shift, shift, shift);

	foreach my $pkg_prefix (@$pkg_list) {
		next unless(exists($self->{$pkg_prefix}));
		my $pkg_rules = $self->{$pkg_prefix};

		my $sub_rules = undef;
		if(exists($pkg_rules->{$sub_name})) {
			$sub_rules = $pkg_rules->{$sub_name};
		} else {
			$sub_name =~ m,^([a-z0-9]*_),i;
			my $sub_prefix = $1 || '';
			if(exists($pkg_rules->{$sub_prefix})) {
				$sub_rules = $pkg_rules->{$sub_prefix};
			} elsif(exists($pkg_rules->{''})) {
				$sub_rules = $pkg_rules->{''};
			}
		}
		next unless(defined($sub_rules));

		foreach my $rule (@$sub_rules) {
			my $generator = $rule->check($pkg_prefix, $sub_name, @_);
			next unless(defined($generator));
			return($generator);
		}
	}
	return(undef);
}


#sub dump {
#	use Data::Dumper;
#	print STDERR Dumper(\@_);
#}


1;
