#!/usr/bin/perl -w
use strict;

# This script 'populates' the puppet webstorage.
#   wget's the githup .zip files for the puppet modules.

my $f_szStorageDir = "/var/webstorage/puppet";


sub UpdateArchive {
  my $szSource = shift;
  my $szZipName = shift;
  my $szLinkName = shift;

  if ( ! -f "$f_szStorageDir/$szZipName" ) {
    print "III Getting $szZipName\n";
    `wget -O $f_szStorageDir/$szZipName $szSource`;
    print "EEE Failed to get $szSource\n" unless($? == 0);
    # if we want to create a symlink.
    if ( defined($szLinkName) ) {
      if ( -e "$f_szStorageDir/$szLinkName" ) {
        unlink("$f_szStorageDir/$szLinkName");
      }
      print "III Symlink ln -s $f_szStorageDir/$szZipName $f_szStorageDir/$szLinkName\n";
      `ln -s $f_szStorageDir/$szZipName $f_szStorageDir/$szLinkName`;
      print "EEE Failed to create symlink: $f_szStorageDir/$szLinkName\n" unless($? == 0);
    }
  } else {
    print "III $szZipName exists, not updated.\n";
  }
}

UpdateArchive("https://github.com/henk52/henk52-hieraconf/archive/master.zip", "henk52-hieraconf.zip");
UpdateArchive("https://github.com/henk52/henk52-vagrant_client/archive/master.zip", "henk52-vagrant_client.zip");
UpdateArchive("https://forgeapi.puppetlabs.com/v3/files/puppetlabs-stdlib-4.10.0.tar.gz?_ga=1.215137169.703514436.1444930369", "puppetlabs-stdlib-4.10.0.tar.gz", "puppetlabs-stdlib.tar.gz");
UpdateArchive("https://forgeapi.puppetlabs.com/v3/files/puppetlabs-apache-1.7.1.tar.gz?_ga=1.211439635.703514436.1444930369", "puppetlabs-apache-1.7.1.tar.gz", "puppetlabs-apache.tar.gz");
UpdateArchive("https://forgeapi.puppetlabs.com/v3/files/dwerder-graphite-5.15.0.tar.gz?_ga=1.249403009.703514436.1444930369", "dwerder-graphite-5.15.0.tar.gz", "dwerder-graphite.tar.gz");
UpdateArchive("https://forgeapi.puppetlabs.com/v3/files/puppetlabs-concat-1.2.5.tar.gz?_ga=1.247656449.703514436.1444930369", "puppetlabs-concat-1.2.5.tar.gz", "puppetlabs-concat.tar.gz");
UpdateArchive("https://forgeapi.puppetlabs.com/v3/files/razorsedge-network-3.6.0.tar.gz?_ga=1.25717309.1261433395.1427318039", "razorsedge-network-3.6.0.tar.gz");
