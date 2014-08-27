use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.001 qw( dztest );

# ABSTRACT: Make sure plugins do what they say they'll do

require Moose;
require Dist::Zilla::Role::Plugin;
require Dist::Zilla::Plugin::Bootstrap::lib;
require Dist::Zilla::Plugin::GatherDir;
require Dist::Zilla::Plugin::MetaConfig;

my $t   = dztest();
my $pn  = 'TestPlugin';
my $fpn = 'Dist::Zilla::Plugin::' . $pn;

$t->add_file( 'dist.ini', simple_ini( ['Bootstrap::lib'], ['GatherDir'], ['MetaConfig'], [$pn], ) );
$t->add_file( 'lib/Dist/Zilla/Plugin/BasePlugin.pm', <<"EOREOR" );
package #
  Dist::Zilla::Plugin::BasePlugin;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'lattr' => ( is => 'ro', 'lazy' => 1, default => sub { 'I have value, my life has meaning' } );
has 'attr' => ( is => 'ro', default => sub { 'I have value, my life has meaning' } );

around dump_config => config_dumper(__PACKAGE__, { attrs => [qw( attr )] });

no Moose;
1;
EOREOR

$t->add_file( 'lib/Dist/Zilla/Plugin/' . $pn . '.pm', <<"EOF");
package $fpn;

use Moose qw( has around extends );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
extends 'Dist::Zilla::Plugin::BasePlugin';

has 'childattr' => ( is => 'ro', default => sub { 'Rainbows and lollypops, etc' } );

around dump_config => config_dumper(__PACKAGE__, { attrs => [qw( childattr )] });

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF

$t->build_ok;
$t->meta_path_deeply(
  '/x_Dist_Zilla/plugins/*/*[ key eq \'class\' and value eq \'Dist::Zilla::Plugin::TestPlugin\' ]/../*[ key eq \'config\']',
  [
    {
      'Dist::Zilla::Plugin::TestPlugin' => { 'childattr' => 'Rainbows and lollypops, etc' },
      'Dist::Zilla::Plugin::BasePlugin' => { 'attr'      => 'I have value, my life has meaning' },
    }
  ],
  "Plugin list expected"
);
done_testing;

