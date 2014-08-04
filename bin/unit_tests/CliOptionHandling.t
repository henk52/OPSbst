#!/usr/bin/perl -w

use strict;
use Data::Dumper;


use Test::More tests => 14;
use Test::Exception;

use CliOptionHandling;

my $f_szImportCommand = "import";

my %f_hValidOption;
my $nReturnValue = AddValidOption(\%f_hValidOption, "--distro", [ "$f_szImportCommand" ], 1, "Distribution name. E.g. 'fedora'", undef);

#print "---\n";
#print Dumper(%f_hValidOption);

ok ( $nReturnValue == 0, 'Number of entries added.');
is ( $f_hValidOption{"--distro"}{"Description"}, "Distribution name. E.g. 'fedora'", "Has a description" );
is ( $f_hValidOption{"--distro"}{"ValidCommandList"}[0], $f_szImportCommand, "Commandlist of one." );

my @arCommandArray = [ "alpha", "bravo" ];
$nReturnValue = AddValidOption(\%f_hValidOption, "--combo", @arCommandArray, 1, "Distribution name. E.g. 'fedora'", "DEFAULT");

ok ( $nReturnValue == 0, 'Number of entries added.');
is ( $f_hValidOption{"--combo"}{"Description"}, "Distribution name. E.g. 'fedora'", "Has a description" );
is ( $f_hValidOption{"--combo"}{"ValidCommandList"}[1], "bravo", "Second Commandlist entry is 'bravo'." );


print "--- Testing: HandleCommandLine()\n";

throws_ok { HandleCommandLine() } "/!!! You must provide a hash of valid options/", 'HandleCommandLine() should die when no valid option hash is provided.';

# Die when there are no %hValidOption.
throws_ok { HandleCommandLine("this is just text.") } "/!!! First parameter must be a reference to a hash./", 'HandleCommandLine() should die when it is not a reference to a hash.';


# Die when the %hValidOption is empty.
my %hValidOption;
throws_ok { HandleCommandLine(\%hValidOption) } "/!!! The ValidOption hash is empty, please populate it./", 'HandleCommandLine() should die when the hValidOption hash is empty.';

$hValidOption{"--distro"}{"HasParameter"} = 1;
throws_ok { HandleCommandLine(\%hValidOption) } "/!!! No command line parameters, where parameters where expected./", 'HandleCommandLine() should die when ARV is not set.';

push(@ARGV, "--smurf");

throws_ok { HandleCommandLine(\%hValidOption) } "/!!! invalid option name encountered, please do not use/", 'HandleCommandLine() should die when the option is not supported.';


$hValidOption{"--verbose"}{"Description"} = "Activate verbose output.";

@ARGV = ( "--verbose", "--distro", "illumos" );
my %hResultParameters = HandleCommandLine(\%hValidOption);
my %hExpectedHash;
$hExpectedHash{"--verbose"} = "A_SWITCH";
$hExpectedHash{"--distro"} = "illumos";
is_deeply(\%hResultParameters, \%hExpectedHash, 'Find both switched and options with parameters');
is( $#ARGV, -1, 'The ARGV is empty afterwards.' );


@ARGV = ( "--distro", "illumos", "ExtraCommand" );
%hResultParameters = HandleCommandLine(\%hValidOption, 1);
is( $#ARGV, 0, 'The ARGV should have one parameter left, when requested.' );

