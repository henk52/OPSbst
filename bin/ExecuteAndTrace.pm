package ExecuteAndTrace;
use strict;       # Be strict on the syntax and semantics, var must be defined prior to use.
use vars qw(@ISA @EXPORT $VERSION);
use Exporter;
use Carp;
use Data::Dumper;

use YAML::XS qw/LoadFile Dump/;


$VERSION = 0.1.0;
@ISA = ('Exporter');

# List the functions and var's that must be available.
# If you want to create a global var, create it as 'our'
@EXPORT = qw(
                &DieIfExecuteFails
            );


# -----------------------------------------------------------------
# ---------------
sub DieIfExecuteFails {
  my $szCmd = shift;

  # TODO V die on empty command.

  my @arOutput = `$szCmd`;
  if ( $? != 0 ) {
    confess("!!! operaiont failed: @arOutput");
  }
} # end DieIfExecuteFails


# This ends the perl module/package definition.
1;

