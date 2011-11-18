use 5.010;
use MooseX::Declare;
use MooseX::RoleFor;

BEGIN {
	$MooseX::RoleFor::Declare::AUTHORITY = 'cpan:TOBYINK';
	$MooseX::RoleFor::Declare::VERSION   = '0.000_01';
}

{
	package MooseX::RoleFor::Declare;
	use Carp qw[croak];
	no warnings 'redefine';
	
	# VERY NASTY HACK: REDEFINE SUB JUST TO ALTER A SINGLE REGEXP!
	sub MooseX::Declare::Context::WithOptions::strip_options
	{
		my ($self) = @_;
		my %ret;

		# Make errors get reported from right place in source file
		local $Carp::Internal{'MooseX::Declare'} = 1;
		local $Carp::Internal{'Devel::Declare'} = 1;

		$self->skipspace;
		my $linestr = $self->get_linestr;

		while (substr($linestr, $self->offset, 1) !~ /[{;]/) {
			my $key = $self->strip_name;
			if (!defined $key) {
				croak 'expected option name'
					if keys %ret;
				return; # This is the case when { class => 'foo' } happens
			}

			# THIS IS THE OFFENDING REGEXP!
			croak "unknown option name '$key'"
				unless $key =~ /^(extends|with|is|for)$/;
			# an improvement might be:
			# unless grep { $key eq $_ } $self->allowed_options;

			my $val = $self->strip_name;
			if (!defined $val) {
				if (defined($val = $self->strip_proto)) {
					$val = [split /\s*,\s*/, $val];
				}
				else {
					croak "expected option value after $key";
				}
			}

			$ret{$key} ||= [];
			push @{ $ret{$key} }, ref $val ? @{ $val } : $val;
		} continue {
			$self->skipspace;
			$linestr = $self->get_linestr();
		}

		my $options = { map {
			my $key = $_;
			$key eq 'is'
				? ($key => { map { ($_ => 1) } @{ $ret{$key} } })
				: ($key => $ret{$key})
			} keys %ret };

		$self->options($options);

		return $options;
	}
}

{
	package MooseX::RoleFor::Declare::Syntax::RoleForApplication;
	use Moose::Role;
	use MooseX::RoleFor::Meta::Role::Trait::RoleFor;
	
	sub add_for_option_customizations
	{
		my ($self, $ctx, $package, $classes) = @_;
		my @code_parts;
		push @code_parts, sprintf("use MooseX::RoleFor");
		push @code_parts, sprintf(
			"role_for([%s])\n",
			join ', ',
				map { "q/$_/" }
				map { $ctx->qualify_namespace($_) }
				@{ ref $classes ? $classes : [$classes] }
			);
		$ctx->add_scope_code_parts(@code_parts);
		return 1;
	}
}

BEGIN {
	use Moose::Util qw/apply_all_roles/;
	apply_all_roles('MooseX::Declare::Syntax::Keyword::Role',
		'MooseX::RoleFor::Declare::Syntax::RoleForApplication');
}

1;

__END__

=head1 NAME

MooseX::ForRole::Declare - extend MooseX::Declare to offer MooseX::ForRole feature

=head1 SYNOPSIS

  use MooseX::Declare;
  use MooseX::RoleFor::Declare;
  
  role Watchdog for Dog {
    requires 'make_noise';
    method on_intruder {
      $self->make_noise;
    }
  }
  
  role FireAlarm
    for Dog
    for SmokeDetector
  {
    requires 'make_noise';
    method on_fire {
      $self->make_noise;
    }
  }

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=MooseX-RoleFor>.

=head1 SEE ALSO

L<MooseX::Declare>, L<MooseX::RoleFor>.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2011 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
