#!/usr/bin/perl -W
use strict;
use Test::Simple tests => 1;

ok(1, 'You are dealing with an experimental module (Package::Autoloader).');
warn('You are dealing with an experimental module (Package::Autoloader).');
exit(0);
