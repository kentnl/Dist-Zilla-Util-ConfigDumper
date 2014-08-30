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
$t->add_file( 'lib/Dist/Zilla/Plugin/' . $pn . '.pm', <<"EOF");
package $fpn;

use Moose qw( has around with );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::Plugin';

has 'attr' => ( is => 'ro', 'lazy' => 1, default => sub { 'I have value, my life has meaning' } );

around dump_config => config_dumper({});

__PACKAGE__->meta->make_immutable;
no Moose;

1;
EOF
isnt( $t->safe_build, undef, 'Ref == bang' );
done_testing;

