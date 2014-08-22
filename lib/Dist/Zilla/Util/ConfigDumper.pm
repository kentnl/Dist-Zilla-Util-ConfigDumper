use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ConfigDumper;

our $VERSION = '0.001000';

# ABSTRACT: Easy implemention of 'dumpconfig'

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Try::Tiny qw( try catch );
use Sub::Exporter::Progressive -setup => {
  exports => [qw( config_dumper )],
};

sub config_dumper {
  my ( $package, @methodnames ) = @_;
  return sub {
      my ( $orig, $self, @rest ) = @_;
      my $cnf = $self->$orig(@rest);
      my $payload = {};
      my @fails;
      for my $method ( @methodnames ) {
        try {
          my $value = $self->$method();
          $payload->{ $method } = $value;
        } catch {
          push @fails, $method;
        };
      }
      $cnf->{$package} = $payload;
      if ( @fails ) {
        $cnf->{+__PACKAGE__} = {} unless exists $cnf->{__PACKAGE__};
        $cnf->{+__PACKAGE__}->{$package} = {} unless exists $cnf->{__PACKAGE__};
        $cnf->{+__PACKAGE__}->{$package}->{failed} = \@fails;
      };
      return $cnf;
  };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ConfigDumper - Easy implemention of 'dumpconfig'

=head1 VERSION

version 0.001000

=head1 SYNOPSIS

  ...

  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

  around dump_config => config_dumper( __PACKAGE__, qw( foo bar baz ) );

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
