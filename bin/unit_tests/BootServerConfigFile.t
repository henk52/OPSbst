#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 1;


use BootServerConfigFile;

my %hFinishedValues;

BscPutConfigDataInHash(\%hFinishedValues);

is($hFinishedValues{BS_DISTRO_CONFIGURATION_FILE}, "/var/ks/distros.xml", "make sure the BS_DISTRO_CONFIGURATION_FILE is defined.");
