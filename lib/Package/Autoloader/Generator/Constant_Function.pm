package Package::Autoloader::Generator::Constant_Function;
use strict;
use warnings;
use Scalar::Util;
#use parent qw(
#	Package::Autoloader::Generator
#);

sub ATB_TAKE_FROM() { 1 };
sub ATB_DATA() { 2 };

my $cf = q{sub %s() { q{%s} };};
sub implement {
	my ($self, $pkg, $sub_name) = (shift, shift, shift);

	my @names = ();
	my $generators = defined($self->[ATB_TAKE_FROM])
		? $pkg->collect_generators($self->[ATB_TAKE_FROM], $sub_name)
		: [$self];
	my $class = Scalar::Util::blessed($self);
	foreach my $generator (reverse(@$generators)) {
		next if($class ne Scalar::Util::blessed($generator));
		push(@names, @{$generator->[ATB_DATA]});
	}
	my $values = $self->determine($sub_name, \@names);

	my $sub_body = join("\n", map(sprintf($cf, @$_), @$values));
	return($sub_body);
}

sub configure {
	my ($self) = (shift);
	push(@{$self->[ATB_DATA]}, @_);
	return;
}

sub take_from {
	$_[0][ATB_TAKE_FROM] = $_[1];
	return;
}

sub _init {
	$_[0][ATB_TAKE_FROM] = '^';
	$_[0][ATB_DATA] = []; # no autobugification
	return;
}

1;
