package XmlDistroConfigFile;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;


use BstShortcuts;
use XmlIf;

$VERSION = 0.3.0;
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
#GetKeyPathsForDistro(
#                      $f_hFinishedValues{"BS_DISTRO_CONFIGURATION_FILE"},
#                      $hPopulatedOptionList{"--distro"},
#                      $hPopulatedOptionList{"--release"},
#                      $hPopulatedOptionList{"--arch"},
#                    );
# Calls GetDistributionNode()
# ---------------
sub GetKeyPathsForDistro {
  my $szConfigFileName = shift;
  my $szDistroName = shift;
  my $szReleaseNumber = shift;
  my $szArchitechture = shift;

  my %hDistroValues;

  $hDistroValues{'BootDistroName'} = $szDistroName;
  $hDistroValues{'Arch'} = $szArchitechture;
  $hDistroValues{'BootDistroId'} = $szReleaseNumber;
  return(GetDistributionNode(undef, \%hDistroValues, $szConfigFileName));
}


# -----------------------------------------------------------------
#  Get the distribution node for the given parms.
#  refhFinishedValues content:
#     BootDistroName: e.g. fedora
#     Arch: e.g. x86_64
#     BootDistroId: e.g. 20
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
    my @arRepoList             = GetDataArrayByTagName($xmlNode, 'repo');
    $hReply{'repo_list'}       = \@arRepoList;
print "DDD GetDistributionNode()\n";
print Dumper(\%hReply);
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
} # end GetReleaseNode.


# -----------------------------------------------------------------
# Create it if it does not exist.
# ---------------
sub UpdateDistroConfigFile {
  my $szFileName = shift;
  my $refHash = shift;

  confess("!!! Missing filename.") unless(defined($szFileName));
  confess("!!! Missing hash.") unless(defined($refHash));

  my %hCombinedHash = %{$refHash};
  print Dumper(\%{$refHash});

  if ( ! -f $szFileName ) {
    open(XML, ">$szFileName") || confess("!!! could not open file for write: $szFileName - $!");
    print XML "<Distributions Version=\"0.1.0\">\n";
    print XML "</Distributions>\n";
    close(XML);
  } 

  # if it already exist, then die, otherwise add it.
  my %hRetrievedHash = GetKeyPathsForDistro($szFileName, $hCombinedHash{'--distro'}, $hCombinedHash{'--release'}, $hCombinedHash{'--arch'});
  if ( exists($hRetrievedHash{'relative_install_image_path'}) ) {
    print Dumper(\%hRetrievedHash);
    confess("EEE The entry already exists");
  } else {
    # Add the entry.
    # TODO V change this to do it through XmlIf, instead of directly.
    # 
    # my $szXmlRoot = LoadXmlTree($szFileName);
    my( $szXmlRoot, $dom ) = LoadXmlStructure($szFileName);
    #my $node = $dom->createElement( "Distro" );
    #$element = $dom->createElement( $nodename );
    my $node = XML::LibXML::Element->new( "Distro" );
    $node->setAttribute( 'Name', "$hCombinedHash{'--distro'}");
    $node->setAttribute( 'Version', "$hCombinedHash{'--release'}");
    $node->setAttribute( 'Architechture', "$hCombinedHash{'--arch'}");

    $node->appendTextChild('relative_boot_kernel_path', "$hCombinedHash{'RelativeBootKernelPath'}");
    $node->appendTextChild('relative_install_image_path', "$hCombinedHash{'RelativeKernelSource'}");

    # Add the list of repos.
    print Dumper(\%{$hCombinedHash{'RepoNameAndRelativePathHash'}});
    foreach my $szRepoName (keys %{$hCombinedHash{'RepoNameAndRelativePathHash'}} ) {
      print "DDD $szRepoName : $hCombinedHash{'RepoNameAndRelativePathHash'}{$szRepoName}\n";
      # TODO V add a repo name.
      $node->appendTextChild('repo', "$hCombinedHash{'RepoNameAndRelativePathHash'}{$szRepoName}");
    }
    $szXmlRoot->addChild($node);


    print $dom->toString(2);
    
    my $format = 1; # will add ignorable white spaces, so the nodes content is easier to read. 
    # See: http://search.cpan.org/~shlomif/XML-LibXML-2.0123/lib/XML/LibXML/Document.pod
    $dom->toFile($szFileName, $format);
    
  }
  
} #end UpdateDistroConfigFile


# This ends the perl module/package definition.
1;
