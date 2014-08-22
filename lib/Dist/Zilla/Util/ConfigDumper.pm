use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Util::ConfigDumper;

our $VERSION = '0.002001';

# ABSTRACT: Easy implementation of 'dumpconfig'

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Carp qw( croak );
use Try::Tiny qw( try catch );
use Sub::Exporter::Progressive -setup => { exports => [qw( config_dumper )], };

sub config_dumper {
  my ( $package, @methodnames ) = @_;
  my (@tests) = map { _mk_test( $package, $_ ) } @methodnames;
  my $CFG_PACKAGE = __PACKAGE__;
  return sub {
    my ( $orig, $self, @rest ) = @_;
    my $cnf     = $self->$orig(@rest);
    my $payload = {};
    my @fails;
    for my $test (@tests) {
      $test->( $self, $payload, \@fails );
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

sub _mk_method_test {
  my ( undef, $methodname ) = @_;
  return sub {
    my ( $instance, $payload, $fails ) = @_;
    try {
      my $value = $instance->$methodname();
      $payload->{$methodname} = $value;
    }
    catch {
      push @{$fails}, $methodname;
    };
  };
}

sub _mk_attribute_test {
  my ( undef, $attrname ) = @_;
  return sub {
    my ( $instance, $payload, $fails ) = @_;
    try {
      my $metaclass           = $instance->meta;
      my $attribute_metaclass = $metaclass->get_attribute($attrname);
      if ( $attribute_metaclass->has_value($instance) ) {
        $payload->{$attrname} = $attribute_metaclass->get_value($instance);
      }
    }
    catch {
      push @{$fails}, $attrname;
    };
  };
}

sub _mk_hash_test {
  my ( $package, $hash ) = @_;
  my @out;
  if ( exists $hash->{attrs} and 'ARRAY' eq ref $hash->{attrs} ) {
    push @out, map { _mk_attribute_test( $package, $_ ) } @{ $hash->{attrs} };
  }
  return @out;
}

sub _mk_test {
  my ( $package, $methodname ) = @_;
  return _mk_method_test( $package, $methodname ) if not ref $methodname;
  return $methodname if 'CODE' eq ref $methodname;
  return _mk_hash_test( $package, $methodname ) if 'HASH' eq ref $methodname;
  croak "Don't know what to do with $methodname";
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::ConfigDumper - Easy implementation of 'dumpconfig'

=head1 VERSION

version 0.002001

=head1 SYNOPSIS

  ...

  with 'Dist::Zilla::Role::Plugin';
  use Dist::Zilla::Util::ConfigDumper qw( config_dumper );

  around dump_config => config_dumper( __PACKAGE__, qw( foo bar baz ) );

=head1 FUNCTIONS

=head2 C<config_dumper>

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

=head1 ADVANCED USE

=head2 CALLBACKS

Internally

  config_dumper( $pkg, qw( method list ) );

Maps to a bunch of subs, so its more like:

  config_dumper( $pkg, sub {
    my ( $instance, $payload ) = @_;
    $payload->{'method'} = $instance->method;
  }, sub {
    $_[1]->{'list'} = $_[0]->list;
  });

So if you want to use that because its more convenient for some problem, be my guest.

  around dump_config => config_dumper( __PACKAGE__, sub {
    $_[1]->{'x'} = 'y'
  });

is much less ugly than

  around dump_config => sub {
    my ( $orig, $self, @args ) = @_;
    my $conf = $self->$orig(@args);
    $config->{+__PACKAGE__} = { # if you forget the +, things break
       'x' => 'y'
    };
    return $config;
  };

=head2 DETAILED CONFIGURATION

There's an additional feature for advanced people:

  config_dumper( $pkg, \%config );

=head3 C<attrs>

  config_dumper( $pkg, { attrs => [qw( foo bar baz )] });

This is for cases where you want to deal with C<Moose> attributes,
but want added safety of B<NOT> loading attributes that have no value yet.

For each item in C<attrs>, we'll call C<Moose> attribute internals to determine
if the attribute named has a value, and only then will we fetch it.

=head1 AUTHOR

Kent Fredric <kentfredric@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
