package IsoInfoFile;

# Loads the boot information for an ISO image for a given distro.

use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use YAML::XS qw/LoadFile Dump/;


$VERSION = 0.1.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
              &IifPutiIsoInfoDataInHash
            );

my $f_szIsoInfoFilesBaseDirectory = "/opt/OPSbst/etc";

# -----------------------------------------------------------------
# TODO V Have an optional filename parm, for an optional path to the config file.
# ---------------
sub IifPutiIsoInfoDataInHash {
  my $refhFinishedValues = shift;

  
  if ( ! exists( $refhFinishedValues->{'--distro'} ) ) {
    confess("!!! required '--distro' key does not exist in the hash provided to this function.");
  }
  my $szIsoInfoFileName = "iso_info_$refhFinishedValues->{'--distro'}.yaml";

  my $szFullPathAndName = "$f_szIsoInfoFilesBaseDirectory/$szIsoInfoFileName";

  if ( ! -f $szFullPathAndName ) {
    confess("!!! ISO Information file for distro not found: $szFullPathAndName");
  }
  my $yaml = LoadFile($szFullPathAndName);

  #print Dumper($yaml);
  foreach my $szKey (keys %{$yaml}) {
    $refhFinishedValues->{$szKey} = $yaml->{$szKey};
  }
  #print Dumper($refhFinishedValues);

} # end BscPutConfigDataInHash

# This ends the perl module/package definition.
1;
