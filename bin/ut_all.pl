#!/usr/bin/perl -w

use strict;

use Test::Harness;

my @arTestFiles = qw(
  unit_tests/BstShortcuts.t
  unit_tests/BootServerConfigFile.t
  unit_tests/CliOptionHandling.t
  unit_tests/IsoInfoFile.t
  unit_tests/KickstartConfig.t
  unit_tests/MacAddressHandling.t
  unit_tests/RoleFileHandler.t
  unit_tests/XmlIf.t
  unit_tests/YamlDistroConfigFile.t
  unit_tests/XmlDistroConfigFile.t
                  );

runtests(@arTestFiles);
