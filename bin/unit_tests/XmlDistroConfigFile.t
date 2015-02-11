#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 2;


use XmlDistroConfigFile;

my %hFinishedValues;

$hFinishedValues{BootDistroName} = "fedora";
$hFinishedValues{BootDistroId} = "20";
$hFinishedValues{Arch} = "x86_64";
$hFinishedValues{BS_BOOT_KERNEL_BASE_DIRECTORY} = "/var/tftp";
$hFinishedValues{BS_IMAGE_BASE_DIRECTORY} = "/var/configs/images";
$hFinishedValues{BS_CONFIG_BASE_DIRECTORY} = "/var/ks/configs";


my %hReply = GetDistributionNode(undef, \%hFinishedValues, "unit_tests/distros.xml");
is($hReply{'relative_install_image_path'}, 'linux/releases/20/Fedora/x86_64/os', 'GetDistributionNode(undef, \%hFinishedValues, "unit_tests/distros.xml")');
print Dumper(\%hReply);

%hReply = GetKeyPathsForDistro("unit_tests/distros.xml", "centos", "65", "x86_64");
is($hReply{'relative_install_image_path'}, 'centos_65_x86_64', 'GetKeyPathsForDistro("unit_tests/distros.xml", "centos", "65", "x86_64")');

#ok(UpdateDistroConfigFile("t.xml", \%hFinishedValues), "Create an structure from scratch.");
#unlink("t.xml");
#print "===\n";
#ok(UpdateDistroConfigFile("unit_tests/distros.xml", \%hFinishedValues), "Try to add a structure that already exists.");
#print "===\n";

#$hFinishedValues{BootDistroName} = "fedora";
#$hFinishedValues{BootDistroId} = "18";
#$hFinishedValues{Arch} = "x86_64";
#ok(UpdateDistroConfigFile("unit_tests/distros.xml", \%hFinishedValues));

#print "===\n";
#$hFinishedValues{BootDistroName} = "fedora";
#$hFinishedValues{BootDistroId} = "19";
#$hFinishedValues{Arch} = "i686";
#ok(UpdateDistroConfigFile("unit_tests/distros.xml", \%hFinishedValues));


#ok(GetKeyPathsForDistro("unit_tests/distros.xml", "fedora", "19", "x86_64") );

#ok(AddExtraRepoPathToDistroConfigFile("unit_tests/distros.xml", \%hFinishedValues));

#my %hLatestConfig = GetKeyPathsForDistro("unit_tests/distros.xml", $hFinishedValues{BootDistroName}, $hFinishedValues{BootDistroId}, $hFinishedValues{Arch});
#is ($hLatestConfig{relative_extra_repo_path}, "$hFinishedValues{BootDistroName}_$hFinishedValues{BootDistroId}_$hFinishedValues{Arch}");
