package Package::Autoloader::Generator::SQL_Table;
use strict;
use warnings;
use parent qw(
	Package::Autoloader::Generator
);

sub ATB_PKG() { 0 };
sub ATB_DBH() { 1 };

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

my $select =  qq{
SELECT sub_prototype, sub_body
FROM _subroutines
WHERE (sub_name = ?)
AND (sub_event = 'on_demand')
AND ((sub_package = ?) OR ISNULL(sub_package))
AND ((sub_argc = ?) OR ISNULL(sub_argc))
ORDER BY sub_package DESC, sub_argc DESC
LIMIT 1};
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

my $std_sub = q{
	sub %s%s {
%s
	};
	return(\&%s);
};
sub implement {
	my ($self, $pkg, $sub_name) = (shift, shift, shift);

	my $rows = $self->[ATB_DBH]->selectall_arrayref($select, {}, $sub_name, $pkg->name, scalar(@_));
	unless (defined($rows)) {
		return(Package::Autoloader::Generator::failure(undef, $sub_name, '::SQL_Table [error in SQL statement?]'));
	}
	unless (scalar($rows)) {
		return(Package::Autoloader::Generator::failure(undef, $sub_name, '::SQL_Table [no record found]'));
	}
	my $row = shift(@$rows);

	my $code = sprintf($std_sub, 
		$sub_name,
		(defined($row->[0]) ? "($row->[0])" : ''),
		$row->[1],
		$sub_name);
	return($pkg->transport(\$code));
}

1;
