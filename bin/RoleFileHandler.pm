package RoleFileHandler;

# Purpose: Read the Package, Pre and Post sections in a role file for the role given.
#   The Each section will be merged into one long list.
#     So if you have three Pre sections in then they will be merged into one combined
#      list. The lines in the combined list will be the same order as read from the file.
#
# Anything outside any of the three sections will be ignored.
#  Only white-space is accepted prior to a section tag.
#
# %PREBEGIN%
# %PREEND%
#
# %PACKAGELISTSTART%
# %PACKAGELISTEND%
#
# %POSTSTART%
# %POSTEND%


use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use BootServerConfigFile;

$VERSION = 0.1.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &ReadRoleConfigurationBlocksIntoHash
            );

# BS_ROLE_CONFIG_SEARCH_PATH
# -----------------------------------------------------------------
# 
# TODO V Support multiple search paths, seperated by ':'? or ';'
#         Does the yaml file support :
# ---------------
sub GetRoleFilePath {
  my $szRoleName = shift;

  my $szFullPath;

  my %hBootServerConfiguration;
  BscPutConfigDataInHash(\%hBootServerConfiguration);

  # TODO V break the search path into and array and iterate over it
  #         to support multiple search paths.
  my $szTestingTarget = "$hBootServerConfiguration{BS_ROLE_CONFIG_SEARCH_PATH}";
  $szTestingTarget .= "/role_${szRoleName}.txt";
  # print "DDD $szTestingTarget\n";
  if ( -f $szTestingTarget ) {
    $szFullPath = $szTestingTarget;
  }

  return($szFullPath);
}


# -----------------------------------------------------------------
# 
# TODO V Should I put the data into a given hash or return a new hash.
# ---------------
sub ReadRoleConfigurationBlocksIntoHash {
  my $szRoleName = shift;

  my %hReturnHash;

  my $szFullPath = GetRoleFilePath($szRoleName);

  confess("!!! Role configuration file for $szRoleName does not exist.") unless(defined($szFullPath));

  open(my $fh, "<$szFullPath") || confess("$0: can't open $szFullPath: $!");

  seek $fh, 0, 0; # Point to the beginning of the file.
  my @arPackageList = ReadAllPackageSections($fh);

  seek $fh, 0, 0; # Point to the beginning of the file.
  my @arPreList = ReadAllPreSections($fh);

  seek $fh, 0, 0; # Point to the beginning of the file.
  my @arPostList = ReadAllPostSections($fh);

  $hReturnHash{PackageList} = \@arPackageList;
  $hReturnHash{PreList}     = \@arPreList;
  $hReturnHash{PostList}    = \@arPostList;


  close($fh);
  return(%hReturnHash);
} # end ReadRoleConfigurationBlocksIntoHash.




# -----------------------------------------------------------------
# This is the common code that each 'Read-specific-section' functions
#   call.
#
#  Please note that this process will not detect if you forgot an end marker.
# ---------------
sub ReadAllGivenSections {
  my $fh = shift;
  my $szSectionName = shift;

  confess("!!! You must provide a file handled and a Section name.") unless(defined($szSectionName));

  my @arContentList;

  my $szBeginMarker = "%${szSectionName}BEGIN%";
  my $szEndMarker = "%${szSectionName}END%";

  my $szGobleState="searching";
  while ( <$fh> ) {
    if ( $szGobleState eq "gobling" ) {
      if ( $_ !~ /^\s*$szEndMarker/ ) {
        push(@arContentList, $_);
      } else {
        $szGobleState = "searching";
      }
    } else {
      if ( $_ =~ /^$szBeginMarker/ ) {
        $szGobleState = "gobling"
      }
    }
  } # end while.

  return(@arContentList);
}


# -----------------------------------------------------------------
# ---------------
sub ReadAllPackageSections {
  my $fh = shift;

  return( ReadAllGivenSections($fh, "PACKAGELIST") );  
}

# -----------------------------------------------------------------
# ---------------
sub ReadAllPreSections {
  my $fh = shift;

  return( ReadAllGivenSections($fh, "PRE") );
}

# -----------------------------------------------------------------
# ---------------
sub ReadAllPostSections {
  my $fh = shift;

  return( ReadAllGivenSections($fh, "POST") );
}

# This ends the perl module/package definition.
1;

