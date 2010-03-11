package Package::Autoloader::Generator::Export;
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

		my $sub_text = sprintf(q{
my ($only_defined_originals) = (shift(@_));
if ($only_defined_originals and !defined(&%s::%s)) {
	return(Package::Autoloader::Generator::failure('%s', '%s', '::Export [original does not exist]'));
}
my $sub_ref = \&%s::%s;
*%s = $sub_ref;
return($sub_ref);
		}, 
			$defining_pkg->name, $sub_name,
			$defining_pkg->name, $sub_name,
			$defining_pkg->name, $sub_name,
			$sub_name);

 		return($pkg->transport(\$sub_text, $ONLY_DEFINED_ORIGINALS));
	};
	my $self = [$generator];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

1;