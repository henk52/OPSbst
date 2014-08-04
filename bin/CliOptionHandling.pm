# The package name must be the same as the filename, except for the '.pm' suffix.
package CliOptionHandling;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

$VERSION = 0.2.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &AddValidOption
                &GetNextCliArgument
                &HandleCommandLine
            );

# -----------------------------------------------------------------
#  @arValidCommandList: Commands this option is valid for.
# ---------------
sub AddValidOption {
  my $HashAsReference = shift;
  my $szOptionName = shift;

  # TODO N Figure out, why I have to do this.
  my $refarValidCommandList = shift;

  my $nHasParameter = shift;
  my $szDescription = shift;
  my $szOptionalDefaultValue = shift;

  my %hValidOption = %$HashAsReference;

  my $nReturnValue=0;

  if ( ! exists $hValidOption{$szOptionName} ) {
    # For the valued to be actually changed I need to use the reference to the hash, not the deref.

    $HashAsReference->{$szOptionName}{"ValidCommandList"} = $refarValidCommandList;

    $HashAsReference->{$szOptionName}{"HasParameter"}     = $nHasParameter;
    $HashAsReference->{$szOptionName}{"Description"}      = $szDescription;
    if ( defined($szOptionalDefaultValue) ) {
      $HashAsReference->{$szOptionName}{"Default"}        = $szOptionalDefaultValue;
    }
  } else {
    $nReturnValue = -1;
  }

  #print "===\n";
  #print Dumper(%hValidOption);
  #print "===\n";

  return($nReturnValue)
} # end AddValidOption.


# -----------------------------------------------------------------
# ---------------
sub GetNextCliArgument {
  my $szErrorMsg = shift || "!!! attempted to read more parameters than there is available.";

  my $szReturnValue = undef;

  if ( $#ARGV > -1 ) {
    $szReturnValue = shift @ARGV;
  } else {
    die($szErrorMsg);
  }
} # end GetNextCliArgument.


# -----------------------------------------------------------------
# Runs throught the arguments left on the CLI and assign them to
# the expected options.
#
# nExpectToLeaveNumberOfParmsAtEnd:: How many arguments are expected to be
# left of the CLI when this function is done. Default to 0.
#
# Return a hash with the options found.
# If the option is a switch(having not parameters) a default value is used as value.
#
# This function will die if an unrecognized option is encountered.
# ---------------
sub HandleCommandLine {
  my $refhValidOption = shift;
  my $nExpectToLeaveNumberOfParmsAtEnd = shift || 0;

  # >>> Verify the preconditions.
  if ( ! defined($refhValidOption) ) {
    die("!!! You must provide a hash of valid options as the first parameter: e.g. HandleCommandLine(\%hValidOptions);");
  }

  if ( (ref($refhValidOption) ne "HASH") ) {
    die("!!! First parameter must be a reference to a hash. Found: " . ref($refhValidOption));
  }

  my %hValidOption = %$refhValidOption;

  if (!keys %hValidOption) {
    die("!!! The ValidOption hash is empty, please populate it.");
  }

  # TODO V Precondition that $nExpectToLeaveNumberOfParmsAtEnd is >= 0.
  # <<< done preconditions.


  my %hProvidedParameters;

  if ( $#ARGV == -1 ) {
    die("!!! No command line parameters, where parameters where expected.");
  }

  while ( $#ARGV >= $nExpectToLeaveNumberOfParmsAtEnd ) {
    my $szOptionName = GetNextCliArgument();

    if ( exists $hValidOption{$szOptionName} ) {
      if ( exists $hValidOption{$szOptionName}{"HasParameter"} ) {
        $hProvidedParameters{$szOptionName} = GetNextCliArgument()
      } else {
        $hProvidedParameters{$szOptionName} = "A_SWITCH";
      }
    } else {
      die("!!! invalid option name encountered, please do not use: $szOptionName");
    }
  } # end while.

  return(%hProvidedParameters);
} #end HandleCommandLine.


# This ends the perl module/package definition.
1;
