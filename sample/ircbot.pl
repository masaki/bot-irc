#!/usr/bin/perl

use FindBin::libs;
use Getopt::Long;
use Bot::IRC;

Getopt::Long::Configure("bundling");
Getopt::Long::GetOptions('--config=s', \my $config);

Bot::IRC->bootstrap(config => $config);
