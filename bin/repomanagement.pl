#!/usr/bin/perl -w

use strict;
use FindBin;

BEGIN {
  push( @INC, "$FindBin::RealBin" );    ## Path to local modules
}

use Data::Dumper;
use File::Temp qw/ tempdir /;
use Text::Template;

use BootServerConfigFile;
use BstShortcuts;
use CliOptionHandling;
use CommandOptionHandling;
use ExecuteAndTrace;
use YamlDistroConfigFile;
use XmlIf;

# Example:
# cd /tmp
# tar -zxvf /vagrant/fedora_20_extra_repo.tgz
# sudo /opt/OPSbst/bin/repoimport.pl  --distro fedora --release 20 --srcdir /tmp/erepo

#  clear; sudo ./repomanagement.pl add --distro fedora --release 20 --srctgz /vagrant/f20.tgz --timestamp 20140514
#  clear; sudo ./repomanagement.pl add --distro centos --release 65 --srciso CentOS-6.5-x86_64-bin-DVD2.iso
 



# ===========================================================================
#                          V A R I A B L E S
# ===========================================================================

# This is a fictisious command, it is here to make this script compatible
#   with the common functions.
my $f_szAddCommand    = "add";
my $f_szImportCommand = "import";

my $f_szLogFileName = "/tmp/repomanagement.log";

my $f_szRepoMdFileName  = "repodata/repomd.xml";

my $f_szTreeInfoTemplate = "$FindBin::RealBin/../templates/treeinfo.tmpl";

my %f_hSupportedCommands;
  $f_hSupportedCommands{"help"} = "This help text. For more information do help 'command'";
  $f_hSupportedCommands{"add"} = "add a new configuration, will fail if already exists.";
#  $f_hSupportedCommands{"delete"} = "delete existing configuration, fail if doesn't exists.";
  $f_hSupportedCommands{"update"} = "Update: will write booth the boot cfg and ks.cfg whether they exist or not.";


my %f_hFinishedValues;

my %f_hValidOption;
my $nHaveParameter = 1;
AddValidOption(\%f_hValidOption, "--arch",     [ $f_szAddCommand, $f_szImportCommand ], $nHaveParameter, "Architecture. e.g. 'x86_64'", "x86_64");
AddValidOption(\%f_hValidOption, "--distro",   [ $f_szAddCommand, $f_szImportCommand ], $nHaveParameter, "Distribution name. E.g. 'fedora'", undef);
AddValidOption(\%f_hValidOption, "--release",  [ $f_szAddCommand, $f_szImportCommand ], $nHaveParameter, "Release ID, e.g. '20' or '10u8'", undef);
AddValidOption(\%f_hValidOption, "--srcdir",   [ $f_szAddCommand, $f_szImportCommand ], $nHaveParameter, "The directory with the downloaded RPM files.", undef);
AddValidOption(\%f_hValidOption, "--srctgz",   [ $f_szAddCommand ], $nHaveParameter, "The TGZ with the downloaded RPM files.", undef);
AddValidOption(\%f_hValidOption, "--srciso",   [ $f_szAddCommand ], $nHaveParameter, "The ISO with the RPM files.", undef);
AddValidOption(\%f_hValidOption, "--timestamp",[ $f_szAddCommand, $f_szImportCommand ], $nHaveParameter, "YYYYMMDD, e.g. 20140514.", undef);


#AddValidOption(\%f_hValidOption, "--filelist", [ $f_szImportCommand ], $nHaveParameter, "", undef);


my %f_hOptionInteractionForCommand;

# This variable assignement is to make the copy and paste work from bootmgmt.rb
#  'required' here means, the option has to be available when performing the command.
#    it does not mean that the option is mandatory on the CLI.
my $szCommand = $f_szImportCommand;

$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--arch"}      = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--distro"}    = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--release"}   = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--srcdir"}    = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"} = {};
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"}{"exclude"} = [ "--srctgz" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--srctgz"} = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"} = {};
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"}{"exclude"} = [ "--srcdir" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"}{"necessity"} = "required";
 
$szCommand = $f_szAddCommand;

$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--arch"}      = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--distro"}    = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--release"}   = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--srcdir"}    = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"} = {};
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"}{"exclude"} = [ "--srctgz", "--srciso" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcdirOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--srctgz"} = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"} = {};
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"}{"exclude"} = [ "--srcdir", "--srciso" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srctgzOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--srciso"} = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcisoOneOf"} = {};
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcisoOneOf"}{"exclude"} = [ "--srcdir", "--srctgz" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--srcisoOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--timestamp"} = "required";

#$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--filelist"} = "required";


# ============================================================
#                       F U N C T I O N S
# ============================================================

# -----------------------------------------------------------------
#  Generate the target dir name
#  Fail if target dir name exists, unless this is 'update'
#  Create the target directory.
#  (clean the target directory.)
#  copy the rpm files to the target directory.
#  create the repo file.
#  link the squashfs.
#  generate the .treeinfo file
#  update the distro.yaml file.
# ---------------
sub CommandHandlingForAdd {
  my $refhCombinedData = shift;

  my %hCombinedData = %{$refhCombinedData};
  print Dumper(\%hCombinedData);

  my $szTargetDirectory = GetAbsolutePathToDestinationRepoDirForDistroOptionallyWithTimeStamp($refhCombinedData);

  if ( ! -d $szTargetDirectory ) {
    DieIfExecuteFails("mkdir -p $szTargetDirectory");
  }

  # TODO V Barf if the dir exists and this is add, not update.
  # if this is an update, clean the dir.
  `rm -f $szTargetDirectory/*.rpm`;

  print "III Copy RPMs: cp $hCombinedData{'--srcdir'}/*.rpm $szTargetDirectory\n";
  DieIfExecuteFails("cp $hCombinedData{'--srcdir'}/*.rpm $szTargetDirectory");

  print "III Create the repodata.\n";
  DieIfExecuteFails("cd $szTargetDirectory; createrepo .");

  foreach my $szKey (keys %hCombinedData) {
    if ( $szKey =~ /^--/ ) {
      my $szNewKeyName = $szKey;
      $szNewKeyName =~ s/^--//;
      print "DDD $szKey => $szNewKeyName\n";
      $hCombinedData{$szNewKeyName} = $hCombinedData{$szKey};
    }
  }
  
  my $szOutput = `cd $szTargetDirectory; sha256sum $f_szRepoMdFileName`;
  $hCombinedData{'szRepomdXmlSha256'} = (split('\s+', $szOutput))[0];

  print "III generate the .treeinfo file\n";
  my $template = Text::Template->new(TYPE => 'FILE', SOURCE => "$f_szTreeInfoTemplate")
        or die "Couldn't construct template: $Text::Template::ERROR";

  my $szResult = $template->fill_in(HASH => \%hCombinedData);
  
  open(TREEINFO, ">$szTargetDirectory/.treeinfo") || die("!!! unable to open file for write: $szTargetDirectory/.treeinfo : $!");
  print TREEINFO $szResult ;
  close(TREEINFO);

  print "XXX TODO C update the distro.yaml file.\n";
} # end CommandHandlingForAdd




# -----------------------------------------------------------------
# ---------------
sub CommandHandlingForImport {
  my $refhCombinedDate = shift;

  my %hCombinedDate = %{$refhCombinedDate};

  # Create a tmp dir in /tmp
  my $szTempDir = tempdir( CLEANUP => 1 );

  # Copy the filelist.xml.tgz there.
  my $szFullPathToImageRepoDataDirectory = GetAbsolutePathToImageRepoDataDirectory(\%hCombinedDate);

  DieIfExecuteFails("cp $szFullPathToImageRepoDataDirectory/*filelists.xml.gz $szTempDir");
  
  # Unzip the filelist.
  DieIfExecuteFails("gzip -d $szTempDir/*filelists.xml.gz");
  
  my @arOutput = `ls -1 $szTempDir/*filelists.xml`;
  my $szFileListName = $arOutput[0];
  chomp($szFileListName);
  
  my $szFullPathToDestinationRepoDirForDistro = GetAbsolutePathToDestinationRepoDirForDistro(\%hCombinedDate);
  # TODO V Create the repo dir, if it does not exist.
  if ( ! -d $szFullPathToDestinationRepoDirForDistro ) {
    DieIfExecuteFails("mkdir $szFullPathToDestinationRepoDirForDistro");
    # Update the distros.yaml with the repo dir(If it does not exist).
    print "III   Updating the distros.yaml file, adding the repo distro subdir\n";
    AddExtraRepoPathToDistroConfigFile($hCombinedDate{'BS_DISTRO_CONFIGURATION_FILE'},\%hCombinedDate);
  } else {
    print "III    the distros.yaml is not updated, since it is expected to be up to date since the distro dir existed\n";
  }

  my $xmlRoot = LoadXmlTree( $szFileListName );

  open(LOG, ">$f_szLogFileName") or die("!!! unable to open the '$f_szLogFileName' for writing. $!");

  # Process the submitted files.
  my @arRepoPkgList = `ls -1 $hCombinedDate{'--srcdir'}`;
  print "III Going through $#arRepoPkgList RPM files to identify the ones that needs to be added to the extra_repo.\n";
  foreach my $szPkgFile (@arRepoPkgList) {
    chomp($szPkgFile);
    my %hPkgInformation = GetRpmInformationOfRpm("$hCombinedDate{'--srcdir'}/$szPkgFile");
    #print "Pkg name: '$szPkgName'\n";

    # If the file exists in the destination dir, then take the next file in the list
    if ( ! -f "$szFullPathToDestinationRepoDirForDistro/$szPkgFile" ) {
      # If the file is in the filelist.xml then take the next file in the list
      if ( ! PkgExistsInBaseImage($xmlRoot, $hPkgInformation{Name}, $hPkgInformation{Version}) ) {
        # Copy the file to the destination dir
        print LOG "New file: $szPkgFile\n";
        DieIfExecuteFails("cp $hCombinedDate{'--srcdir'}/$szPkgFile $szFullPathToDestinationRepoDirForDistro");
      } else {
        print LOG "Exists in base image: $hPkgInformation{Name} $hPkgInformation{Version}\n";
      }
    } else {
      print LOG "Exists in repo: $szFullPathToDestinationRepoDirForDistro/$szPkgFile\n";
    }
  } # end foreach.
  close(LOG);

  # Run createrepo in the target directory.
  print "III update the repo configuration files.\n";
  DieIfExecuteFails("cd $szFullPathToDestinationRepoDirForDistro; createrepo .");
  print "III If you have any problems, please see the log file: $f_szLogFileName\n";
  print "III Done.\n";

} # end CommandHandlingForImport.



# -----------------------------------------------------------------
# ---------------
sub DieOnInvalidCommand {
  my $szCommand = shift;
  if ( ! exists($f_hSupportedCommands{$szCommand}) ) {
    die("!!! Please provide a valid command, this command is not supported: ${szCommand}");
  }
}



# -----------------------------------------------------------------
# ---------------
sub GetRpmInformationOfRpm {
  my $szRpmFileName = shift;

  my %hReturnHash;

  chomp($szRpmFileName);
  my @arOutput = `rpm -qip $szRpmFileName 2> /dev/null | grep :`;

  foreach my $szLine (@arOutput) {
    my ($szKey, $szValue) = split(':', $szLine);
    chomp($szValue);
    # trim the name.
    $szValue =~ s/^\s+//;
    $szValue =~ s/\s+$//;
    $szKey   =~ s/^\s+//;
    $szKey   =~ s/\s+$//;

    $hReturnHash{$szKey} = $szValue;
  }
  return(%hReturnHash);
}

# -----------------------------------------------------------------
# ---------------
sub LoadVariableFromEnvironment {
  my $refhFinishedValues = shift;

  my @arEnvVarToLookFor = (
                             "BS_IMAGE_BASE_DIRECTORY",
                             "BS_BOOT_KERNEL_BASE_DIRECTORY",
                             "BS_CONFIG_BASE_DIRECTORY",
                             "BS_DISTRO_CONFIGURATION_FILE"
                          );

  foreach my $szEnvVarName (@arEnvVarToLookFor) {
    if ( exists $ENV{$szEnvVarName} ) {
      # TODO C validate that this is a clean dir and not some command.
      $refhFinishedValues->{$szEnvVarName} = $ENV{$szEnvVarName};
    }
  } # end foreach.
} # LoadVariableFromEnvironment.

# -----------------------------------------------------------------
# ---------------
sub PkgExistsInBaseImage {
  my $xmlRoot = shift;
  my $szPkgName = shift;
  my $szPkgVersion = shift;

  my $nPkgExists = 0;  

  my  $xmlPackageNode = GetSingleChildNodeByTagAndAttribute($xmlRoot, "package", "name", $szPkgName);
  if ( defined($xmlPackageNode) ) {
    my @arList = GetNodeArrayByTagName($xmlPackageNode, "version");
    my $xmlVersionElement = shift @arList;
    if (  $xmlVersionElement->getAttribute("ver") eq $szPkgVersion ) {
      $nPkgExists = 1;
    }
  }

  return($nPkgExists);
}


# ============================================================

                #     #    #      ###   #     #
                ##   ##   # #      #    ##    #
                # # # #  #   #     #    # #   #
                #  #  # #     #    #    #  #  #
                #     # #######    #    #   # #
                #     # #     #    #    #    ##
                #     # #     #   ###   #     #

# ============================================================

BscPutConfigDataInHash(\%f_hFinishedValues);

$szCommand = GetNextCliArgument();

DieOnInvalidCommand($szCommand);

if ( $szCommand eq "help" ) {
  cmdOptDisplayHelpText();
  exit 0;
}

LoadVariableFromEnvironment(\%f_hFinishedValues);


# TODO V Do BscOverloadEnvConfigsInHash(\%f_hFinishedValues);
#  With an optional parm of additional keys.

# Validate the CLI parms.
my %hProvidedParameters = HandleCommandLine(\%f_hValidOption, 0);

#print Dumper(\%f_hValidOption);
DieOnInvalidOptionsForCommand($szCommand, \%f_hValidOption, \%hProvidedParameters);
my %hPopulatedOptionList = DieOnSemanticErrorsOfOptionsForCommand($szCommand, \%f_hValidOption, \%hProvidedParameters, \%f_hOptionInteractionForCommand);


my %hDistroKeyData = GetKeyPathsForDistro(
         $f_hFinishedValues{BS_DISTRO_CONFIGURATION_FILE},
         $hPopulatedOptionList{'--distro'},
         $hPopulatedOptionList{'--release'},
         $hPopulatedOptionList{'--arch'},
                                         );

$hPopulatedOptionList{'BootDistroName'} = $hPopulatedOptionList{'--distro'};
$hPopulatedOptionList{'BootDistroId'} = $hPopulatedOptionList{'--release'};
$hPopulatedOptionList{'architechture'} = $hPopulatedOptionList{'--arch'};


# Verify that the distro, rel, arch exist in the distro.yaml file.
if ( ! exists($hDistroKeyData{relative_boot_kernel_path}) ) {
  die("!!! Couldn't find $hPopulatedOptionList{'--distro'} $hPopulatedOptionList{'--release'} $hPopulatedOptionList{'--arch'} in $f_hFinishedValues{BS_DISTRO_CONFIGURATION_FILE}");
}

my $szTgzTmpDir;

# Set to 1 if the fusemount -u needs to be run on szTgzTmpDir.
my $bUnmountIso = 0;

#  If the input is a .tgz then extract the files to a random tmp dir.
if ( exists($hPopulatedOptionList{'--srctgz'}) ) {
  # create a tmpdir
  my $szTempDir = tempdir( CLEANUP => 1 );
  #print "!!! tmpdir: $szTempDir\n";

  print "III extract TGZ file into tmpdir.\n";
  DieIfExecuteFails("cd $szTempDir; tar -zxf $hPopulatedOptionList{'--srctgz'}");

  # set --srcdir
  $hPopulatedOptionList{'--srcdir'} = "$szTempDir/erepo";
}

#  If the input is an ISO
if ( exists($hPopulatedOptionList{'--srciso'}) ) {
  # create a tmpdir
  my $szTempDir = tempdir( CLEANUP => 1 );
  #print "!!! tmpdir: $szTempDir\n";

  print "III mount ISO file on tmpdir: $szTempDir\n";
  DieIfExecuteFails("fuseiso $hPopulatedOptionList{'--srciso'} $szTempDir");
  $bUnmountIso = 1;

  # set --srcdir
  $hPopulatedOptionList{'--srcdir'} = "$szTempDir/Packages";
}

# Validate that the source dir exists.
if ( ! -d $hPopulatedOptionList{'--srcdir'} ) {
  die("!!! directory for RPM import candidates can't be found: $hPopulatedOptionList{'--srcdir'}");
}


my %hCombinedData = ( %hPopulatedOptionList, %f_hFinishedValues);

if ( $szCommand eq "add" ) {
  CommandHandlingForAdd(\%hCombinedData);
} elsif ( $szCommand eq "import" ) {
  CommandHandlingForImport(\%hCombinedData);
} elsif ( $szCommand eq "update" ) {
  my $nAllowToOverwriteConfigFiles = 1;
  CommandHandlingForAdd(\%hCombinedData, $nAllowToOverwriteConfigFiles);
} else {
  die("!!! Command not recognized: $szCommand");
}

print "XXXXXXXXXXXXXX bUnmountIso: $bUnmountIso\n";
if ( $bUnmountIso == 1 ) {
  print "III Unmount the ISO\n";
  DieIfExecuteFails("fusermount -u $szTgzTmpDir");
}

if ( defined($szTgzTmpDir) ) {
  print "III remove the tmpdir.\n";
  unlink($szTgzTmpDir) || die("!!! unable to remove: $szTgzTmpDir $!");
}
