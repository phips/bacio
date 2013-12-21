#!/usr/bin/env perl
#
use strict;
use warnings;
use Test::More;

my @modules = qw{ Compress::Raw::Zlib IO::Compress::Gzip Time::HiRes Data::Dumper YAML::XS };

plan tests =>
    1
    + ( scalar @modules );

use_ok('Mojolicious', '4') or BAIL_OUT(q<Can't continue.>);

foreach my $class ( @modules ) {
    use_ok( $class );
}

