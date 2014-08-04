#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 4;
use Test::Exception;

use RoleFileHandler;

my %hFinishedValues;

is(RoleFileHandler::GetRoleFilePath("vagrant"), "/opt/OPSbst/roles/role_vagrant.txt", "Verify RoleFileHandler::GetRoleFilePath()");
is(RoleFileHandler::GetRoleFilePath("NOT_THERE"), undef, "Verify RoleFileHandler::GetRoleFilePath(), undef on non-existing files.");

dies_ok { ReadRoleConfigurationBlocksIntoHash("ROLE_NOT_EXIST") } 'Verify that it dies if the role file does not exists.';

my %hSectionHash = ReadRoleConfigurationBlocksIntoHash("UNIT_TESTING");

my %hExpected = (
        PackageList => [ "Packet1\n", "Packet2\n" ],
        PreList => [ "SinglePreLine\n" ],
        PostList => [ "PostLine 1\n", "PostLine 2\n" ]
                );

is_deeply( \%hSectionHash, \%hExpected, "Verify the structure is correct.");
