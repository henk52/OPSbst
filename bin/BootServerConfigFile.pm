package BootServerConfigFile;

# Loads the configuration content of 'config_boot_server_tool.yaml' into the hash given.

use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use YAML::XS qw/LoadFile Dump/;


$VERSION = 0.2.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &BscPutConfigDataInHash
            );

# TODO V enable reading the OPSbst yaml first then overload with the one in /etc.
my $f_szYamlConfigFileName = "config_boot_server_tool.yaml";
my $f_szBootServerConfigFile;
if ( -e "/etc/$f_szYamlConfigFileName" ) {
  $f_szBootServerConfigFile = "/etc/$f_szYamlConfigFileName";
} else {
  $f_szBootServerConfigFile = "/opt/OPSbst/etc/$f_szYamlConfigFileName";
}

# -----------------------------------------------------------------
# TODO V Have an optional filename parm, for an optional path to the config file.
# ---------------
sub BscPutConfigDataInHash {
    my $refhFinishedValues = shift;

    my $yaml = LoadFile($f_szBootServerConfigFile);

    #print Dumper($yaml);
    foreach my $szKey (keys %{$yaml}) {
      $refhFinishedValues->{$szKey} = $yaml->{$szKey};
    }
} # end BscPutConfigDataInHash
# This ends the perl module/package definition.
1;
