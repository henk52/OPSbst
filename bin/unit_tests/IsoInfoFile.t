#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 2;
use Test::Exception;

use IsoInfoFile;

my %hFinishedValues;

dies_ok { IifPutiIsoInfoDataInHash(\%hFinishedValues) } 'verify that it dies, when there is no --distro defined.';

$hFinishedValues{'--distro'} = "ubuntu";
IifPutiIsoInfoDataInHash(\%hFinishedValues);

is($hFinishedValues{'RelativeKernelSource'}, "install", "make sure the RelativeKernelSource is defined.");
