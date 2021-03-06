use strict;
use warnings;
use Test::More tests => 7;
use Test::Mojo;

use FindBin qw/$Bin/;

$ENV{'MOJO_LOG_LEVEL'} = 'info';

require_ok ("$Bin/../bacio.pl");

my $t = Test::Mojo->new;
$t->get_ok('/ks')
    ->status_is(200)
    ->content_like(qr/No X-RHN-Prov/, 'Default get');

$t->ua->on(start => sub {
    my ($ua, $tx) = @_;
    $tx->req->headers->header(
        'X-RHN-Provisioning-Mac-0' => 'eth0 00:1c:42:f0:6f:64'
    );
});

$t->get_ok('/ks')
    ->status_is(200)
    ->content_like(qr/hostname=c64.lan/, 'Got a host KS config');

