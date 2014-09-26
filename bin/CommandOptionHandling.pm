package CommandOptionHandling;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

$VERSION = 0.1.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
               DieOnInvalidOptionsForCommand
               DieOnSemanticErrorsOfOptionsForCommand
            );

# -----------------------------------------------------------------
# ---------------



# -----------------------------------------------------------------
# This functions assumes that only valid options are in the hProvidedOptions hash.
# ---------------
sub DieOnInvalidOptionsForCommand {
  my $szCommand =shift;
  my $refhValidOption = shift;
  my $refhProvidedOptions = shift;

  my %hValidOption = %$refhValidOption;
  my %hProvidedOptions = %$refhProvidedOptions;

  #print Dumper(%hValidOption);
  #print Dumper(%hProvidedOptions);

  foreach my $szOptionName (keys %hProvidedOptions) {
    if ( $szOptionName ne "Command" ) {
      my %hValidCommandDirectory = map { $_ => 1 } @{$hValidOption{$szOptionName}{"ValidCommandList"}};
      # print Dumper(%hValidCommandDirectory);

      if( ! exists($hValidCommandDirectory{$szCommand}) ) { 
        confess("!!! Option name '${szOptionName}' not valid for command '${szCommand}'.");
      }
    } 
  }
} # end DieOnInvalidOptionsForCommand.


# -----------------------------------------------------------------
#  I think I need to update the missing options
#  Go through the list of all options that are possible for szCommand.
#  If there a required parms that hasn't been provided, then attempt
#    to get the information from other configuration files.
#  Verfiy that only one of an exclusive set of options are provided.
# ---------------
sub DieOnSemanticErrorsOfOptionsForCommand {
  my $szCommand = shift;
  my $refhValidOption = shift;
  my $refhProvidedOptions = shift;
  my $refhOptionInteractionForCommand = shift;

  my %hValidOption = %$refhValidOption;
  my %hProvidedOptions = %$refhProvidedOptions;
  my %hOptionInteractionForCommand = %$refhOptionInteractionForCommand;

#print "DDD " . $hOptionInteractionForCommand{$szCommand}{"OptionList"} . "\n";
#print Dumper($hOptionInteractionForCommand{$szCommand}{"OptionList"});


  foreach my $szOptionName (keys $hOptionInteractionForCommand{$szCommand}{"OptionList"} ) { 
#   print "DDD OptionName: $szOptionName for Command: $szCommand\n";
#   print Dumper($hOptionInteractionForCommand{$szCommand}{"OptionList"}{$szOptionName});

    # If the options is required, and not yet set, then set it if possible.
#    if ( IsInArray("required", @{$hOptionInteractionForCommand{$szCommand}{"OptionList"}{szOptionName}}) ) {
    if ( $hOptionInteractionForCommand{$szCommand}{"OptionList"}{$szOptionName} eq "required" ) {

      # If the option is required then try to get value somewhere else.
      if ( ! exists($hProvidedOptions{$szOptionName}) ) {
        # Start looking for the values somewhere else.
        # see if there is a default definition.
        if ( exists($hValidOption{$szOptionName}{"Default"}) ) {
          $hProvidedOptions{$szOptionName} = $hValidOption{$szOptionName}{"Default"};
          #DebugAndExit.Trace(7, "DDD using default value for #{szOptionName} = #{hProvidedOptions[szOptionName]}")
        } else {
          confess("!!! The required option is not defined: ${szOptionName}");
        } # end
      } #end

    # Special handling is needed for OneOf options. e.g. either --distro or --combo, both are not allowed at the same time.

#    } elsif  ( IsInArray("OneOf", @{$hOptionInteractionForCommand{$szCommand}{"OptionList"}{$szOptionName}}) ) {
    } elsif  ( $hOptionInteractionForCommand{$szCommand}{"OptionList"}{$szOptionName} eq "OneOf" ) {
      # Fail if more than one of the options in the oneof list is in the options list provide via the CLI.
      foreach my $szExcludeOption (@{$hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"${szOptionName}OneOf"}{"exclude"}}) {
        if ( exists($hProvidedOptions{$szOptionName}) && exists($hProvidedOptions{$szExcludeOption}) ) {
          die("!!! ${szOptionName} and ${szExcludeOption} are mutually exclusive.");
        }
      } # end foreach.
      # Fail if this was a required option and none was defined. (is it possible to have a defailt oneof? )
      if ( $hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"${szOptionName}OneOf"}{"necessity"} eq "required" ) {
        if ( ! exists($hProvidedOptions{$szOptionName}) ) {
          my $bOneOfTheMutuallyExcliveOptionFound = 0;
          foreach my $szExcludeOption (@{$hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"${szOptionName}OneOf"}{"exclude"}}) {
#            print "DDD OptionName: $szOptionName ExcludeOption: $szExcludeOption\n";
            if ( exists($hProvidedOptions{$szExcludeOption}) ) {
              $bOneOfTheMutuallyExcliveOptionFound = 1;
            }
          } # end foreach.
          if ( ! $bOneOfTheMutuallyExcliveOptionFound ) {
            my $szOtherOptionsList = join(", ", @{$hOptionInteractionForCommand{$szCommand}{"OptionInfo"}{"${szOptionName}OneOf"}{"exclude"}}); # .join(",")
            confess("!!! one of the mutually exclusive options must be specified: ${szOptionName}, ${szOtherOptionsList}")
          }
        }
      }
    } else {
      confess("!!! Internal Error, the definition is not know at programming time, command=$szCommand, option name=$szOptionName : " . $hOptionInteractionForCommand{$szCommand}{"OptionList"}{$szOptionName});
    }
  } # end foreach.

  return(%hProvidedOptions);
} # end DieOnSemanticErrorsOfOptionsForCommand.



sub IsInArray {
  my $szStringToSearch = shift;
  my @arArrayToSearch = shift;

  my $nFound = 0;

  my %hDirectory = map { $_ => 1 } @arArrayToSearch;

  if( exists($hDirectory{$szStringToSearch}) ) {
    $nFound = 1;
  }

  return($nFound);
} # end IsInArray

# This ends the perl module/package definition.
1;

