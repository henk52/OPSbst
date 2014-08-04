#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 7;


use YamlDistroConfigFile;

my %hFinishedValues;

$hFinishedValues{BootDistroName} = "gentoo";
$hFinishedValues{BootDistroId} = "14";
$hFinishedValues{Arch} = "x86_64";
$hFinishedValues{BS_BOOT_KERNEL_BASE_DIRECTORY} = "/var/tftp";
$hFinishedValues{BS_IMAGE_BASE_DIRECTORY} = "/var/configs/images";
$hFinishedValues{BS_CONFIG_BASE_DIRECTORY} = "/var/ks/configs";


ok(UpdateDistroConfigFile("t.yaml", \%hFinishedValues), "Create an structure from scratch.");
unlink("t.yaml");
print "===\n";
ok(UpdateDistroConfigFile("unit_tests/distros.yaml", \%hFinishedValues), "Try to add a structure that already exists.");
print "===\n";

$hFinishedValues{BootDistroName} = "fedora";
$hFinishedValues{BootDistroId} = "18";
$hFinishedValues{Arch} = "x86_64";
ok(UpdateDistroConfigFile("unit_tests/distros.yaml", \%hFinishedValues));

print "===\n";
$hFinishedValues{BootDistroName} = "fedora";
$hFinishedValues{BootDistroId} = "19";
$hFinishedValues{Arch} = "i686";
ok(UpdateDistroConfigFile("unit_tests/distros.yaml", \%hFinishedValues));


ok(GetKeyPathsForDistro("unit_tests/distros.yaml", "fedora", "19", "x86_64") );

ok(AddExtraRepoPathToDistroConfigFile("unit_tests/distros.yaml", \%hFinishedValues));

my %hLatestConfig = GetKeyPathsForDistro("unit_tests/distros.yaml", $hFinishedValues{BootDistroName}, $hFinishedValues{BootDistroId}, $hFinishedValues{Arch});
is ($hLatestConfig{relative_extra_repo_path}, "$hFinishedValues{BootDistroName}_$hFinishedValues{BootDistroId}_$hFinishedValues{Arch}");
