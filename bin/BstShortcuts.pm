package BstShortcuts;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;


$VERSION = 1.5.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &GetAbsolutePathToDestinationRepoDirForDistro
                &GetAbsolutePathToDestinationRepoDirForDistroOptionallyWithTimeStamp
                &GetAbsolutePathToImageRepoDataDirectory
                &GetDistroDirectoryName
                &GetDistroDirectoryNameOptionallyWithTimeStamp
                &UseOtherIfFirstDoesNotExistOrDie
            );


# -----------------------------------------------------------------
#  return the full distroname: fedora-20-x86_64
# ---------------
sub GetDistroDirectoryName {
  my $refhFullList = shift;

  # TODO V I should move away from --distro and use BootDistroName instead, everywhere.
  UseOtherIfFirstDoesNotExistOrDie($refhFullList, "--distro", "BootDistroName");
  UseOtherIfFirstDoesNotExistOrDie($refhFullList, "--release", "BootDistroId");
  UseOtherIfFirstDoesNotExistOrDie($refhFullList, "--arch", "Architechture");

  # The seperations can't be '_', if they are then yum can't resolve e.g. $releasever
  my $szDirectoryName = $refhFullList->{'--distro'};
  $szDirectoryName .= "-$refhFullList->{'--release'}";
  $szDirectoryName .= "-$refhFullList->{'--arch'}";

  return($szDirectoryName);
}


# -----------------------------------------------------------------
#  return the full distroname: fedora-20-x86_64-20140514
# ---------------
sub GetDistroDirectoryNameOptionallyWithTimeStamp {
  my $refhFullList = shift;

  my $szDirectoryName = GetDistroDirectoryName($refhFullList);

  if ( exists($refhFullList->{'--timestamp'}) ) {
    $szDirectoryName .= "-$refhFullList->{'--timestamp'}";
  }

  return($szDirectoryName);
}

# -----------------------------------------------------------------
# ---------------
sub GetAbsolutePathToGivenDirectory {
  my $refhFullList = shift;
  my $szGivenDirectory = shift;

  my $szFullPath = $refhFullList->{'BS_NFS_BASE_PATH'};
  $szFullPath .= "/$szGivenDirectory";
  $szFullPath .= "/" . GetDistroDirectoryName($refhFullList);

  return($szFullPath);
}

# -----------------------------------------------------------------
# ---------------
sub GetAbsolutePathToImageRepoDataDirectory {
  my $refhFullList = shift;

  my $szFullPath = GetAbsolutePathToGivenDirectory($refhFullList, $refhFullList->{'BS_RELATIVE_IMAGE_DIRECTORY'});
  $szFullPath .= "/repodata";

  return($szFullPath);
}

# -----------------------------------------------------------------
# ---------------
sub GetAbsolutePathToDestinationRepoDirForDistroOptionallyWithTimeStamp {
  my $refhFullList = shift;

  my $szFullPath = GetAbsolutePathToGivenDirectory($refhFullList, $refhFullList->{'BS_RELATIVE_EXTRA_REPO_DIRECTORY'});

  if ( exists($refhFullList->{'--timestamp'}) ) {
    $szFullPath .= "-$refhFullList->{'--timestamp'}";
  }

  return($szFullPath);
}


# -----------------------------------------------------------------
# ---------------
sub GetAbsolutePathToDestinationRepoDirForDistro {
  my $refhFullList = shift;

  die("!!! You must provide a reference to a hash as the parameter for GetAbsolutePathToDestinationRepoDirForDistro()") unless(defined($refhFullList));
  print "DDD GetAbsolutePathToDestinationRepoDirForDistro($refhFullList)\n";
  #my $szFullPath = GetAbsolutePathToDestinationRepoDirForDistro();
  my $szFullPath = GetAbsolutePathToGivenDirectory($refhFullList, $refhFullList->{'BS_RELATIVE_EXTRA_REPO_DIRECTORY'});

  return($szFullPath);
}



# -----------------------------------------------------------------
# This function will copy the value by szSecondaryKey into the 
#   szPrimaryKey part, provided szPrimaryKey doesn't exit.
#  If neither exists this function will die.
#
# TODO N Move this funtionc into a more generic package.
# ---------------
sub UseOtherIfFirstDoesNotExistOrDie {
  my $refhFullList = shift;
  my $szPrimaryKey = shift;
  my $szSecondaryKey = shift;

  print "DDD UseOtherIfFirstDoesNotExistOrDie($refhFullList, $szPrimaryKey, $szSecondaryKey)\n";

  if ( ! exists($refhFullList->{$szPrimaryKey}) ) {
    if ( exists($refhFullList->{$szSecondaryKey}) ) {
      $refhFullList->{$szPrimaryKey} = $refhFullList->{$szSecondaryKey};
    } else {
      confess("!!! no value for key: '$szPrimaryKey' or '$szSecondaryKey'.");
    }
  } 
} # end UseOtherIfFirstDoesNotExistOrDie

# This ends the perl module/package definition.
1;

