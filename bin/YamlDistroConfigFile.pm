package YamlDistroConfigFile;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use YAML::XS qw/LoadFile Dump/;

use BstShortcuts;

$VERSION = 0.3.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &AddExtraRepoPathToDistroConfigFile
                &UpdateDistroConfigFile
                &GetKeyPathsForDistro
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
  my $yaml = shift;
  my $refhFinishedValues = shift;
  my $szConfigFileName = shift;

  my $ymlNode;

  if ( ! defined($yaml) ) {
    if ( -f $szConfigFileName ) {
      $yaml = LoadFile($szConfigFileName);
    } else {
      die("!!! Config file missing: $szConfigFileName");
    }
  }

  my @arDistroList = @{$yaml->{'Distributions'}};

  foreach my $ymlDistro (@arDistroList) {
    die("!!! 'BootDistroName' is not defined in the hash that was suppose to have it, could you please provide it?") unless ( exists($refhFinishedValues->{BootDistroName}) );
    if ( $ymlDistro->{distro} eq $refhFinishedValues->{BootDistroName} ) {
      $ymlNode = $ymlDistro;
    }
  }

  return($ymlNode);
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




# -----------------------------------------------------------------
# 
# Parms:
#  - yaml: The Distro yaml structure. If this is undef, then parm must be given.
#  - refhFinishedValues: The hash with the definitions.
#  - szConfigFileName: Optional, must be here if 'yaml' isn't defined.
# ---------------
sub GetArchitectureNode {
  my $yaml = shift;
  my $refhFinishedValues = shift;
  my $szConfigFileName = shift;

  confess("!!! first parm(yaml) not defined, please fix or include the (szConfigFileName) in the call.") unless(defined($yaml) || defined($szConfigFileName));
  confess("!!! second parm(refhFinishedValues) not defined, please fix the call.") unless(defined($refhFinishedValues));
  confess("!!! third parm(szConfigFileName) not defined, please fix the call.") unless(defined($szConfigFileName) || defined($yaml));

  my $ymlNode;

  if ( ! defined($yaml) ) {
    $yaml = GetReleaseNode($yaml, $refhFinishedValues, $szConfigFileName);
  }

  if ( defined($yaml) ) {
    foreach my $ymlArchitecture ( @{$yaml->{architechture}} ) {
      UseOtherIfFirstDoesNotExistOrDie($refhFinishedValues, "Arch", "architechture");
      if ( $ymlArchitecture->{arch} eq $refhFinishedValues->{Arch} ) {
        $ymlNode = $ymlArchitecture;
      } # endif.
    } # end foreach.
  }

  return($ymlNode);
} # end GetDistributionNode




# -----------------------------------------------------------------
# ---------------
sub GetKeyPathsForDistro {
  my $szConfigFileName = shift;
  my $szDistribution   = shift;
  my $szVersionId      = shift;
  my $szArchitecture   = shift;

  my %hReturnValues;

  my $refhFinishedValues = {};

  $refhFinishedValues->{BootDistroName} = $szDistribution;
  $refhFinishedValues->{BootDistroId}   = $szVersionId;
  $refhFinishedValues->{Arch}           = $szArchitecture;

  my $yaml;

  if ( -f $szConfigFileName ) {
    $yaml = LoadFile($szConfigFileName);
    # TODO V Test the file was actually loaded.

    $yaml = GetDistributionNode($yaml, $refhFinishedValues);
  } else {
    die("!!! Not able to read file: $szConfigFileName");
  }

  if ( defined($yaml) ) {
    $yaml = GetReleaseNode($yaml, $refhFinishedValues);
  } else {
    die("!!! Unable to find Distribition: $szDistribution");
  }

  if ( defined($yaml) ) {
    $yaml = GetArchitectureNode($yaml, $refhFinishedValues);
  } else {
    die("!!! Unable to find release of $szDistribution: $szVersionId");
  }

  if ( defined($yaml) ) {
    my @arRequiredKeyList = ( "relative_boot_kernel_path", "relative_install_image_path" );
    foreach my $szKey (@arRequiredKeyList) {
      if ( exists( $yaml->{$szKey} ) ) {
        $hReturnValues{$szKey} = $yaml->{$szKey};
      } else {
        die("!!! Missing data entry: $szKey");
      }
    }
    my @arOptionalKeyList = ( "relative_extra_repo_path" );
    foreach my $szKey (@arOptionalKeyList) {
      if ( exists( $yaml->{$szKey} ) ) {
        $hReturnValues{$szKey} = $yaml->{$szKey};
      }
    }
    
  } else {
    die("!!! Unable to find architecture of $szDistribution,$szVersionId: $szArchitecture");
  }

  #print Dumper(%hReturnValues);

  return(%hReturnValues);
} # end GetKeyPathsForDistro.





# -----------------------------------------------------------------
# Rules for the YAML file:
#  Create the file if it does not exist.
#  Add the Release if it does not exist.
#  Add the architechture if it does not exist.
#  (Add the machine (for Solaris) if it does not exits).
# ---------------
sub UpdateDistroConfigFile {
  my $szConfigFileName = shift;
  my $refhFinishedValues = shift;

  my $yaml;

  if ( ! -f $szConfigFileName ) {
    # Create the structure from scratch.
    $yaml = CreateDistributionsStructure($refhFinishedValues);
  } else {
    $yaml = LoadFile($szConfigFileName);
    my $ymlDistro = GetDistributionNode($yaml, $refhFinishedValues);

    if ( ! defined($ymlDistro) ) {
      $ymlDistro = CreateDistroStructure($refhFinishedValues);
      push(@{$yaml->{Distributions}}, $ymlDistro);
    } else {
      #print Dumper($ymlDistro);
      my $ymlRelease = GetReleaseNode($ymlDistro, $refhFinishedValues);
      if ( ! defined($ymlRelease)) {
        $ymlRelease = CreateReleaseStructure($refhFinishedValues);
        push(@{$ymlDistro->{Versions}}, $ymlRelease);
      } else {
        my $ymlArch = GetArchitectureNode($ymlRelease, $refhFinishedValues);
        if ( ! defined($ymlArch)) {
          my $ymlArch = CreateArchStructure($refhFinishedValues);
          push(@{$ymlRelease->{architechture}}, $ymlArch);
        } else {
          print "III It should all be there !??\n";
        }
      }
    }
  }

  if ( defined($yaml) ) {
    open(YAML, ">$szConfigFileName") || die("Unable to open for write: '$szConfigFileName' - Error: $!");
    print YAML Dump($yaml);
    close(YAML);
  }
} # end UpdateDistroConfigFile.


# -----------------------------------------------------------------
# ---------------
sub AddExtraRepoPathToDistroConfigFile {
  my $szConfigFileName = shift;
  my $refhFinishedValues = shift;

  my $yaml;
  my $ymlNode;

  if ( -f $szConfigFileName ) {
    $yaml = LoadFile($szConfigFileName);
    # TODO V Test the file was actually loaded.

    $ymlNode = GetDistributionNode($yaml, $refhFinishedValues);
  } else {
    die("!!! Not able to read file: $szConfigFileName");
  }

  if ( defined($ymlNode) ) {
    $ymlNode = GetReleaseNode($ymlNode, $refhFinishedValues);
  } else {
    die("!!! Unable to find Distribition: $refhFinishedValues->{BootDistroName}");
  }

  if ( defined($ymlNode) ) {
    $ymlNode = GetArchitectureNode($ymlNode, $refhFinishedValues);
  } else {
    die("!!! Unable to find release of $refhFinishedValues->{BootDistroName}, $refhFinishedValues->{BootDistroId}");
  }

  if ( defined($ymlNode) ) {
    my $szIdentifier = "$refhFinishedValues->{BootDistroName}_$refhFinishedValues->{BootDistroId}_$refhFinishedValues->{Arch}";
    $ymlNode->{relative_extra_repo_path} = "$szIdentifier";
    if ( defined($ymlNode) ) {
      open(YAML, ">$szConfigFileName") || die("Unable to open for write: '$szConfigFileName' - Error: $!");
      print YAML Dump($yaml);
      close(YAML);
    }
  } else {
    die("!!! Architecture node not found for: $refhFinishedValues->{BootDistroName}, $refhFinishedValues->{BootDistroId}: $refhFinishedValues->{Arch}");
  }
  
} # end AddExtraRepoPathToDistroConfigFile

# This ends the perl module/package definition.
1;
