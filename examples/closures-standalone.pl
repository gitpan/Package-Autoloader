#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	my $calc_generic = sub {
		my ($correction, $a, $b) = @_;
		return($a * $correction/100 + $b);
	};
	my $generator = sub {
		my ($pkg, $sub_name, $argc) = (shift, shift, shift);
		my $argument = substr($sub_name, 5) || 100;
		my $sub_text = sprintf(q{
my ($calc_generic, $arg1) = (shift(@_), shift(@_));
sub %s { return($calc_generic->($arg1, @_)); };
return(\&%s);
		}, $sub_name, $sub_name);

		my $sub_ref = $pkg->transport(\$sub_text,
			$calc_generic, $argument);
 		return($sub_ref);
	};
	$_[0]->register_rule($generator, '*', 'calc_');
};

print calc_5(7, 8);
exit(0);
