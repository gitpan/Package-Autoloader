package Package::Autoloader::Generator::Eponymous_Directory;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub ATB_PKG() { 0 };
sub ATB_BASE_DIR() { 1 };

my %DIRECTORIES = ();
sub eponymous_base_dir($) {
	my ($pkg_name) = (shift);

	if (exists($DIRECTORIES{$pkg_name})) {
		return($DIRECTORIES{$pkg_name});
	}
	my $pkg_file = $pkg_name;
	$pkg_file =~ s,::,/,sg;
	$pkg_file .= '.pm';

	my $base_dir = $INC{$pkg_file} || $pkg_file;
	$base_dir =~ s,\.pm$,,si;
	
	unless (-e $base_dir) {
		Carp::confess("Can't load from directory '$base_dir' - does not exist.");
	}
	unless (-d $base_dir) {
		Carp::confess("Can't load from directory '$base_dir' - not a directory.");
	}

	$DIRECTORIES{$pkg_name} = $base_dir;
	return($base_dir);
}

sub _init {
	my ($self, $defining_pkg) = (shift, shift);

	$self->[ATB_BASE_DIR] = eponymous_base_dir($defining_pkg->name);
	return;
}

sub prototypes {
	my ($self) = (shift);

	my $file_name = $self->[ATB_BASE_DIR] . '/-prototypes.pl';
	my $code = "require shift(\@_);";
	$self->[ATB_PKG]->transport(\$code, $file_name);
}

sub matcher {
	my ($self) = (shift);

	opendir(D, $self->[ATB_BASE_DIR]);
	my %pl_files = ();
	foreach my $file_name (readdir(D)) {
		next unless ($file_name =~ m/^(\w+)\.pl$/i, );
		$pl_files{$1} = 1;
	}
	closedir(D);

	return(sub {
		return(exists($pl_files{$_[1]}));
	});
}

sub implement {
	my ($self, $pkg, $sub_name) = (shift, shift, shift);

	my $file_name = "$self->[ATB_BASE_DIR]/$sub_name.pl";
	my $code = "require shift(\@_); return(\\&$sub_name);";
	return($pkg->transport(\$code, $file_name));
}

1;
