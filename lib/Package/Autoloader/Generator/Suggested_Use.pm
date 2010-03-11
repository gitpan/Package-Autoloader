package Package::Autoloader::Generator::Suggested_Use;
use strict;
use warnings;
use Scalar::Util qw();
use Package::Autoloader::Generator::Suggested_Use::Suggestions;
use parent qw(
	Package::Autoloader::Generator
);
our $VERBOSE = 1;

sub ATB_SUGGESTSIONS() { 1 };

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $suggestions = scalar(@_) ? shift :
		Package::Autoloader::Generator::Suggested_Use::Suggestions->new();	

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		my $ref = Scalar::Util::blessed($_[0]) ? 'OBJECT' : ref($_[0]);
		my $suggested = $suggestions->lookup($sub_name, $ref, scalar(@_));

		unless (defined($suggested)) {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, '::Suggested_Use [no suggestion found]'));
		}
		my ($load, $module) = @$suggested;

		my $sub_text;
		if ($load eq 'use') {
			$sub_text = sprintf(q{
my $verbose = shift(@_);
print STDERR qq{Loading suggested module '%s' to enable subroutine '%s'.\n} if ($verbose);
use %s;
return(\&%s) if (defined(&%s));
return(\&%s::%s) if (defined(&%s::%s));
return(Package::Autoloader::Generator::failure(undef, '%s', q{::Suggested_Use ['use %s' had not the required effect]}));
		},
			$module, $sub_name,
			$module,
			$sub_name, $sub_name, 
			$module, $sub_name, $module, $sub_name,
			$sub_name, $module);
		} elsif ($load eq 'parent') {
			$sub_text = sprintf(q{
my $verbose = shift(@_);
print STDERR qq{Loading suggested parent '%s' to enable method '%s'.\n} if ($verbose);
use parent qw(%s);
my $can = UNIVERSAL::can($_[0], '%s');
return($can) if (defined($can));
return(Package::Autoloader::Generator::failure(undef, '%s', q{::Suggested_Use ['use parent qw(%s)' had not the required effect]}));
		},
			$module, $sub_name,
			$module,
			$sub_name,
			$sub_name, $module);
		} else {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, "::Suggested_Use [invalid loading '$load']"));
		}

 		return($pkg->transport(\$sub_text, $VERBOSE, $_[0]));
	};
	my $self = [$generator, $suggestions];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

sub matcher {
	my ($self) = (shift);

	return(sub {
		my $ref = Scalar::Util::blessed($_[2]) ? 'OBJECT' : ref($_[2]);
		return (defined($self->[ATB_SUGGESTSIONS]->lookup($_[1], $ref, scalar(@_)-2)));

	});
}

1;