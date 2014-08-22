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

subtest 'unspecificied lazy' => sub {
  my $t   = dztest();
  my $pn  = 'TestPlugin';
  my $fpn = 'Dist::Zilla::Plugin::' . $pn;

  $t->add_file( 'dist.ini', simple_ini( ['Bootstrap::lib'], ['GatherDir'], ['MetaConfig'], [$pn], ) );
  $t->add_file( 'lib/Dist/Zilla/Plugin/' . $pn . '.pm', <<"EOF");
package $fpn;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'attr' => ( is => 'ro', 'lazy' => 1, default => sub { 'I have value, my life has meaning' } );
has 'nlattr' => ( is => 'ro', default => sub { 'nonlazy' } );

around dump_config => config_dumper(__PACKAGE__, { attrs => [qw( attr nlattr )] });

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF

  $t->build_ok;
  $t->meta_path_deeply(
    '/x_Dist_Zilla/plugins/*/*[ key eq \'class\' and value eq \'Dist::Zilla::Plugin::TestPlugin\' ]/../*[ key eq \'config\']',
    [ { 'Dist::Zilla::Plugin::TestPlugin' => { nlattr => 'nonlazy' } } ],
    "Plugin list expected"
  );

};

subtest 'specificied lazy' => sub {
  my $t   = dztest();
  my $pn  = 'TestPlugin';
  my $fpn = 'Dist::Zilla::Plugin::' . $pn;

  $t->add_file( 'dist.ini', simple_ini( ['Bootstrap::lib'], ['GatherDir'], ['MetaConfig'], [ $pn, { attr => 'user' } ], ) );
  $t->add_file( 'lib/Dist/Zilla/Plugin/' . $pn . '.pm', <<"EOF");
package $fpn;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'attr' => ( is => 'ro', 'lazy' => 1, default => sub { 'I have value, my life has meaning' } );
has 'nlattr' => ( is => 'ro', default => sub { 'nonlazy' } );

around dump_config => config_dumper(__PACKAGE__, { attrs => [qw( attr nlattr )] });

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF

  $t->build_ok;
  $t->meta_path_deeply(
    '/x_Dist_Zilla/plugins/*/*[ key eq \'class\' and value eq \'Dist::Zilla::Plugin::TestPlugin\' ]/../*[ key eq \'config\']',
    [ { 'Dist::Zilla::Plugin::TestPlugin' => { attr => 'user', nlattr => 'nonlazy' } } ],
    "Plugin list expected"
  );

};
done_testing;

