package Package::Autoloader::Generator::Closures_Demo;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);
# allow AUTOLOAD to eventually trigger AUTOLOAD?
our $ONLY_DEFINED_ORIGINALS = 1;

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		$sub_name =~ m,^(\w+)_(\d+)$,;
		my ($sub_base, $fixed_argument) = ($1, $2);
		my $sub_text = sprintf(q{
my ($only_defined_originals, $fixed_argument) = (shift(@_), shift(@_));
if ($only_defined_originals and !defined(&%s::%s)) {
	return(Package::Autoloader::Generator::failure('%s', '%s', '::Closures_Demo [original does not exist]'));
}
sub %s { return(%s::%s($fixed_argument, @_)); };
return(\&%s);
		}, 
			$defining_pkg->name, $sub_base,
			$defining_pkg->name, $sub_base,
			$sub_name,
			$defining_pkg->name, $sub_base,
			$sub_name);

		my $sub_ref = $pkg->transport
			(\$sub_text, $ONLY_DEFINED_ORIGINALS, $fixed_argument);
 		return($sub_ref);
	};

	my $self = [$generator];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

1;