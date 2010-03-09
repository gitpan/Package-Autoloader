package Package::Autoloader::Generator::Eponymous_Directory;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

my %DIRECTORIES = ();
sub pkg_directory($) {
	my ($pkg_name) = (shift);

	if(exists($DIRECTORIES{$pkg_name})) {
		return($DIRECTORIES{$pkg_name});
	}
	my $pkg_file = $pkg_name;
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

	$DIRECTORIES{$pkg_name} = $pkg_directory;
	return($pkg_directory);
}

sub new {
	my ($class, $defining_pkg) = (shift, shift);

	my $pkg_directory = pkg_directory($defining_pkg->name);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		my $file_name = "$pkg_directory/$sub_name.pl";
		my $code = "require shift(\@_); return(\\&$sub_name);";
 		return($pkg->transport(\$code, $file_name));
	};
	bless($generator, $class);
}


sub prototypes {
	my ($self, $pkg) = (shift, shift);

	my $file_name = pkg_directory($pkg->name) . '-prototypes.pl';
	my $code = "require shift(\@_);";
	$pkg->transport(\$code, $file_name);
}

sub matcher {
	my ($self, $pkg) = (shift, shift);

	my $pkg_directory = pkg_directory($pkg->name);
	opendir(D, $pkg_directory);
	my %pl_files = ();
	foreach my $file_name (readdir(D)) {
		next unless($file_name =~ m/^(\w+)\.pl$/i, );
		$pl_files{$1} = 1;
	}
	closedir(D);

	return(sub {
		return(exists($pl_files{$_[1]}));
	});
}

1;
