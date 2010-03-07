#!/usr/bin/perl -W -T
use strict;

package A::B::C;
# default search:
# 	A::B::C
# 	A::B::
# 	A::
# 	''
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->search->first('D');	# D before A::B::C
	$_[0]->search->not_self;	# no A::B::C
	$_[0]->search->second('E');	# E after A::B::C
	$_[0]->search->not_hierarchy;	# no A::B::, A::
	$_[0]->search->third('F');	# F before ''
	$_[0]->search->not_globally;	# no ''
	$_[0]->search->last('G');	# G after ''

	use Data::Dumper;
	print STDERR Dumper($_[0]);
};
