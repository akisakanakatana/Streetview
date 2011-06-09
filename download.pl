#!/usr/local/bin/perl

use strict;
use IO::File;
use CGI;
use LWP::Simple;

my $cgi = new CGI;
my $file = $cgi->param('f');
my $format = $cgi->param('n') || 'pano%d%d%d.jpg';

if (!$file) {
  print "usage: perl download f=filename\n";
}

print "Get from $file\n";

my $in = IO::File->new($file, 'r') or die $!;
while (!$in->eof) {
  my $f = $in->getline;
  chomp $f;
  
  if ($f =~ /^\s*$/) {
    print "Skip line bacause filename is empty\n";
    next;
  }

  $f =~ /x=(\d)/ or die "Not found x.\n";
  my $x = $1;
  $f =~ /y=(\d)/ or die "Not found y.\n";
  my $y = $1;
  $f =~ /zoom=(\d)/ or die "Not found zoom.\n";
  my $z = $1;

  my $to = sprintf $format, $x, $y, $z;
  print "Downloading $f to $to\n";

  getstore ($f, $to);
  
}

print "Download complete.";
  
exit;

