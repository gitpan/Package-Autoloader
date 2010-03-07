#!/usr/bin/perl -W -T
use strict;

use Package::Autoloader sub{eval shift}, sub {
	my $generator = q{
		my $name = substr($sub_name, 4);
		my $sub_text = sprintf(q{
			my $self = shift;
			$self->{%s} = shift;
		}, $name);
 		return($sub_text);
	};
	$_[0]->register_rule($generator, '*', 'set_');
};

my $obj = bless( {}, 'main');
$obj->set_world(1);

use Data::Dumper;
print STDERR Dumper($obj);

exit(0);
