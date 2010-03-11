package Package::Autoloader::Generator::Eponymous_Tie;
use strict;
use warnings;
use SDBM_File;
use Fcntl;
use parent qw(
	Package::Autoloader::Generator
);

sub ATB_PKG() { 1 };
sub ATB_BASE_DIR() { 2 };

my %DIRECTORIES = ();
sub pkg_directory($) {
	my ($pkg_name) = (shift);

	if (exists($DIRECTORIES{$pkg_name})) {
		return($DIRECTORIES{$pkg_name});
	}
	my $pkg_file = $pkg_name;
	$pkg_file =~ s,::,/,sg;
	$pkg_file .= '.pm';

	my $pkg_directory = $INC{$pkg_file} || $pkg_file;
	$pkg_directory =~ s,\.pm$,,si;

	$DIRECTORIES{$pkg_name} = $pkg_directory;
	return($pkg_directory);
}

my $std_sub = q{
	sub %s%s {
%s
	};
	return(\&%s);
};
sub new {
	my ($class, $defining_pkg) = (shift, shift, shift);

	my $pkg_directory = pkg_directory($defining_pkg->name);
	tie(my %sub_bodies, 'SDBM_File', $pkg_directory, O_RDONLY, 0);

	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		unless (exists($sub_bodies{$sub_name})) {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, "::Eponymous_Tie [not in '$pkg_directory']"));
		}
		my $prototype = '';
		if (exists($sub_bodies{"$sub_name-prototype"})) {
			$prototype = '('.$sub_bodies{"$sub_name-prototype"}.')';
		}

		my $code = sprintf($std_sub, 
			$sub_name,
			$prototype,
			$sub_bodies{$sub_name},
			$sub_name);
 		return($pkg->transport(\$code));
	};
	my $self = [$generator, $defining_pkg, $pkg_directory];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

sub prototypes {
	my ($self) = (shift);

	tie(my %sub_bodies, 'SDBM_File', $self->[ATB_BASE_DIR], O_RDONLY, 0);

	my $code = '';
	foreach my $key (keys(%sub_bodies)) {
		next unless ($key =~ m,^(\w+)-prototype,);
		$code .= sprintf('sub %s(%s); ', $1, $sub_bodies{$key});
	}
	$self->[ATB_PKG]->transport(\$code);
}

sub matcher {
	my ($self) = (shift);

	tie(my %sub_bodies, 'SDBM_File', $self->[ATB_BASE_DIR], O_RDONLY, 0);
	return(sub {
		return(exists($sub_bodies{$_[1]}));
	});
}

1;