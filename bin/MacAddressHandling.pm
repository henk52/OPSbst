package MacAddressHandling;

# This module allows you to create a Kickstart configuration file.

use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use Text::Template;


$VERSION = 0.1.0;
@ISA = ('Exporter');
# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &ReturnMacDashedFormat
            );

# convert to lower case.
# 

# -----------------------------------------------------------------
# Post conditions:
#  - lower case.
#  - octets seperated by '-'
#  - prepended with '01-'
# Precondition:
#  - Must have 6 octets.
# TODO N support ':' separation.
# ---------------
sub ReturnMacDashedFormat {
  my $szMacAddress = shift;

  die("!!! Please provide the required MAC address.") unless(defined($szMacAddress));

  if ( $szMacAddress =~ /:/ ) {
    $szMacAddress =~ s/:/-/g;
  }
  if ( $szMacAddress =~ /-/ ) {
    die("The Address does not have the expected lenght of 17 bytes.") unless( length($szMacAddress) == 17 );
  } else {
    die("The Address does not have the expected lenght of 12 bytes.") unless( length($szMacAddress) == 12 );
    my @arSingleCharacter = split(//, $szMacAddress);
    $szMacAddress = "$arSingleCharacter[0]$arSingleCharacter[1]-";
    $szMacAddress .= "$arSingleCharacter[2]$arSingleCharacter[3]-";
    $szMacAddress .= "$arSingleCharacter[4]$arSingleCharacter[5]-";
    $szMacAddress .= "$arSingleCharacter[6]$arSingleCharacter[7]-";
    $szMacAddress .= "$arSingleCharacter[8]$arSingleCharacter[9]-";
    $szMacAddress .= "$arSingleCharacter[10]$arSingleCharacter[11]";
  }
  $szMacAddress = lc($szMacAddress);
  $szMacAddress = "01-$szMacAddress";

  return($szMacAddress);
}

# This ends the perl module/package definition.
1;

