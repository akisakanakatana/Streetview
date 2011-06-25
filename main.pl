#!/usr/local/bin/perl

use strict;
use Carp;
use CGI;
use Data::Dumper;
use IO::File;

use Panorama;
use IsIn;

# http://cbk0.googleapis.com/cbk?output=json&oe=utf-8&cb_client=apiv3&v=4&panoid=Hv0Fu-S4oaTv8MKZ9VUBPg&callback=_xdc_._v66h5&token=93802
# http://cbk0.googleapis.com/cbk?output=json&oe=utf-8&cb_client=apiv3&v=4&ll=38.263127%2C140.851803&radius=50&callback=_xdc_._6mw12v&token=47294
# (38.263127, 140.851803) Sendai-Kawauchi
# (38.238479, 140.96931700000005) SendaiHigashi-Onuma

=pod
Onuma
perl main.pl lat=38.238479 lng=140.969317 step=1000 shape=38.2503-141.0,38.241-140.95212,38.237-140.952,38.22-140.974,38.22-150.0,38.238479-150.0
Sanbonduka
perl main.pl lat=38.215393 lng=140.950919 step=1000 shape=38.22-40.9483,38.21-140.946,38.2093-140.95643,38.2093-150.0,38.22-150.0
Idohama
perl main.pl lat=38.2 lng=140.9495 step=2000 shape=38.204-140.944236,38.191-140.939,38.18193-140.946293,38.18-150.0,38.204-150.0
Yuriage Kita
perl main.pl lat=38.180534 lng=140.944905 step=2000 shape=38.183126-140.947488,38.1867-140.9357,38.1686-140.91603,38.158206-140.92236,38.16855-140.9383,38.183126-140.947
Yuriage Nishi
perl main.pl lat= step=2000 shape=38.183126-140.947,38.16855-140.9383,38.1659-140.9383,38.1659-140.9482,38.173505-140.95151,38.17645-140.95474,38.183126-140.95474
Yuriage Higashi
perl main.pl lat= step=3000 shape=38.1659-140.9482,38.173505-140.95151,38.17645-140.95474,38.17645-150.0,38.1657-150.0

=cut
38.168555, 140.93827)
# make point list
sub loop {
  my ($pano, $start, $radius, $count, $shape) = @_;
  
  # get the first paranoram by id
  $start = new LatLng ($start);
  my $res = $pano->getByLocation ($start, $radius);
  
  die "Start is out of range.\n" unless IsIn::isin ([$start->lat(), $start->lng()], @$shape);
  my %visited = ($res->{Location}->{panoId} => $res);
  my @wait = map { $_->{panoId} } @{$res->{Links}};
  
  # walk among path
  while ($count-- != 0) {
    my $nextid = shift @wait or last;

    my $res = $pano->getById ($nextid);
    my $loc = $res->{Location};

    printf "%d: It is %s (%f,%f)\n", $count, $nextid, $loc->{lat}, $loc->{lng};

    if (IsIn::isin ([$loc->{lat}, $loc->{lng}], @$shape)) {
      $visited{$nextid} = $res;

      # append next path
      map {
        my $pid = $_->{panoId};
        push @wait, $pid if not exists $visited{$pid};
      } @{$res->{Links}};
    } else {
      print "$nextid is out of range.\n";
    }
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
sub information {
  my ($fail, $file, $p) = @_;
  my $loc = $p->{Location};
  return sprintf "%s:%s(%f,%f)>%s",
    $fail ? "fail" : "succ", $loc->{panoId}, $loc->{lat}, $loc->{lng}, $file;
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
                    shape=<shape>
                    [rad=<radius>]
shape: <lat_0>-<lng_0>,<lat_1>-<lng_1>,...,<lat_n>-<lng_n>
           where <lat_i> and <lng_i> (i >= 2) are float value.
USAGE
    exit;
}

sub main {
  my $cgi = new CGI;
  my $latitude  = $cgi->param('lat')  or die usage();
  my $longitude = $cgi->param('lng')  or die usage();
  my $steps     = $cgi->param('step') or die usage();
  my $radius    = $cgi->param('rad') || 50;
  my @shape    = map { [split /-/] } split /,/, $cgi->param('shape') or die usage();

  my $latlng = new LatLng ($latitude, $longitude);
  my $pano = new Pano;
  
  print "Walking...\n";
  my %track = loop ($pano, $latlng, $radius, $steps, \@shape);
  my @ids = keys %track;

  my @info;
  foreach my $id (@ids) {
    foreach my $zoom ((1..3)) {
      foreach my $img ($pano->getAllImage ($zoom, $id)) {
        print "Downloading image: ", $img->{src}, "\n";
        
        my $to = panoToFilename ($id, $img->{x}, $img->{y}, $img->{zoom});

        # if $to is already downloaded then skip to download.
        if (!-f $to) {
          eval { $pano->copy ($img->{src}, $to); };
          push @info, information ($@, $to, $track{$id});
          sleep 1;
        }
      }
    }
  }
  print "Download finished.\n";
  
  # save panorama data
  while (my ($k, $v) = each %track) {
    print "Saving data: $k\n";
    savePano ($k, $v);
  }

  print "Saving finished.\n";
  
  # save information
  my $o = new IO::File ('download-info.dat', 'a') or die "$!: main\n";
  my $time = localtime;
  $o->print ("$time\n");
  map { $o->print ("$_\n") } @info;
  
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

