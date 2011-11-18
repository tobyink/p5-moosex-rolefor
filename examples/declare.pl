use 5.010;
use MooseX::Declare;
use MooseX::RoleFor::Declare;

role Example::Role for Example::Class for Example::Class3 {
}

class Example::Class with Example::Role {
}

class Example::Class2 {
}


{
	package main;
	use Moose::Util qw/apply_all_roles/;
	my $obj = Example::Class2->new;
	apply_all_roles($obj, 'Example::Role');
}
