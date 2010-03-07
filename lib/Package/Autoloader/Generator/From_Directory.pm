package Package::Autoloader::Generator::From_Directory;
use strict;
use warnings;
use Scalar::Util;
use parent qw(
	Package::Autoloader::Generator
);

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $pkg_file = $defining_pkg->name;
	$pkg_file =~ s,::,/,sg;
	$pkg_file .= '.pm';

	my $pkg_directory = $INC{$pkg_file} || $pkg_file;
	$pkg_directory =~ s,\.pm$,,si;
	
	unless(-e $pkg_directory) {
		Carp::confess("Can't load from directory '$pkg_directory' - does not exist.");
	}
	unless(-d $pkg_directory) {
		Carp::confess("Can't load from directory '$pkg_directory' - not a directory.");
	}

	my $generator = sub {
		my ($pkg, $sub_name, $argc) = (shift, shift, shift);

		my $file_name = "$pkg_directory/$sub_name.pl";
		my $code = "require shift(\@_); return(\\&$sub_name);";
 		return($pkg->transport(\$code, $file_name));
	};
	bless($generator, $class);
}

1;
