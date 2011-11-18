use Test::More;
use Test::Pod::Coverage;

my @modules = qw(MooseX::RoleFor MooseX::RoleFor::Meta::Role::Trait::RoleFor);
pod_coverage_ok($_, "$_ is covered")
	foreach @modules;
done_testing(scalar @modules);

