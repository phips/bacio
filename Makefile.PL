use inc::Module::Install;

name         'Bacio';
abstract     'A simple Linux Kickstart helper';
author       'Mark Phillips <mark@probably.co.uk>';
license      'perl';
version      '0.6';

requires 'perl'                 => '5.010001';
requires 'Compress::Raw::Zlib';
requires 'IO::Compress::Gzip';
requires 'Time::HiRes';
requires 'Data::Dumper';
requires 'Mojolicious'          => '4.63';
requires 'YAML::XS';
requires 'TAP::Formatter::JUnit';

WriteAll;
