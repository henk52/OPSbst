#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 6;
use Test::Exception;

use BstShortcuts;
use BootServerConfigFile;


my %hSparseHash;

dies_ok { BstShortcuts::UseOtherIfFirstDoesNotExistOrDie(\%hSparseHash,"--distro", "BootDistroName") } 'Die if none of the keys are there';
$hSparseHash{'BootDistroName'} = "Second";

BstShortcuts::UseOtherIfFirstDoesNotExistOrDie(\%hSparseHash,"--distro", "BootDistroName");
is($hSparseHash{'--distro'}, "Second", "Verify the second key is used if the first is not defined.");

$hSparseHash{'--distro'} = "First";
BstShortcuts::UseOtherIfFirstDoesNotExistOrDie(\%hSparseHash,"--distro", "BootDistroName");
is($hSparseHash{'--distro'}, "First", "Verify that the first key is picked if it is defined.");


my %hFinishedValues;

BscPutConfigDataInHash(\%hFinishedValues);

$hFinishedValues{'--distro'} = "gentoo";
$hFinishedValues{'--release'} = "14";
$hFinishedValues{'--arch'} = "x86_64";

is(GetDistroDirectoryName(\%hFinishedValues), "gentoo-14-x86_64", "Validating GetDistroDirectoryName()");
is(GetAbsolutePathToImageRepoDataDirectory(\%hFinishedValues), "/var/ks/images/gentoo-14-x86_64/repodata", "Validating GetAbsolutePathToImageRepoDataDirectory()");
$hFinishedValues{''} = "extrarepos";
is(GetAbsolutePathToDestinationRepoDirForDistro(\%hFinishedValues), "/var/ks/extrarepos/gentoo-14-x86_64", "Validating GetAbsolutePathToDestinationRepoDirForDistro()");
#is((\%hFinishedValues), "", "Validating ()");



