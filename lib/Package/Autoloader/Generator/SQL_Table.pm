package Package::Autoloader::Generator::SQL_Table;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub ATB_PKG() { 1 };
sub ATB_DBH() { 2 };

my $select =  qq{
SELECT sub_prototype, sub_body
FROM _subroutines
WHERE (sub_name = ?)
AND (sub_event = 'on_demand')
AND ((sub_package = ?) OR ISNULL(sub_package))
AND ((sub_argc = ?) OR ISNULL(sub_argc))
ORDER BY sub_package DESC, sub_argc DESC
LIMIT 1};

my $std_sub = q{
	sub %s%s {
%s
	};
	return(\&%s);
};
sub new {
	my ($class, $defining_pkg, $dbh) = (shift, shift, shift);

	my $sth = $dbh->prepare($select);
	my $generator = sub {
		my ($pkg, $sub_name) = (shift, shift);

		my $rv = $sth->execute($sub_name, $pkg->name, scalar(@_));
		unless (defined($rv)) {
			Carp::confess($DBI::errstr);
		}
		my $row = $sth->fetchrow_arrayref;
		unless (defined($row)) {
			return(Package::Autoloader::Generator::failure(undef, $sub_name, '::SQL_Table'));
		}

		my $code = sprintf($std_sub, 
			$sub_name,
			(defined($row->[0]) ? "($row->[0])" : ''),
			$row->[1],
			$sub_name);
 		return($pkg->transport(\$code));
	};
	my $self = [$generator, $defining_pkg, $dbh];
	bless($self, $class);
	Internals::SvREADONLY(@{$self}, 1);

	return($self);
}

my $prototypes =  qq{
SELECT sub_name, sub_prototype
FROM _subroutines
WHERE (sub_event = 'on_demand')
AND NOT ISNULL(sub_prototype)
AND ((sub_package = ?) OR ISNULL(sub_package))
};
sub prototypes {
	my ($self) = (shift);

	my $rows = $self->[ATB_DBH]->selectall_arrayref($prototypes, {}, $self->[ATB_PKG]->name);
	my $code = '';
	foreach my $row (@$rows) {
		$code .= sprintf('sub %s(%s); ', @$row);
	}
	$self->[ATB_PKG]->transport(\$code);
}

sub matcher {
	my ($self) = (shift);

	my $sth = $self->[ATB_DBH]->prepare($select);
	return(sub {
		my $rv = $sth->execute($_[1], $_[0], scalar(@_));
		unless (defined($rv)) {
			Carp::confess($DBI::errstr);
		}
		my $row = $sth->fetchrow_arrayref;
		return unless (defined($row));

	});
}

1;