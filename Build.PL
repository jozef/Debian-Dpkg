use 5.010;
use strict;

use Module::Build;

my $build = Module::Build->new(
    license            => 'gpl2',
    module_name        => 'Dpkg',
    dist_version_from  => 'lib/Dpkg.pm',
    configure_requires => {
        'perl'          => '5.010',
    },
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        'perl'                   => '5.010',
    },
    add_to_cleanup => [ 'Dpkg-*', 't.tmp' ],
);
$build->create_build_script;
