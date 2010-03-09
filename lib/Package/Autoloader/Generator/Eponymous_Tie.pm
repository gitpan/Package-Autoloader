package Package::Autoloader::Generator::Eponymous_Tie;
use strict;
use warnings;
use SDBM_File;
use parent qw(
	Package::Autoloader::Generator
);

my $std_sub = q{
	sub %s {
%s
	};
	return(\&%s);
};
sub new {
	my ($class, $defining_pkg) = (shift, shift, shift);

	my $pkg_file = $defining_pkg->name;
	$pkg_file =~ s,::,/,sg;
	$pkg_file .= '.pm';

	my $pkg_directory = $INC{$pkg_file} || $pkg_file;
	$pkg_directory =~ s,\.pm$,,si;
	tie(my %sub_bodies, 'SDBM_File', $pkg_directory, 1, 0640);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		unless(exists($sub_bodies{$sub_name})) {
			Carp::confess("No sub '$sub_name'");
		}

		my $code = sprintf($std_sub, 
			$sub_name,
			$sub_bodies{$sub_name},
			$sub_name);
 		return($pkg->transport(\$code));
	};
	bless($generator, $class);
}

sub matcher {
	my ($self, $defining_pkg) = (shift, shift);

	tie(my %sub_bodies, 'SDBM_File', $defining_pkg->name, 1, 0640);
	return(sub {
		return(exists($sub_bodies{$_[1]}));
	});
}

1;

