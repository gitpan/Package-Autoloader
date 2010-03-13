package Package::Autoloader::Rule::Gone;
use strict;
use warnings;

sub new		{	return(bless([], __PACKAGE__));	}
my @nothing = ([], []);
sub pre_select	{	return(@nothing);		}
sub release	{	return;				}
sub check	{	return(undef);			}

1;
