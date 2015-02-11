#!/usr/bin/perl -w

use strict;
use FindBin;

BEGIN {
  push( @INC, "$FindBin::RealBin" );    ## Path to local modules
}


use Text::Template;
use Data::Dumper;
use ExecuteAndTrace;

# Example: 

#  clear; sudo ./bootmgmt.pl add --mac 080027C4D9ED --distro ubuntu --release 1404 --arch x86_64
#  clear; sudo ./bootmgmt.pl add --mac 080027600349 --distro fedora --release 20 --arch x86_64 --role yumdownload
#  clear; sudo ./bootmgmt.pl update --mac 080027346180 --distro fedora --release 20 --arch x86_64 --role vagrant
#  clear; sudo ./bootmgmt.pl add --mac 080027346180 --distro fedora --release 19 --arch x86_64
#  clear; sudo ./bootmgmt.pl add --mac 080027346180 --distro fedora --release 19 --arch x86_64 --media nfs
# export BS_DISTRO_CONFIGURATION_FILE="/home/vagrant/distro.yaml"
# clear; ./bootmgmt.pl add --mac TUT --distro fedora --release 20 --arch x86_64

# Example: clear; ./bootmgmt.pl add --mac TUT --distro fedora --release 20 --arch x86_64
#TODO C add a relative path to the script dir and use it as an include path form modules.

use BootServerConfigFile;
use BstShortcuts;
use CliOptionHandling;
use CommandOptionHandling;
use KickstartConfig;
use MacAddressHandling;
use RoleFileHandler;
use XmlDistroConfigFile;

sub TRUE { return(1) };

# TODO V I need to figure out how I can handle required vs. optional options,
#   required, in this script means that the parameter is required for successfull execution.
#     if the required option has a default value, that means the user is not required to enter it.
#     if the required option has no deault value, then the user is required to enter it.
#   A truly optional option, is like a comment, that would go in as a comment in the boot cfg file.
# TODO V include automated support for e.g. 'bootmgmt.rb help add'


# ===========================================================================
#                          V A R I A B L E S
# ===========================================================================

my $f_szTftpBootKernelPath = "relative_boot_kernel_path";

my %f_hFinishedValues;

my %f_hSupportedCommands;
  $f_hSupportedCommands{"help"} = "This help text. For more information do help 'command'";
  $f_hSupportedCommands{"add"} = "add a new configuration, will fail if already exists.";
  $f_hSupportedCommands{"delete"} = "delete existing configuration, fail if doesn't exists.";
  $f_hSupportedCommands{"update"} = "Update: will write booth the boot cfg and ks.cfg whether they exist or not.";
  $f_hSupportedCommands{"query"} = "list information on current configurations.";

my %f_hValidOption;
 my $szOptionName;

 $szOptionName = "--arch";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Architecture. e.g. 'x86_64'";
   $f_hValidOption{$szOptionName}{"Default"} = "x86_64";

 $szOptionName = "--combo";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Combined DVD name. E.g. 'DIPM'";

 $szOptionName = "--distro";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Distribution name. E.g. 'fedora'";
   $f_hValidOption{$szOptionName}{"Default"} = "fedora";

 $szOptionName = "--externalcfg";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "External cfg to translate and use.";
# TODO V Find a way to name the resulting .cfg
#   Possibly if the first line in the external cfg starts with 'Name:' have a max name length.

 $f_hValidOption{"--mac"} = {};
   $f_hValidOption{"--mac"}{"ValidCommandList"} = [ "add", "delete", "update", "query" ];
   $f_hValidOption{"--mac"}{"HasParameter"} = TRUE;
   $f_hValidOption{"--mac"}{"Description"} = "MAC address, lower or upper-case. E.g. '08002723A3D2'";

 $szOptionName = "--media";
 $f_hValidOption{szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Deployment media for the boot installation, e.g. 'nfs'";
   $f_hValidOption{$szOptionName}{"Default"} = "http";


 $szOptionName = "--release";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Release ID, e.g. '20' or '10u8'";
   $f_hValidOption{$szOptionName}{"Default"} = "20";

 $szOptionName = "--role";
 $f_hValidOption{$szOptionName} = {};
   $f_hValidOption{$szOptionName}{"ValidCommandList"} = [ "add", "update" ];
   $f_hValidOption{$szOptionName}{"HasParameter"} = TRUE;
   $f_hValidOption{$szOptionName}{"Description"} = "Role name, e.g. 'vagrant' or 'kvm'";


  my %f_hOptionInteractionForCommand;

  my $szCommand = "add";
  $f_hOptionInteractionForCommand{$szCommand} = {};
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"} = {};
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"} = {};
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--mac"} = "required";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--media"} = "required";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--distro"} = "OneOf";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--distroOneOf"} = {};
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--distroOneOf"}{"exclude"} = [ "--combo" ];
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--distroOneOf"}{"necessity"} = "required";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--combo"} = "OneOf";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--comboOneOf"} = {};
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--comboOneOf"}{"exclude"} = [ "--distro" ];
  $f_hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"--comboOneOf"}{"necessity"} = "required";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--release"} = "required";
  $f_hOptionInteractionForCommand{$szCommand}{"OptionList"}{"--arch"} = "required";

  $f_hOptionInteractionForCommand{"update"} = $f_hOptionInteractionForCommand{"add"};


# ============================================================
#                       F U N C T I O N S
# ============================================================

# -----------------------------------------------------------------
#  Execute the add command.
#  This function expects the hProvidedOptions complete and valid.
#   It is exected that validations have been made by:
#    - DieOnSemanticErrorsOfOptionsForCommand()
#    - DieOnInvalidOptionsForCommand
#  Generate the:
#    - tftboot cfg file for the given MAC address.
#    - kickstart configuration file for the role?
#
#  Parameters:
#   - $refhPopulatedOptionList: hash reference with all relevant keys defined.
#   - $nAllowToOverwriteConfigFiles: Optional, default 0. If set(1) then ks.cfg 
#      will be overwritten if it exists.
# ---------------
sub CommandHandlingForAdd {
  my $refhBootConfiguration = shift;
  my $nAllowToOverwriteConfigFiles = shift || 0;

  # De-reference the hash. 
  my %hBootConfiguration = %{$refhBootConfiguration};

  $hBootConfiguration{"BootDistroName"} = $hBootConfiguration{"--distro"};
  $hBootConfiguration{"BootDistroId"}   = $hBootConfiguration{"--release"};
  $hBootConfiguration{"Architechture"}  = $hBootConfiguration{"--arch"};
  $hBootConfiguration{"InstallMedia"}   = $hBootConfiguration{"--media"};

  # TODO V when solaris support is introduced, this must become configurable.
  $hBootConfiguration{"machine"}            = "x86_64";


  $hBootConfiguration{"relative_ks_cfg_path_and_name"} = $hBootConfiguration{'BS_RELATIVE_CONFIG_DIRECTORY'};
  $hBootConfiguration{"relative_ks_cfg_path_and_name"} .= "/ks_" . GetDistroDirectoryName(\%hBootConfiguration);

  #print Dumper(\%hBootConfiguration);
  my $szKickstartFile;

  if ( $hBootConfiguration{"InstallMedia"} eq "nfs" ) {
    $hBootConfiguration{"install_media_type"}  = "nfs:";
    $hBootConfiguration{"base_path"}           = ":$hBootConfiguration{'BS_NFS_BASE_PATH'}";
    $hBootConfiguration{"relative_ks_cfg_path_and_name"}   .= "_nfs";
    $szKickstartFile = $hBootConfiguration{"BS_NFS_BASE_PATH"} . "/" . $hBootConfiguration{"relative_ks_cfg_path_and_name"};
  } elsif ( $hBootConfiguration{"InstallMedia"} eq "http" ) {
    $hBootConfiguration{"install_media_type"}  = "http://";
    $hBootConfiguration{"base_path"}           = ":$hBootConfiguration{'BS_HTTP_PORT_NUMBER'}";
    $hBootConfiguration{"relative_ks_cfg_path_and_name"}   .= "_http";
    # Here we are prepending the BS_RELATIVE_CONFIG_DIRECTORY.
    $szKickstartFile = $hBootConfiguration{"BS_NFS_BASE_PATH"};
    $szKickstartFile .= "/" . $hBootConfiguration{"relative_ks_cfg_path_and_name"};
  } else {
    die("!!! Media not supported, unknown: $hBootConfiguration{'--media'}");
  }

  if ( exists($hBootConfiguration{'--role'}) ) {
    $hBootConfiguration{"relative_ks_cfg_path_and_name"}   .= "_$hBootConfiguration{'--role'}";
    $szKickstartFile .= "_$hBootConfiguration{'--role'}";
  }
  $hBootConfiguration{"relative_ks_cfg_path_and_name"}   .= ".cfg";
  $szKickstartFile .= ".cfg";

  if ( ! -d "/$hBootConfiguration{'BS_BOOT_KERNEL_BASE_DIRECTORY'}/$hBootConfiguration{$f_szTftpBootKernelPath}" ) {
    die("!!! Required TFTP boot path does not exist: $hBootConfiguration{$f_szTftpBootKernelPath} under /$hBootConfiguration{'BS_BOOT_KERNEL_BASE_DIRECTORY'} (defined by: BS_BOOT_KERNEL_BASE_DIRECTORY)");
  }


  # TODO ? Verify that the ks cfg file exists.

  # TODO V Before supporting ESXi, then include the kernel list in the Hash since it is needed by the boot cfg file.

  # TODO N When solaris is introduced, make the tmpl name configurable (also for ESXi).

  my $template = Text::Template->new(TYPE => 'FILE', SOURCE => '/opt/OPSbst/templates/tftp_boot_linux.tmpl')
          or die "Couldn't construct template: $Text::Template::ERROR";

  my $szResult = $template->fill_in(HASH => \%hBootConfiguration);
  
  #print "DDD \n$szResult\n";
  # TODO V create a function that will translate the mac addr from a ':' address or '' to '-' address.
  my $szMacAddress = ReturnMacDashedFormat($hBootConfiguration{'--mac'});
  my $szConfigFileName = "$f_hFinishedValues{'BS_BOOT_KERNEL_BASE_DIRECTORY'}/pxelinux.cfg/$szMacAddress";
  print "    Writing boot config file: $szConfigFileName\n";
  open(CONFIG_FILE, ">$szConfigFileName") || die("!!! Unable to open file for write '$!': $szConfigFileName");
  print CONFIG_FILE $szResult;
  close(CONFIG_FILE);
  DieIfExecuteFails("chown nobody $szConfigFileName");


  if (  -f $szKickstartFile && ! $nAllowToOverwriteConfigFiles ) {
    # Don't over-write the kickstart config file, unless we are allowed to overwrite.
    print "    Using existing $szKickstartFile\n";
  } else {
    print "    Writing new ks cfg file: $szKickstartFile\n";
    # TODO N These values are somehow available to the boot conf, figure out, which and make it the same in both cases.
    GenerateKickstartFile(\%hBootConfiguration, $szKickstartFile);
  }

  if ( exists($hBootConfiguration{'--externalcfg'}) ) {
    print "   Translating the external KS to $szKickstartFile\n";
    KscTranslateExternalKsCfgFile(\%hBootConfiguration, $szKickstartFile);
  }
} # CommandHandlingForAdd.

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

my %hProvidedParameters = HandleCommandLine(\%f_hValidOption, 1);

DieOnInvalidOptionsForCommand($szCommand, \%f_hValidOption, \%hProvidedParameters);


my %hPopulatedOptionList = DieOnSemanticErrorsOfOptionsForCommand($szCommand, \%f_hValidOption, \%hProvidedParameters, \%f_hOptionInteractionForCommand);

#print Dumper(%f_hFinishedValues);
#print Dumper(\%hPopulatedOptionList);

my %hKeyPaths = GetKeyPathsForDistro( 
                      $f_hFinishedValues{"BS_DISTRO_CONFIGURATION_FILE"},
                      $hPopulatedOptionList{"--distro"},
                      $hPopulatedOptionList{"--release"},
                      $hPopulatedOptionList{"--arch"},
                    );
my @arKeyList = ( $f_szTftpBootKernelPath, "relative_install_image_path" );
foreach my $szKey (@arKeyList) {
  if ( exists( $hKeyPaths{$szKey} ) ) {
    $hPopulatedOptionList{$szKey} = $hKeyPaths{$szKey};
  } else {
    die("!!! Missing data entry: $szKey");
  }
}
if ( exists($hKeyPaths{'relative_extra_repo_path'}) ) {
  $hPopulatedOptionList{'relative_extra_repo_path'} = $hKeyPaths{'relative_extra_repo_path'};
}

my %hCombinedData = ( %hPopulatedOptionList, %f_hFinishedValues);

if ( exists($hPopulatedOptionList{"--role"}) ) {
  my %hRoleConfigurations = ReadRoleConfigurationBlocksIntoHash($hPopulatedOptionList{"--role"});
  %hCombinedData = ( %hCombinedData, %hRoleConfigurations);
}

#print Dumper(\%hCombinedData);

if ( $szCommand eq "add" ) {
  CommandHandlingForAdd(\%hCombinedData);
} elsif ( $szCommand eq "update" ) {
  my $nAllowToOverwriteConfigFiles = 1;
  CommandHandlingForAdd(\%hCombinedData, $nAllowToOverwriteConfigFiles);
} else {
  die("!!! Command not recognized: $szCommand");
}


