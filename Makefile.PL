use inc::Module::Install;

name         'Bacio';
abstract     'A simple Linux Kickstart helper';
author       'Mark Phillips <mark@probably.co.uk>';
license      'perl';
version      '0.5';

requires 'perl'        => '5.010001';
requires 'Mojolicious' => 4;
requires 'DDP';
requires 'YAML::XS';

WriteAll;
