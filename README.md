## Bacio - a kickstart helper

### What is it?

Kickstarting Linux needs a different vmlinuz and initrd per version. This gets
to be a pain if you're running a PXE boot environment. What would be so much
nicer would be to boot a generic PXE image, whether that be over the network or
via a CD/image and let the resulting URL work out what version of the OS you're
trying to install on the host.

There are plenty of 'big' answers to this - [Cobbler](https://cobbler.github.io/)
and [The Foreman](https://theforeman.org) are two that spring to mind - but I
wanted something much smaller and simpler. You could go much smaller and
simpler than this here, without a doubt, but originally I used the problem as
an excuse to learn [Catalyst](http://catalyst.perl.org), and then to learn
[Mojolicious](https://mojolicio.us).

## What is it really?

This is very much 'work in progress' - it's barely documented and I threw it
together rather quickly to replace a version I originally wrote in
Catalyst.

It's now written as a Mojolicious
[lite](https://mojolicio.us/perldoc/Mojolicious/Lite) app. You can run it with
'morbo' for testing, under [Plack](https://plackperl.org), Hypnotoad, whatever.
Check the Mojo docs on
[deployment](https://mojolicio.us/perldoc/Mojolicious/Guides/Cookbook#DEPLOYMENT).

In short, you want a 'hosts.yaml' file in the same directory as the script. It
needs to contain a couple of hashes containing Linux versions with the server
and URL to get them from (see examples within). Then list MAC addresses, in the
format shown within (dash separators). There's a template kickstart file
embedded (search for ^@@ ks.txt.ep) that installs a pretty minimal OS. The root
password, by default, is 'vagrant'.

I tend to kickstart then hand off to
[Ansible](https://docs.ansible.com/) to do configuration
work - and setting 'cm: 1' in [the YAML
file](https://github.com/phips/bacio/blob/master/hosts.yaml) would've, back in the day, run Puppet (see [line
341](https://github.com/phips/bacio/blob/master/bacio.pl#L341), it's commented out
now).

The original Catalyst version had a web interface for 'registering' hosts,
editing and deleting hosts and managing the kickstart servers. Editing YAML is
simpler ;-)

Tinker to your delight.

## Debugging

You can dump the 'database' as the app sees it by viewing /dumpdb. Easiest to
curl the url, as it renders as text. You can also test kickstart files with
`curl -H'X-RHN-Provisioning-Mac-0: eth0 MACADDRESS'`.


