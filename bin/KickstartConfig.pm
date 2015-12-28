package KickstartConfig;

# This module allows you to create a Kickstart configuration file.

use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use Text::Template;
use BstShortcuts;

$VERSION = 0.5.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &GenerateKickstartFile
                &KscTranslateExternalKsCfgFile
            );

# -----------------------------------------------------------------
# Parameters:
#  - $refhFinishedValues(Mandatory)
#  - $szDestinationFileName(Optional)
#
#  Required keys:
#    - BS_CONFIG_BASE_DIRECTORY
#    - BS_RELATIVE_CONFIG_DIRECTORY
#    - BS_NFS_BASE_PATH
#    - BootDistroName
#    - BootDistroId
#    - Architechture
#    - InstallMedia
#    - 
#  optional keys:
#    - KS_KEYBOARD
#    - EncryptedPassword
#    - media_host_address
#    - time_zone
# ---------------
sub GenerateKickstartFile {
  my $refhFinishedValues = shift;
  my $szDestinationFileName = shift;

  my %hFinishedValues = %$refhFinishedValues;

  #print Dumper(\%hFinishedValues);

  my @arMandatoryKeys = (
      "BS_CONFIG_BASE_DIRECTORY",
      "BS_RELATIVE_CONFIG_DIRECTORY",
      "BS_RELATIVE_IMAGE_DIRECTORY",
      "BS_NFS_BASE_PATH",
      "BootDistroName",
      "BootDistroId",
      "Architechture",
      "InstallMedia"
                        );

  foreach my $szMandatoryKey (@arMandatoryKeys) {
    if ( ! exists($hFinishedValues{$szMandatoryKey}) ) {
      die("!!! Mandatory key not defined, please define it: $szMandatoryKey");
    }
  }

  my $szDistroIdArch = GetDistroDirectoryName(\%hFinishedValues);

  $hFinishedValues{"relative_ks_cfg_path_and_name"} = $hFinishedValues{"BS_RELATIVE_CONFIG_DIRECTORY"} . "/ks_";
  $hFinishedValues{"relative_ks_cfg_path_and_name"} .= $szDistroIdArch;


  if ( ! exists($hFinishedValues{time_zone}) ) {
    $hFinishedValues{time_zone} = "Europe/Amsterdam";
  }

  my $szKickstartFile = DefineInstallMediaKeys(\%hFinishedValues);

#print "$hFinishedValues{KS_INSTALL_SOURCE_SELECTION}\n";
#print "$hFinishedValues{KS_REPO_SOURCE_SELECTION}\n";


  if ( ! defined($szDestinationFileName) ) {
    $szDestinationFileName = $szKickstartFile;
    # was: $hFinishedValues{"BS_CONFIG_BASE_DIRECTORY"} . "/ks_" . $hFinishedValues{"BootDistroName"} . "_" . $hFinishedValues{"BootDistroId"} . "_" . $hFinishedValues{"Arch"} . ".cfg";
  } 


  # TODO make it possible to pick this from the ENV.
  if ( ! exists($hFinishedValues{KS_KEYBOARD}) ) {
    $hFinishedValues{KS_KEYBOARD} = 'dk';
  }

  # TODO N Make it possible to provide the root password through ENV and CLI.
  if ( ! exists($hFinishedValues{EncryptedPassword}) ) {
    $hFinishedValues{EncryptedPassword} = `echo "ChangeMe"|openssl passwd -1 -stdin`;
    chomp($hFinishedValues{EncryptedPassword});
  }

  my $template = Text::Template->new(TYPE => 'FILE', SOURCE => '/opt/OPSbst/templates/kickstart.tmpl')
          or die "Couldn't construct template: $Text::Template::ERROR";

  my $szResult = $template->fill_in(HASH => \%hFinishedValues);

print Dumper(\%hFinishedValues);

  if ( defined($szResult) ) {
    print "III Writing the Kickstart config file to: $szDestinationFileName\n";
    open(KS_CFG_FILE, ">$szDestinationFileName") || die("Unable to write to: $szDestinationFileName ($!)");
    print KS_CFG_FILE $szResult;
    close(KS_CFG_FILE);
  } else {
    die "Couldn't fill in template: $Text::Template::ERROR"
  }

} # end GenerateKickstartFile.


# -----------------------------------------------------------------
# ---------------
sub DefineInstallMediaKeys {
  my $refhFinishedValues = shift;

  my $szKickstartFile;

  if ( ! exists($refhFinishedValues->{BS_HTTP_PORT_NUMBER}) ) {
    $refhFinishedValues->{BS_HTTP_PORT_NUMBER} = "80";
  }

  if ( ! exists($refhFinishedValues->{BS_MEDIA_HOST_ADDRESS}) ) {
    $refhFinishedValues->{BS_MEDIA_HOST_ADDRESS} = "10.1.3.2";
  }

  if ( $refhFinishedValues->{"InstallMedia"} eq "nfs" ) {
    $refhFinishedValues->{"install_media_type"}  = "nfs:";
    $refhFinishedValues->{"base_path"}           = $refhFinishedValues->{"BS_NFS_BASE_PATH"};
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} = "nfs --server=$refhFinishedValues->{'BS_MEDIA_HOST_ADDRESS'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= " --dir=$refhFinishedValues->{'BS_NFS_BASE_PATH'}";
    #$refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_IMAGE_DIRECTORY'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_MIRROR_DIRECTORY'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'relative_install_image_path'}";
    my $nIndex = 0;
#print "DDD DefineInstallMediaKeys()\n";
#print Dumper(\@{$refhFinishedValues->{'repo_list'}});
    $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} = "";
    foreach my $szRelativeRepoPath ( @{$refhFinishedValues->{'repo_list'}} ) {
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "repo --name=local${nIndex} --baseurl=nfs:";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "$refhFinishedValues->{'BS_MEDIA_HOST_ADDRESS'}";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= ":$refhFinishedValues->{'BS_NFS_BASE_PATH'}";
      # TODO C This needs to be fixed, the path only works when I use mirrors. the repo_list should probably include the 'mirrors' dir.
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_MIRROR_DIRECTORY'}";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "/$szRelativeRepoPath\n";
      $nIndex++;
    }
    $refhFinishedValues->{'relative_ks_cfg_path_and_name'}   .= "_nfs";
    $szKickstartFile = $refhFinishedValues->{"BS_NFS_BASE_PATH"} . $refhFinishedValues->{"relative_ks_cfg_path_and_name"};
  } elsif ( $refhFinishedValues->{"InstallMedia"} eq "http" ) {
    $refhFinishedValues->{"install_media_type"}  = "http://";
    $refhFinishedValues->{"base_path"}           = ":$refhFinishedValues->{'BS_HTTP_PORT_NUMBER'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} = "url --url=http://";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "$refhFinishedValues->{'BS_MEDIA_HOST_ADDRESS'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= ":$refhFinishedValues->{'BS_HTTP_PORT_NUMBER'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_IMAGE_DIRECTORY'}";
    $refhFinishedValues->{'KS_INSTALL_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'relative_install_image_path'}";
    #if ( exists($refhFinishedValues->{'relative_extra_repo_path'}) ) {
    my $nIndex = 0;
    $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} = "";
    foreach my $szRelativeRepoPath ( @{$refhFinishedValues->{'repo_list'}} ) {
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "repo --name=local${nIndex} --baseurl=http://";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "$refhFinishedValues->{'BS_MEDIA_HOST_ADDRESS'}";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= ":$refhFinishedValues->{'BS_HTTP_PORT_NUMBER'}";
      #$refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_EXTRA_REPO_DIRECTORY'}";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "/$refhFinishedValues->{'BS_RELATIVE_MIRROR_DIRECTORY'}";
      $refhFinishedValues->{'KS_REPO_SOURCE_SELECTION'} .= "/$szRelativeRepoPath\n";
      $nIndex++;
    }

    $refhFinishedValues->{"relative_ks_cfg_path_and_name"}   .= "_http";
    # Here we are prepending the BS_RELATIVE_CONFIG_DIRECTORY.
    $szKickstartFile = $refhFinishedValues->{"BS_NFS_BASE_PATH"} . $refhFinishedValues->{"relative_ks_cfg_path_and_name"};
  } else {
    die("!!! Media not supported, unknown: $refhFinishedValues->{'InstallMedia'}");
  }

  return($szKickstartFile);
} # end DefineInstallMediaKeys.


# -----------------------------------------------------------------
# ---------------
sub KscTranslateExternalKsCfgFile {
  my $refhBootConfiguration = shift;
  my $szKickstartFile = shift;

  my %hBootConfiguration = %$refhBootConfiguration;

  DefineInstallMediaKeys(\%hBootConfiguration);
  my %hReplacementPatterns;


  $hReplacementPatterns{'^bootloader'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^clearpart'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^firewall'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^ignoredisk'} = "# Dropped.\n";
  $hReplacementPatterns{'^install'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^keyboard'} = "keyboard dk\n";
#  $hReplacementPatterns{'^lang'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^network'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^part'} = "# dropped, replaced by a very simple allocation.\n";
  $hReplacementPatterns{'^rootpw'} = "rootpw --iscrypted \$1\$CMwKB6SZ\$A/bIPra.oQMIeCFTPyWeT0\n";
  $hReplacementPatterns{'^selinux'} = "# replaced by a default.\n";
  $hReplacementPatterns{'^timezone'} = "timezone Europe/Amsterdam --isUtc\n";
  $hReplacementPatterns{'^zerombr'} = "# replaced by a default.\n";

  open(KS_OUT, ">$szKickstartFile") || die("!!! Unable to open file for writing: $szKickstartFile: $!");
  open(EXTERNAL_KS, "<$hBootConfiguration{'--externalcfg'}") || die("!!! Unable to open file for read - $hBootConfiguration{'--externalcfg'}: $!");
  print KS_OUT "# Install OS instead of upgrade\n";
  print KS_OUT "install\n";
  print KS_OUT "# Firewall configuration\n";
  print KS_OUT "firewall --disabled\n";
  print KS_OUT "# SELinux configuration\n";
  print KS_OUT "selinux --disabled\n";
  print KS_OUT "# Use text mode install\n";
  print KS_OUT "text\n";
  print KS_OUT "# Do not configure the X Window System\n";
  print KS_OUT "skipx\n";
  print KS_OUT "\n";
  print KS_OUT "# System bootloader configuration\n";
  print KS_OUT "bootloader --location=mbr\n";
  print KS_OUT "# Clear the Master Boot Record\n";
  print KS_OUT "zerombr\n";
  print KS_OUT "# Partition clearing information\n";
  print KS_OUT "clearpart --all --initlabel\n";
  print KS_OUT "# Disk partitioning information\n";
  print KS_OUT "part swap --fstype=\"swap\" --size=1024\n";
  print KS_OUT "part / --fstype=\"ext4\" --grow --size=1\n";
  print KS_OUT "network  --bootproto=dhcp\n";
  print KS_OUT "\n";
  print KS_OUT "\n";

  my $nInsideSection = 0;
  while (<EXTERNAL_KS>) {
    foreach my $szPattern ( keys %hReplacementPatterns) {
      if ( /$szPattern/ ) {
        $_ = $hReplacementPatterns{$szPattern};
      }
    } # end foreach.
    if ( /^cdrom/ ) {
      $_ = $hBootConfiguration{'KS_INSTALL_SOURCE_SELECTION'} . "\n";
      if ( exists($hBootConfiguration{'KS_REPO_SOURCE_SELECTION'}) ) {
        $_ .= $hBootConfiguration{'KS_REPO_SOURCE_SELECTION'} . "\n";
      }
    } # end if cdrom.

    if ( /^%end/ ) {
      $nInsideSection = 0;
    } elsif ( /^%/ ) {
      if ( $nInsideSection == 1 ) {
        $_ = "%end\n" . $_;
      } else {
        $nInsideSection = 1;
      }
    }

    print KS_OUT $_;
  } # end while.
  close(EXTERNAL_KS);
  close(KS_OUT);
} # end KscTekcTranslateExternalKsCfgFile.



# This ends the perl module/package definition.
1;
