use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL 1.001 qw( dztest );

# ABSTRACT: Make sure failures go in the right places

require Moose;
require Dist::Zilla::Role::Plugin;
require Dist::Zilla::Plugin::Bootstrap::lib;
require Dist::Zilla::Plugin::GatherDir;
require Dist::Zilla::Plugin::MetaConfig;

my $t   = dztest();
my $pn  = 'TestPlugin';
my $fpn = 'Dist::Zilla::Plugin::' . $pn;

$t->add_file( 'dist.ini', simple_ini( ['Bootstrap::lib'], ['GatherDir'], ['MetaConfig'], [$pn], ) );
$t->add_file( 'lib/Dist/Zilla/Plugin/' . $pn . '.pm', <<"EOF");
package $fpn;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'attr' => ( is => 'ro', 'lazy' => 1, default => sub { die "You can't handle the truth" } );

around dump_config => config_dumper(__PACKAGE__, qw( attr ));

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF

$t->build_ok;
$t->meta_path_deeply(
  '/x_Dist_Zilla/plugins/*/*[ key eq \'class\' and value eq \'Dist::Zilla::Plugin::TestPlugin\' ]/../*[ key eq \'config\']',
  [
    {
      'Dist::Zilla::Util::ConfigDumper' => {
        'Dist::Zilla::Plugin::TestPlugin' => { 'failed' => ['attr'] }
      },
    }
  ],
  "Plugin list expected"
);
done_testing;

