#!/usr/local/bin/perl

use strict;
use Carp;
use CGI;
use Data::Dumper;
use IO::File;

use Panorama;

# http://cbk0.googleapis.com/cbk?output=json&oe=utf-8&cb_client=apiv3&v=4&panoid=Hv0Fu-S4oaTv8MKZ9VUBPg&callback=_xdc_._v66h5&token=93802
# http://cbk0.googleapis.com/cbk?output=json&oe=utf-8&cb_client=apiv3&v=4&ll=38.263127%2C140.851803&radius=50&callback=_xdc_._6mw12v&token=47294

sub loop {
  my ($pano, $start, $radius, $count) = @_;
  $start = new LatLng ($start);

  my $res = $pano->getByLocation ($start, $radius);

  my %visited = ($res->{Location}->{panoId} => $res);
  my @wait = map { $_->{panoId} } @{$res->{Links}};
  
  while ($count-- != 0) {
    my $nextid = shift @wait or last;
    my $res = $pano->getById ($nextid);
    $visited{$nextid} = $res;

    map {
      my $pid = $_->{panoId};
      push @wait, $pid if not exists $visited{$pid};
    } @{$res->{Links}};
    
    sleep 1;
  }

  return %visited;
}

sub panoToString {
  my $p = shift;
  local $Data::Dumper::Indent = 0;
  local $Data::Dumper::Purity = 1;
  local $Data::Dumper::Useqq = 1;
  my $out = Dumper ($p);
  $out =~ s/^[^{]+//; # }
  return $out;
}
sub stringToPano {
  my $s = shift;
  my $p = eval $s;
  return $p;
}
sub savePano {
  my ($pid, $p) = @_;
  my $d = panoToString ($p);
  my $o = new IO::File (pidToFilename($pid), 'w') or die "$!: savePano\n";
  $o->print ($d);
}

sub panoToFilename {
  my ($pid, $x, $y, $z) = @_;
  return "/cygdrive/m/Streetview/img/$pid-$x-$y-$z.jpg";
}
sub pidToFilename {
  my $pid = shift;
  return "/cygdrive/m/Streetview/pano/$pid.dat";
}

sub usage {
  print << "USAGE";
Usage: perl main.pl lat=<latitude> lng=<longitude> step=<step>
                    [rad=<radius>]
USAGE
    exit;
}

sub main {
  my $cgi = new CGI;
  my $latitude  = $cgi->param('lat')  or die usage();
  my $longitude = $cgi->param('lng')  or die usage();
  my $steps     = $cgi->param('step') or die usage();
  my $radius    = $cgi->param('rad') || 50;

  my $latlng = new LatLng ($latitude, $longitude);
  my $pano = new Pano;
  
  print "Walking...\n";
  my %track = loop ($pano, $latlng, $radius, $steps);
  my @ids = keys %track;

  foreach my $id (@ids) {
    foreach my $zoom ((1..3)) {
      foreach my $img ($pano->getAllImage ($zoom, $id)) {
        print "Downloading image: ", $img->{src}, "\n";
        my $to = panoToFilename ($id, $img->{x}, $img->{y}, $img->{zoom});
        if (!-f $to) {
          $pano->copy ($img->{src}, $to);
          sleep 1;
        }
      }
    }
  }
  print "Download finished.\n";

  while (my ($k, $v) = each %track) {
    print "Saving data: $k\n";
    savePano ($k, $v);
  }
  print "Saving finished.\n";

}

# test code
sub getTest {
  my $latitude = 38.26151;
  my $longitude = 140.85146;
  my $radius = 50;
  my $steps = 3;
  my $latlng = new LatLng ($latitude, $longitude);

  my $pano = new Pano;
#  print $pano->makeURLById ('PID'), "\n";
#  print $pano->makeURLByLocation ($latlng, $radius), "\n";
  
  my %track = loop ($pano, $latlng, $radius, $steps);
  my @ids = keys %track;

  print "Below IDs are gotten.\n";
  map { print "$_\n" } @ids;

  my @images = map { $pano->getAllImage (3, $_) } @ids;
  print "Below images are gotten.\n";
  map { print $_->{src}, "\n" } @images;

  foreach my $id (@ids) {
    foreach my $zoom ((1..3)) {
      foreach my $img ($pano->getAllImage ($zoom, $id)) {
        print "Downloading image: ", $img->{src}, "\n";
        my $to = panoToFilename ($id, $img->{x}, $img->{y}, $img->{zoom});
        if (!-f $to) {
          $pano->copy ($img->{src}, $to);
          sleep 1;
        }
      }
    }
  }
  print "Download finished.\n";

  while (my ($k, $v) = each %track) {
    print "Saving data: $k\n";
    savePano ($k, $v);
  }
  print "Saving finished.\n";

}
sub saveTest {
  my $pano = new Pano;
  my $res = $pano->sampleResponse;
  $res = Pano::readResponse($res);
  my $out = panoToString ($res);
  print "=== panoToString ===\n";
  print $out;
  print "\n=== stringToPano ===\n";
  print Dumper (stringToPano ($out));
}

# getTest ();
main();

1;

