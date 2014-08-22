use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ConfigDumper;

our $VERSION = '0.001001';

# ABSTRACT: Easy implementation of 'dumpconfig'

# AUTHORITY

use Try::Tiny qw( try catch );
use Sub::Exporter::Progressive -setup => { exports => [qw( config_dumper )], };

=function C<config_dumper>

  config_dumper( __PACKAGE__, qw( method list ) );

Returns a function suitable for use with C<around dump_config>.

  my $sub = config_dumper( __PACKAGE__, qw( method list ) );
  around dump_config => $sub;

Or

  around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    return config_dumper(__PACKAGE__, qw( method list ))->( $orig, $self, @args );
  };

Either way:

  my $function = config_dumper( $package_name_for_config, qw( methods to call on $self ));
  my $hash = $function->( $function_that_returns_a_hash, $instance_to_call_methods_on, @somethinggoeshere );

=~ All of this approximates:

  around dump_config => sub {
    my ( $orig , $self , @args ) = @_;
    my $conf = $self->$orig( @args );
    my $payload = {};

    for my $method ( @methods ) {
      try {
        $payload->{ $method } = $self->$method();
      };
    }
    $config->{+__PACKAGE__} = $payload;
  }

Except with some extra "things dun goofed" handling.

=cut

sub config_dumper {
  my ( $package, @methodnames ) = @_;
  my $CFG_PACKAGE = __PACKAGE__;
  return sub {
    my ( $orig, $self, @rest ) = @_;
    my $cnf     = $self->$orig(@rest);
    my $payload = {};
    my @fails;
    for my $method (@methodnames) {
      try {
        my $value = $self->$method();
        $payload->{$method} = $value;
      }
      catch {
        push @fails, $method;
      };
    }
    $cnf->{$package} = $payload;
    if (@fails) {
      $cnf->{$CFG_PACKAGE} = {} unless exists $cnf->{$CFG_PACKAGE};
      $cnf->{$CFG_PACKAGE}->{$package} = {} unless exists $cnf->{$CFG_PACKAGE};
      $cnf->{$CFG_PACKAGE}->{$package}->{failed} = \@fails;
    }
    return $cnf;
  };
}

1;

=head1 SYNOPSIS

  ...

  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

  around dump_config => config_dumper( __PACKAGE__, qw( foo bar baz ) );

=cut
