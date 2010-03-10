#!/usr/bin/perl -W -T
use strict;
# just for completeness... you don't save much by postponing compilation

use Package::Autoloader;

# this could be hidden in a generator class, but it's of no practical use

{
	my $pkg = Package::Autoloader->new(sub{eval shift});
	my $buffer = join('', <DATA>);
	my @matches = ($buffer =~ m,(?:^|\n)([\s\t]*sub[\s\t]*(\w+)[\s\t]*(\([^\)]*\))?[\s\t]*{[\s\t]*.*?\n[\s\t]*}[\s\t]*;?[\s\t]*\n+),sg);
	my %subroutines = ();
	while (scalar(@matches)) {
		my ($body, $name, $prototype) = splice(@matches, -3);
		$subroutines{$name} = [$prototype, $body];
	}
	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);
		unless (exists($subroutines{$sub_name})) {
			Carp::confess("No subroutine '$sub_name' in __DATA__.");
		}
		# FIXME: also check prototype
		my $code = $subroutines{$sub_name}->[1]
			. "\nreturn(\\&$sub_name);";
		return($pkg->transport(\$code));
	};
	$pkg->register_rule($generator, '=', [keys(%subroutines)]);
};

yn(potentially_defined('hello_worlds'));
yn(potentially_defined('hello_world'));
yn(defined(&hello_world));

hello_world();

yn(defined(&hello_world));
exit(0);

__DATA__
sub yn {
	print STDOUT ($_[0] ? 'Yes' : 'No'), "\n";
}
sub hello_world {
	print "Hello World.\n";
}
sub hello_world {
	print "Hello World.\n";
}
sub salut_monde {
	print "Hello World.\n";
}