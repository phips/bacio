#!/usr/bin/env perl
use Mojolicious::Lite;
use DDP colored => 0;
use YAML::XS qw/LoadFile/;

helper bootserver => sub {
    my $self = shift;

    my $url_host = $self->req->headers->header('host');
    return $url_host;
};

helper db => sub {
    my $self = shift;
    my $dir  = $self->app->home;
    my $data = {};

    eval { $data = LoadFile("$dir/hosts.yaml") };
    if ( $@ ) {
        $self->app->log->debug
            ("*** Problem loading data file: $dir/hosts.yaml ***");
    }

    return $data;
};

helper mac => sub {
    my ($self, $passed_mac) = @_;

    # turn it all into lowercase, and turn separators into dashes
    (my $mac = lc($passed_mac)) =~ s/ : | \. /-/gx;

    $self->app->log->debug("*** Normalised MAC from helper: $mac ***");

    return $mac;
};

get '/' => sub {
    my $self = shift;
    $self->res->headers->header('X-Hello' => 'Bacio on Mojo');
    $self->render(text => 'Default');
};

get '/dumpdb' => sub {
    my $self = shift;

    $self->render(text => p $self->db);
};

get '/ks' => (agent => qr/Safari/) => sub {
    my $self = shift;
    # $self->render(text => 'Use from cmdline');
    my $request = $self->bootserver;
    $self->render(text => "$request");
};

get '/ks' => sub {
    my $self = shift;
    my ($mac, $hdr_line);
    my $kickstart = {};

    $hdr_line = $self->req->headers->header('X-RHN-Provisioning-MAC-0');
    if ( $hdr_line ) {
        $hdr_line =~ s/^\w+ \s+?//x;
        $mac = $self->mac($hdr_line);

        my $hostname = $self->db->{$mac}->{name};
        if (! $hostname ) {
            $self->render(text => "MAC not found\n");
        }
        else {
            my $db      = $self->db;
            my $osrel   = $db->{$mac}->{osrel};
            (my $majver = $osrel) =~ s/\..//;
            my $cm      = $db->{$mac}->{cm};
            my $url     = $db->{$osrel}->{url};
            my $server  = $db->{$osrel}->{server};

            $kickstart->{'url'}    = $url;
            $kickstart->{'server'} = $server;
            $kickstart->{'fstype'} = $majver == '6' ? 'ext4' : 'ext3';
            $kickstart->{'pm'}     = 'PMSERVER';

            $self->stash(
                bootserver => $self->bootserver,
                cm         => $cm,
                hostname   => $hostname,
                kickstart  => $kickstart,
                majver     => $majver,
                arch       => 'x86_64',
            );

            $self->render(template => 'ks', format => 'txt');
        }
    }
    else {
        $self->render(text => 'No X-RHN-Provisioning-MAC-0 header');
    }
};

get '/pxe/:mac' => sub {
    my $self   = shift;
    my $mac    = $self->mac( $self->param('mac') );
    my $db     = $self->db;
    my $osver  = $db->{$mac}->{osrel};
    my $url    = $db->{$osver}->{url};
    my $server = $db->{$osver}->{server};
    my $kernel = $url . '/images/pxeboot/vmlinuz';
    my $initrd = $url . '/images/pxeboot/initrd.img';

    $self->stash(
        bootserver => $self->bootserver,
        server     => $server,
        url        => $url,
        kernel     => $kernel,
        initrd     => $initrd,
    );

    $self->render(template => 'pxe', format => 'txt');
};

app->secret('**CHANGEME**');
app->start;

__DATA__

@@ layouts/default.html.ep
<!DOCTYPE html>
<html>
  <head><title><%= title %></title></head>
  <body><%= content %></body>
</html>

@@ ks.txt.ep
# Kickstart configuration for base RHEL-derived Linux install

install
% if  ( $kickstart->{url} =~ /cdrom/ ) {
cdrom
% } else {
url --url http://<%= $kickstart->{server} %><%= $kickstart->{url} %>/<%= $arch %>
% }
lang en_GB.UTF-8
keyboard uk
text
network --bootproto dhcp --noipv6 --hostname=<%= $hostname %>
# this rootpw is 'vagrant'
rootpw --iscrypted $1$8CLWH1$y8nKfSP7dzQY19LZf0kxb0
firewall --disabled
authconfig --enableshadow --enablemd5
selinux --permissive
services --disabled avahi-daemon,avahi-dnsconfd,bluetooth,cups,gpm,iscsi,iscsid,nfslock,portmap,rpcidmapd,xfs,pcscd
services --enabled ntpd
timezone --utc Europe/London
bootloader --location=mbr
firstboot --disabled
reboot
zerombr
clearpart --all --initlabel
part swap --size=1024 --asprimary
part /boot --fstype <%= $kickstart->{fstype} %> --size=200
part / --fstype <%= $kickstart->{fstype} %> --size=1 --grow
part /var --fstype <%= $kickstart->{fstype} %> --size=1024

# EPEL
repo --name=epel --baseurl=http://www.mirrorservice.org/sites/dl.fedoraproject.org/pub/epel/<%= $majver %>/<%= $arch %>
% if ( $cm ) {
# Puppet
repo --name=puppetdepends --baseurl=http://yum.puppetlabs.com/el/<%= $majver %>/dependencies/<%= $arch %>
repo --name=puppetlabs --baseurl=http://yum.puppetlabs.com/el/<%= $majver %>/products/<%= $arch %>
% }

%%packages
@core
% if ( $majver == 6 ) {
bind-libs
bind-utils
perl-CPAN
perl-Module-CoreList
% } else {
bind97-libs
bind97-utils
gnupg2
% }
# From EPEL
perl-Inline-Files
% if ( $cm ) {
augeas
facter
puppet
ruby-augeas
ruby-shadow
% }
# From EPEL
epel-release
ntp
openssh-clients
openssh-server
# From EPEL (if osrel = 5)
git
redhat-lsb
rsync
ruby-ri
# From EPEL
rubygems
kernel-devel
rsync
rsyslog
sudo
sysstat
telnet
vim-enhanced
virt-what
wget
-dmraid
-apmd
-aspell
-aspell-en
-autofs
-bluez-bluefw
-bluez-hcidump
-bluez-libs
-bluez-utils
-dapl
-desktop-file-utils
-diskdumputils
-dos2unix
-dosfstools
-dump
-eject
-finger
-ftp
-gpm
-htmlview
-ibmasm
-indexhtml
-ipsec-tools
-irda-utils
-isdn4k-utils
-jpackage-utils
-kernel-ib
-kernel-smp
-krb5-workstation
-lftp
-libgssapi
-libibverbs
-libmthca
-librdmacm
-libsdp
-libwvstreams
-lksctp-tools
-m4
-mailcap
-mailx
-minicom
-mt
-mtr
-mt-st
-nano
-nfs
-nfs-utils-lib
-nscd
-nss_ldap
-numactl
-OpenIPMI
-OpenIPMI-libs
-pam_ccreds
-pam_krb5
-pam_passwdqc
-pam_smb
-parted
-pcmcia-cs
-pdksh
-pinfo
-ppp
-procmail
-rdist
-redhat-menus
-rhpl
-rmt
-rp-pppoe
-rsh
-sendmail
-setarch
-specspo
-sysreport
-talk
-tcsh
-unix2dos
-up2date
-vconfig
-wireless-tools
-wvdial
-xorg-x11-libs
-xorg-x11-Mesa-libGL
-ypbind
-yp-tools

%%pre
ntpdate ntp.linx.net
hwclock --systohc

%%post --log=/root/ks-post.log
ip=$(/sbin/ifconfig eth0 | /usr/bin/perl -ne 'print $1 if /addr:( (\d{1,3}\.){3} \d{1,3} )/x')
mac=$(/sbin/ifconfig eth0 | /usr/bin/perl -ne 'print $1 if /HWaddr \s ((?:\w{2}
:){5} \w{2})/x')
echo "IP: ${ip}" >> /etc/issue

% if ( $cm ) {
# puppet agent -t --pluginsync true --ssldir=\$confdir/ssl --server=<%= $kickstart->{pm} %> --waitforcert 15 --color=false --certname=<%= $hostname %> --tags bootstrap
% }

@@ pxe.txt.ep
#!ipxe
kernel -n img http://<%= $server %><%= $kernel %> ks=http://<%= $bootserver %>/ks kssendmac
initrd http://<%= $server %><%= $initrd %>
boot img

