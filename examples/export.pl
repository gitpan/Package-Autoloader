use strict;

package Synopsis;
use Package::Autoloader sub{eval shift}, sub {
	$_[0]->export('::*', ['hello_world']);
};

sub hello_world() { print "Hello World.\n"; };

package Synopsis::Ex1;
use Package::Autoloader sub{eval shift};

print STDOUT (defined(&hello_world) ? 'Can':'Cannot'),"\n";
print STDOUT (potentially_defined('hello_world') ? 'Can':'Cannot'),"\n";

hello_world();

exit(0);
