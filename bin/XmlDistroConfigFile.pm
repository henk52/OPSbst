package XmlDistroConfigFile;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;


use BstShortcuts;
use XmlIf;

$VERSION = 0.1.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &AddExtraRepoPathToDistroConfigFile
                &UpdateDistroConfigFile
                &GetKeyPathsForDistro
                &GetDistributionNode
            );


# -----------------------------------------------------------------
# ---------------
sub CreateDistributionsStructure {
  my $refhFinishedValues = shift;

  my $yaml = {};

  $yaml->{Distributions} = ();

  my $ymlDistro = CreateDistroStructure($refhFinishedValues);
  push(@{$yaml->{Distributions}}, $ymlDistro);

  return($yaml);
}




# -----------------------------------------------------------------
# ---------------
sub CreateDistroStructure {
  my $refhFinishedValues = shift;

  my $yaml = {};

  $yaml->{distro} = $refhFinishedValues->{BootDistroName};
  $yaml->{Versions} = ();

  my $ymlRelease = CreateReleaseStructure($refhFinishedValues);
  push(@{$yaml->{Versions}}, $ymlRelease);

  return($yaml);
}


# -----------------------------------------------------------------
# ---------------
sub CreateReleaseStructure {
  my $refhFinishedValues = shift;

  my $yaml = {};

  $yaml->{release} = $refhFinishedValues->{BootDistroId};
  $yaml->{architechture} = ();

  my $ymlArch = CreateArchStructure($refhFinishedValues);
  push(@{$yaml->{architechture}}, $ymlArch);

  return($yaml);
}




# -----------------------------------------------------------------
# ---------------
sub CreateArchStructure {
  my $refhFinishedValues = shift;

  my $yaml = {};

  $yaml->{arch} = $refhFinishedValues->{Arch};
  # TODO C Add the relevant information.
  my $szIdentifier = "$refhFinishedValues->{BootDistroName}_$refhFinishedValues->{BootDistroId}_$refhFinishedValues->{Arch}";
  $yaml->{relative_boot_kernel_path} = "$szIdentifier";
  $yaml->{relative_install_image_path} = "$szIdentifier";

  return($yaml);
} # end CreateArchStructure.





# -----------------------------------------------------------------
# ---------------
sub GetDistributionNode {
  my $xml = shift;
  my $refhFinishedValues = shift;
  my $szConfigFileName = shift;

  my $xmlNode;
  my %hReply;

  if ( ! defined($xml) ) {
    if ( -f $szConfigFileName ) {
      $xml = LoadXmlTree($szConfigFileName);
    } else {
      die("!!! Config file missing: $szConfigFileName");
    }
  }
  my %hAttributeHash;

  # TODO V Die if one of the values are missing.
  $hAttributeHash{'Name'} = $refhFinishedValues->{BootDistroName};
  $hAttributeHash{'Architechture'} = $refhFinishedValues->{Arch};
  $hAttributeHash{'Version'} = $refhFinishedValues->{BootDistroId};

  my @arDistroList = GetNodeArrayByTagAndAttributeList($xml, "Distro", \%hAttributeHash);

  #print Dumper(@arDistroList);
  #print Dumper(\%hAttributeHash);

  $xmlNode = shift @arDistroList;
  if ( defined($xmlNode) ) {
    $hReply{'relative_boot_kernel_path'}         = GetChildDataBySingleTagName($xmlNode, "relative_boot_kernel_path");
    $hReply{'relative_install_image_path'}       = GetChildDataBySingleTagName($xmlNode, "relative_install_image_path");
    $hReply{'relative_additional_packages_path'} = GetChildDataBySingleTagName($xmlNode, "relative_additional_packages_path");
    $hReply{'relative_updates_path'}             = GetChildDataBySingleTagName($xmlNode, "relative_updates_path");
  }

  return(%hReply);
} # end GetDistributionNode


# -----------------------------------------------------------------
# ---------------
sub GetReleaseNode {
  my $yaml = shift;
  my $refhFinishedValues = shift;
  my $szConfigFileName = shift;

  my $ymlNode;

  if ( ! defined($yaml) ) {
    $yaml = GetDistributionNode($yaml, $refhFinishedValues, $szConfigFileName);
  }

  if ( defined($yaml) ) {
    foreach my $ymlVersion ( @{$yaml->{'Versions'}} ) {
      if ( $ymlVersion->{release} eq $refhFinishedValues->{BootDistroId} ) {
        $ymlNode = $ymlVersion;
      }
    }
  }

  return($ymlNode);
} # end GetDistributionNode


# This ends the perl module/package definition.
1;
