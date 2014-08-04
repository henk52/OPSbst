#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 4;
use Test::Exception;

use MacAddressHandling;

is(ReturnMacDashedFormat("08002723A3d2"), "01-08-00-27-23-a3-d2", "Handle normal MAC address.");
is(ReturnMacDashedFormat("08-00-27-23-A3-d2"), "01-08-00-27-23-a3-d2", "Handle dash separated MAC address.");
is(ReturnMacDashedFormat("08:00:27:23:A3:d2"), "01-08-00-27-23-a3-d2", "Handle colon separated MAC address.");

dies_ok { ReturnMacDashedFormat("0800272") } 'Too short to be a MAC address.';
