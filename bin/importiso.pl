#!/usr/bin/perl -w

use strict;
use FindBin;

BEGIN {
  push( @INC, "$FindBin::RealBin" );    ## Path to local modules
}

use Text::Template;
use Data::Dumper;


# Example:
# clear; sudo ./importiso.pl --distro ubuntu --release 1404 /vagrant/isos/ubuntu-14.04-server-amd64.iso
# clear; sudo ./importiso.pl --distro fedora --release 19 /vagrant/isos/Fedora-19-x86_64-DVD.iso
#   clear; ./importiso.pl --distro fedora --release 20 my.iso


#TODO C add a relative path to the script dir and use it as an include path form modules.

use BootServerConfigFile;
use CliOptionHandling;
use CommandOptionHandling;
use IsoInfoFile;
use KickstartConfig;
use YamlDistroConfigFile;

# EXAMPLE: ./importiso.rb --combo DIPM /vagrant/isos/DMICRO_SERVER-R03.00.05.05.DISK1.iso
#          clear;./importiso.rb  --distro fedora --release 20


# Guiding moto: Do one thing and do it well.

# ===========================================================================
#                          V A R I A B L E S
# ===========================================================================
# This is a fictisious command, it is here to make this script compatible
#   with the common functions.
my $f_szImportCommand = "import";

my %f_hDefaultValues;

$f_hDefaultValues{"BS_HOME_DIRECTORY"} = "/home/vagrant";
$f_hDefaultValues{"BS_TMP_MOUNT_POINT"} = $f_hDefaultValues{"BS_HOME_DIRECTORY"} . "/mnt";
$f_hDefaultValues{"BS_BOOT_KERNEL_BASE_DIRECTORY"} = "/var/tftp";
$f_hDefaultValues{"BS_BOOT_KERNEL_BASE_DIRECTORY_OWNER"} = "nobody";
$f_hDefaultValues{"BS_IMAGE_BASE_DIRECTORY"} = "/var/ks/images";
$f_hDefaultValues{"BS_CONFIG_BASE_DIRECTORY"} = "/var/ks/configs";

my %f_hFinishedValues;
$f_hFinishedValues{"BS_HOME_DIRECTORY"}             = $f_hDefaultValues{"BS_HOME_DIRECTORY"};
$f_hFinishedValues{"BS_TMP_MOUNT_POINT"}            = $f_hDefaultValues{"BS_TMP_MOUNT_POINT"};
$f_hFinishedValues{"BS_BOOT_KERNEL_BASE_DIRECTORY"} = $f_hDefaultValues{"BS_BOOT_KERNEL_BASE_DIRECTORY"};
$f_hFinishedValues{"BS_BOOT_KERNEL_BASE_DIRECTORY_OWNER"} = $f_hDefaultValues{"BS_BOOT_KERNEL_BASE_DIRECTORY_OWNER"};
$f_hFinishedValues{"BS_IMAGE_BASE_DIRECTORY"}       = $f_hDefaultValues{"BS_IMAGE_BASE_DIRECTORY"};
$f_hFinishedValues{"BS_CONFIG_BASE_DIRECTORY"}      = $f_hDefaultValues{"BS_CONFIG_BASE_DIRECTORY"};
$f_hFinishedValues{"BS_DISTRO_CONFIGURATION_FILE"}  = "/var/ks/distros.yaml";


# This is a definition of all the valid options.
my %f_hValidOption;
my $nHaveParameter = 1;
AddValidOption(\%f_hValidOption, "--distro",     [ $f_szImportCommand ], $nHaveParameter, "Distribution name. E.g. 'fedora'", undef);
AddValidOption(\%f_hValidOption, "--arch",       [ $f_szImportCommand ], $nHaveParameter, "Architecture. e.g. 'x86_64'", "x86_64");
AddValidOption(\%f_hValidOption, "--release",    [ $f_szImportCommand ], $nHaveParameter, "Release ID, e.g. '20' or '10u8'", undef);
AddValidOption(\%f_hValidOption, "--mountpoint", [ $f_szImportCommand ], $nHaveParameter, "temporary mountpoint for the ISO.", $f_hDefaultValues{"BS_TMP_MOUNT_POINT"});


#print Dumper(%f_hValidOption);

my %f_hOptionInteractionForCommand;

# This variable assignement is to make the copy and paste work from bootmgmt.rb
#  'required' here means, the option has to be available when performing the command.
#    it does not mean that the option is mandatory on the CLI.
my $szCommand = $f_szImportCommand;
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--distro"} = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--distroOneOf"}{"exclude"} = [ "--combo" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--distroOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--combo"} = "OneOf";
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--comboOneOf"}{"exclude"} = [ "--distro" ];
$f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--comboOneOf"}{"necessity"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--release"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--arch"} = "required";
$f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--mountpoint"} = "required";

#print Dumper(%f_hOptionInteractionForCommand);

# ============================================================
#                       F U N C T I O N S
# ============================================================

# -----------------------------------------------------------------
# ---------------
sub CommandHandlingForImport {
  my $refhcombinedData = shift;

  my %hCombinedData = %$refhcombinedData;

#print Dumper(%hPopulatedOptionList);
#print "---\n";
#print Dumper(%hFinishedValues);
#print Dumper(\%hCombinedData);

  if ( ! -f $hCombinedData{"IsoImageName"} ) {
    die("!!! ISO image does not exist: " . $hCombinedData{"IsoImageName"});
  }

  DieIfIsoAlreadyMounted(\%hCombinedData);

  DieIfExecuteFails("fuseiso " . $hCombinedData{"IsoImageName"} . " " . $hCombinedData{"BS_TMP_MOUNT_POINT"});

  # TODO Validate the kernel target dir exists
  # If Distribution is given, then call that function, and the distribution can then
  #    call any OS/Arch specific functions.

  # If this is a --combo, then populate the ISO kernel data.
  if ( ! exists $hCombinedData{"--distro"} ) {
    die("!!! Developer: Please implement handling of missing --distro, that would be extracting the info based on the --combo.");
  }
  $hCombinedData{"BootDistroName"} = $hCombinedData{"--distro"};
  $hCombinedData{"BootDistroId"}   = $hCombinedData{"--release"};
  $hCombinedData{"Arch"}           = $hCombinedData{"--arch"};

  #  based on --distro get: KernelFileList and RelativeKernelSource.
  IifPutiIsoInfoDataInHash(\%hCombinedData);

  CopyBootKernel(\%hCombinedData);

  CopyIsoContent(\%hCombinedData);

  # TODO V Only do this if it exists. In F20 it does not exist.
  #CopyDefaultKickStartCfg();


  #UpdateBootDataFiles();  
  print "III Writing config file to: $hCombinedData{BS_DISTRO_CONFIGURATION_FILE}\n";
  UpdateDistroConfigFile($hCombinedData{BS_DISTRO_CONFIGURATION_FILE}, \%hCombinedData);

  sleep 1;
  DieIfExecuteFails("fusermount -u $hCombinedData{'BS_TMP_MOUNT_POINT'}");
} # end CommandHandlingForImport




# -----------------------------------------------------------------
# ---------------
sub CopyBootKernel {
  my $refhFinishedValues = shift;

  my %hFinishedValues = %$refhFinishedValues;


   #print Dumper(%hFinishedValues);

  # TODO V verify predefinitions, like BootDistroName having been defined.
  # TODO C Populate $f_hCardinalIsoData
  my $szBootKernelTarget = $hFinishedValues{"BootDistroName"} . "_" . $hFinishedValues{"BootDistroId"} . "_" . $hFinishedValues{"Arch"};

  my $szDestinationDirectory = $hFinishedValues{"BS_BOOT_KERNEL_BASE_DIRECTORY"} ."/${szBootKernelTarget}";

  if ( ! -d $szDestinationDirectory ) {
    # Create target directory if it does not exists.
    DieIfExecuteFails("mkdir $szDestinationDirectory");
    # copy all boot kernel files.
#print Dumper(\%hFinishedValues);
    print "III Copy boot kernel files to $szDestinationDirectory\n";
    foreach my $szKernelFile (@{$hFinishedValues{"KernelFiles"}}) {
      #print "DDD szKernelFile: ${szKernelFile}\n";
      DieIfExecuteFails("cp $hFinishedValues{'BS_TMP_MOUNT_POINT'}/$hFinishedValues{'RelativeKernelSource'}/${szKernelFile} $szDestinationDirectory");
    }
    DieIfExecuteFails("chown -R $hFinishedValues{'BS_BOOT_KERNEL_BASE_DIRECTORY_OWNER'} $szDestinationDirectory");
  } else {
    # TODO C Unless clobber is in effect then if the files exists at the target then fail.
    print "WWW Boot kernel files not copied, since target directory exists:  $hFinishedValues{'BS_BOOT_KERNEL_BASE_DIRECTORY'}/${szBootKernelTarget}\n";
  }
}




# -----------------------------------------------------------------
# copy the packages
# ---------------
sub CopyIsoContent {
  my $refhFinishedValues = shift;

  my %hFinishedValues = %$refhFinishedValues;

  my $szIsoContentTarget = $hFinishedValues{"BootDistroName"} . "_" . $hFinishedValues{"BootDistroId"} . "_" . $hFinishedValues{"Arch"};
  my $szDestinationDirectory = $hFinishedValues{"BS_IMAGE_BASE_DIRECTORY"} ."/" . $szIsoContentTarget;

  if ( ! -d $szDestinationDirectory ) {
    # Create target directory if it does not exists.
    # Create target directory if it does not exists.
    ExecuteCmd("mkdir $szDestinationDirectory");
    # copy all files.
    #Trace(7, "DDD ISO content to #{$f_szImagesBaseDirectory}/#{$f_hCardinalIsoData["ImageTarget"]}")
    print "III Copy ISO content to $szDestinationDirectory\n";
    ExecuteCmd("cp -r $hFinishedValues{'BS_TMP_MOUNT_POINT'}/. $szDestinationDirectory");
  } else {
    # TODO C Unless clobber is in effect then if the files exists at the target then fail.
    print "WWW ISO content files are not copied, since target directory exists: $szDestinationDirectory\n";
  }
} # end CopyIsoContent



# -----------------------------------------------------------------
# ---------------
sub DieIfIsoAlreadyMounted {
  my $refhFinishedValues = shift;

  my %hFinishedValues = %$refhFinishedValues;
  
  my $szTmpMountPoint = $hFinishedValues{"BS_TMP_MOUNT_POINT"};
  my @arOutput = `grep $szTmpMountPoint $hFinishedValues{"BS_HOME_DIRECTORY"}/.mtab.fuseiso`;
  if ( defined($arOutput[0]) && $arOutput[0] =~ /$szTmpMountPoint/ ) {
    die("!!! The tmp mount point is in use. Please unmount; fusermount -u $szTmpMountPoint");
  }
}


# -----------------------------------------------------------------
# ---------------
sub DieIfExecuteFails {
  my $szCmd = shift;

  # TODO V die on empty command.

  my @arOutput = `$szCmd`;
  if ( $? != 0 ) {
    die("!!! operaiont failed '$szCmd': @arOutput");
  }
} # end DieIfExecuteFails


# -----------------------------------------------------------------
# ---------------
sub ExecuteCmd {
  my $szCmd  = shift;
  my $nAudit = shift;

  if ( !defined($nAudit) ) {
    $nAudit=0;
  } #endif auditing undefined.

#  if ( $nAudit == 1 ) {
#    $szCmd = "$f_szClearAudit -c '$szCmd'";
#  } # endif audition.

  # TODO: Check that a command was given.
#   $f_pLogHandler->notice("exec: $szCmd");
  # Why do it twice?
#   #$f_pLogHandler->info("exec: $szCmd ");

  my  $nRc;
  my @arOutput;
#  if ( $f_nDryRun == $f_nEnable ) {
#    push(@arOutput, "DRYRUN: $szCmd  2>&1");
#    $nRc=0;
#  } else {
    @arOutput = `$szCmd   2>&1`;
    $nRc=$?;
#  }
#  if ( $nRc == 0 ) {
#    $f_pLogHandler->notice(@arOutput);
#    print "[Ok]\n";
#  } else {
#    $f_pLogHandler->error(@arOutput);
#    $f_pLogHandler->critical("FAILED $nRc");
#    carp("[FAIL]");
#  } # endif rc

  return($nRc);
} # endif execcheck




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

# Load the Configurations from the config_boot_server_tool.yaml
BscPutConfigDataInHash(\%f_hFinishedValues);


LoadVariableFromEnvironment(\%f_hFinishedValues);

#print Dumper(%f_hValidOption);

#print Dumper(%f_hValidOption);
my %hProvidedParameters = HandleCommandLine(\%f_hValidOption, 1);
#print Dumper(%f_hValidOption);

#print Dumper(%hProvidedParameters);

#my %tmp = ( "--combo", "Alpha" );
#$tmp{"--release"} = "20";
#print Dumper(%tmp);

#print "Release: $tmp{'--release'}\n";

DieOnInvalidOptionsForCommand($f_szImportCommand, \%f_hValidOption, \%hProvidedParameters);
my %hPopulatedOptionList = DieOnSemanticErrorsOfOptionsForCommand($f_szImportCommand, \%f_hValidOption, \%hProvidedParameters, \%f_hOptionInteractionForCommand);

#print Dumper(%hProvidedParameters);
#print "---\n";
#print Dumper(%hPopulatedOptionList);

$f_hFinishedValues{"IsoImageName"} = GetNextCliArgument("!!! You must provide the name of the ISO image at the end.");

my %hCombinedData = ( %hPopulatedOptionList, %f_hFinishedValues);

CommandHandlingForImport(\%hCombinedData);
