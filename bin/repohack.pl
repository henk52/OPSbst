#!/usr/bin/perl -w
use strict;
use FindBin;

BEGIN {
  push( @INC, "$FindBin::RealBin" );    ## Path to local modules
}

use ExecuteAndTrace;

my $f_szTarGzFileName = shift || die("!!! Please provide the tgz file name.");

my $f_szTargetDirectory = "/var/ks/extrarepos/fedora-20-x86_64-20140514";

my $f_szRepoMdFileName  = "repodata/repomd.xml";

my $f_szTreeInfoTemplate = "$FindBin::RealBin/../templates/treeinfo.tmpl";

use Text::Template;

my %hTemplateData;


DieIfExecuteFails("cd $f_szTargetDirectory; tar -zxf $f_szTarGzFileName");
DieIfExecuteFails("cd $f_szTargetDirectory; rm *.rpm");
DieIfExecuteFails("cd $f_szTargetDirectory; mv erepo/*.rpm .");

DieIfExecuteFails("cd $f_szTargetDirectory; createrepo .");

my $szOutput = `cd $f_szTargetDirectory; sha256sum $f_szRepoMdFileName`;
my $szSha256Sum = (split('\s+', $szOutput))[0];

$hTemplateData{'nTimeStamp'} = time();
$hTemplateData{'szRepomdXmlSha256'} = $szSha256Sum;


my $template = Text::Template->new(TYPE => 'FILE', SOURCE => "$f_szTreeInfoTemplate")
        or die "Couldn't construct template: $Text::Template::ERROR";

my $szResult = $template->fill_in(HASH => \%hTemplateData);

my $szTreeInfoFileName = "$f_szTargetDirectory/.treeinfo";
open (TREEINFO, ">$szTreeInfoFileName") || die("!!! could not open to file for write: $szTreeInfoFileName: $!");
print TREEINFO $szResult;
close(TREEINFO);

