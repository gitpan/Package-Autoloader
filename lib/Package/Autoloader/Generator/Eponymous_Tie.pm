package Package::Autoloader::Generator::Eponymous_Tie;
use strict;
use warnings;
use GDBM_File;
use Fcntl;
use parent qw(
	Package::Autoloader::Generator
);

sub ATB_PKG() { 0 };
sub ATB_DB_FILE() { 1 };
sub ATB_SUB_BODIES() { 2 };

my %DIRECTORIES = ();
sub eponymous_db_file($) {
	my ($pkg_name) = (shift);

	if (exists($DIRECTORIES{$pkg_name})) {
		return($DIRECTORIES{$pkg_name});
	}
	my $pkg_file = $pkg_name;
	$pkg_file =~ s,::,/,sg;
	$pkg_file .= '.pm';

	my $file_name = $INC{$pkg_file} || $pkg_file;
	$file_name =~ s,\.pm$,.dbm,si;

	$DIRECTORIES{$pkg_name} = $file_name;
	return($file_name);
}

sub _init {
	my ($self, $defining_pkg) = (shift, shift);

	my $file_name = eponymous_db_file($defining_pkg->name);
	tie(my %sub_bodies, 'GDBM_File', $file_name, O_RDONLY, 0);

	$self->[ATB_DB_FILE] = $file_name;
	$self->[ATB_SUB_BODIES] = \%sub_bodies;
	return;
}

sub prototypes {
	my ($self) = (shift);

	my $code = '';
	foreach my $key (keys(%{$self->[ATB_SUB_BODIES]})) {
		next unless ($key =~ m,^(\w+)-prototype,);
		$code .= sprintf('sub %s(%s); ',
			$1, $self->[ATB_SUB_BODIES]->{$key});
	}
	$self->[ATB_PKG]->transport(\$code);
}

sub matcher {
	my ($self) = (shift);

	return(sub {
		return(exists($self->[ATB_SUB_BODIES]->{$_[1]}));
	});
}

my $std_sub = q{
	sub %s%s {
%s
	};
	return(\&%s);
};
sub implement {
	my ($self, $pkg, $sub_name) = (shift, shift, shift);

	my $sub_bodies = $self->[ATB_SUB_BODIES];
	unless (exists($sub_bodies->{$sub_name})) {
		return(Package::Autoloader::Generator::failure(undef, $sub_name, "::Eponymous_Tie [not in '$self->[ATB_DB_FILE]']"));
	}
	my $prototype = '';
	if (exists($sub_bodies->{"$sub_name-prototype"})) {
		$prototype = '('.$sub_bodies->{"$sub_name-prototype"}.')';
	}

	my $code = sprintf($std_sub, 
		$sub_name,
		$prototype,
		$sub_bodies->{$sub_name},
		$sub_name);
	return($pkg->transport(\$code));
}

1;
