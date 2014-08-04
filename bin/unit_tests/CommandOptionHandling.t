#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 1;
use Test::Exception;

use CommandOptionHandling;

my $f_szImportCommand = "import";

my %f_hValidOption;
#my $nReturnValue = AddValidOption(\%f_hValidOption, "--distro", [ "$f_szImportCommand" ], 1, "Distribution name. E.g. 'fedora'", undef);

my %f_hProvidedOptions;

#print "---\n";
#print Dumper(%f_hValidOption);

ok(DieOnInvalidOptionsForCommand($f_szImportCommand, \%f_hValidOption, \%f_hProvidedOptions));
