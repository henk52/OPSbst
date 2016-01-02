#!/usr/bin/perl -w
use strict;

# This script 'populates' the puppet webstorage.
#   wget's the githup .zip files for the puppet modules.

my $f_szStorageDir = "/var/webstorage/puppet";


sub UpdateArchive {
  my $szSource = shift;
  my $szZipName = shift;

  if ( ! -f "$f_szStorageDir/$szZipName" ) {
    print "III Getting $szZipName\n";
    `wget -O $f_szStorageDir/$szZipName $szSource`;
    print "EEE Failed to get $szSource\n" unless($? == 0);
  } else {
    print "III $szZipName exists, not updated.\n";
  }
}

UpdateArchive("https://github.com/henk52/henk52-hieraconf/archive/master.zip", "henk52-hieraconf.zip");
UpdateArchive("https://github.com/henk52/henk52-vagrant_client/archive/master.zip", "henk52-vagrant_client.zip");

