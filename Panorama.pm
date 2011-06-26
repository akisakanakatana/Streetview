
###################################################
# class Pano {
#     version = '2011-06-11'
#
# }
# 
###################################################

sub cross {
  my ($f, $z, $h, @t) = @_;
  defined $h ?
    map { my $a = $_;
          map { $f->($a, $_) } cross ($f, $z, @t) } @$h
    : $z;
}
sub cross_product {
  cross (sub { [shift, @{+shift}] }, [], @_);
}

package LatLng;
sub new {
  my $self = shift;
  if ('LatLng' eq ref $_[0]) {
    return shift;
  } else {
    @_ == 2 or die "InvalidArguments: LatLng::new\n";
    bless {
      latitude => shift,
      longitude => shift,
    }, $self;
  }
}
sub lat {
  my $self = shift;
  return $self->{latitude};
}
sub lng {
  my $self = shift;
  return $self->{longitude};
}

package Pano;

use strict;
use LWP::UserAgent;
use JSON qw/to_json from_json/;

sub new {
  my $self = shift;
  my %p = @_;
  my $servers  = $p{servers}  || 3;
  my $callback = $p{callback} || 'response';
  my $token    = $p{token}    || 0;
  my $addr     = $p{addr}     || "http://cbk%d.googleapis.com/cbk";
  my $query    = $p{query}    || ();
  my $agent    = $p{ua}       || 'xaxxi.net';

  my $ua = new LWP::UserAgent;
  $ua->agent ("$agent ".$ua->agent);

  $query = {
    oe        => 'utf-8',
    cb_client => 'apiv3',
    v         => '4',
    callback  => $callback,
    token     => $token,
    $query
  };
  bless {
    servers => $servers,
    addr    => $addr,
    query   => $query,
    ua      => $ua
  }, $self;
}

## URL generator
my $last_server = 0;
sub getAddress {
  my $self = shift;
  $last_server = ($last_server + 1) % $self->{servers};
  return sprintf $self->{addr}, $last_server;
}
sub makeQuery {
  my ($self, %q) = @_;
  %q = (%{$self->{query}}, %q);
  my $res = '';
  while (my ($k, $v) = each %q) {
    $res .= "$k=$v&";
  }
  return $res;
}
sub makeURL {
  my ($self, %q) = @_;
  return $self->getAddress() . "?" . $self->makeQuery(%q);
}

sub makeURLById {
  @_ == 2 or die "InvalidArguments: makeURLById\n";
  my ($self, $pid) = @_;
  return $self->makeURL (
    panoid => $pid, output => 'json');
}
sub makeURLByLocation {
  @_ == 3 or die "InvalidArguments: makeURLByLocation\n";
  my $self = shift;
  my $latlng = new LatLng (shift);
  my $radius = shift;
  return $self->makeURL (
    ll => $latlng->lat() . "%2C" . $latlng->lng(), radius => $radius, output => 'json');
}
sub makeImageURL {
 @_ == 5 or die "InvalidArguments: makeImageURL\n";
 my ($self, $pid, $x, $y, $z) = @_;
 return $self->makeURL (
   panoid => $pid, zoom => $z, x => $x, y => $y, fover => 2, onerr => 3, output => 'tile');
}

## Wrapped API
sub jsonById {
  @_ == 2 or die "InvalidArguments: getByLocation\n";
  my ($self, $pid) = @_;
  my $url = $self->makeURLById ($pid);
  my $res = $self->request ($url);
  return $res;
}
sub jsonByLocation {
  @_ == 3 or die "InvalidArguments: getByLocation\n";
  my ($self, $latlng, $radius) = @_;
  my $url = $self->makeURLByLocation ($latlng, $radius);
  my $res = $self->request ($url);
  return $res;
}
sub getById {
  @_ == 2 or die "InvalidArguments: getByLocation\n";
  my ($self, $pid) = @_;
  my $res = jsonById ($self, $pid);
  $res = readResponse ($res);
  return $res;
}
sub getByLocation {
  @_ == 3 or die "InvalidArguments: getByLocation\n";
  my ($self, $latlng, $radius) = @_;
  my $res = jsonByLocation ($self, $latlng, $radius);
  $res = readResponse ($res);
  return $res;
}
sub getAllImage {
  @_ == 3 or die "InvalidArguments: getAllImage\n";
  my ($self, $zoom, $pid) = @_;
  my ($mx, $my) = $zoom == 1 ? (1, 0) : # 2
                  $zoom == 2 ? (3, 1) : # 8
                  $zoom == 3 ? (6, 3) : # 28
                  die "Zoom paramaeter must be in (1,2,3): getAllImage\n";
  return
    map { { x => $_->[0], y => $_->[1], zoom => $zoom,
            src => $self->makeImageURL ($pid, $_->[0], $_->[1], $zoom) } }
      ::cross_product ([0 .. $mx], [0 .. $my]);
}

## WWW  
sub request {
  @_ == 2 or die "InvalidArguments: request\n";
  my ($self, $url) = @_;
  my $rq = new HTTP::Request GET => $url;
  my $re = $self->{ua}->request ($rq);
  $re->is_success or die $re->message. ": request";
  return $re->content;
}
sub copy {
  @_ == 3 or die "invalidArgumnts: copy\n";
  my ($self, $url, $to) = @_;
  my $rq = new HTTP::Request GET => $url;
  my $re = $self->{ua}->request ($rq, $to);
  $re->is_success or die $re->message. ": request";
  return 1;
}
sub readResponse {
  @_ == 1 or die "InvalidArguments: readResponse\n";
  my $re = shift;
  $re =~ /({.+})/s or die "FailedToParse: readResponse\n";
  $re = $1;
  $re = from_json($re);
  return $re;
}

sub sampleResponse {
  return << "JSONDATA";
_xdc_._v66h5 && _xdc_._v66h5({
"Data":{"image_width":"3328",
        "image_height":"1664",
        "tile_width":"512",
        "tile_height":"512",
        "copyright":"c 2011 Google"},
"Projection":{"projection_type":"spherical",
              "pano_yaw_deg":"80.33",
              "tilt_yaw_deg":"-179.3",
              "tilt_pitch_deg":"1.53"},
"Location":{"panoId":"Hv0Fu-S4oaTv8MKZ9VUBPg",
            "zoomLevels":"3",
            "lat":"38.262936",
            "lng":"140.851777",
            "original_lat":"38.262994",
            "original_lng":"140.851761",
            "description":"国道48号線",
            "region":"",
            "country":"日本"},
"Links":[{"yawDeg":"79.82",
          "panoId":"YY6Mf6hK2DeV08OPMXRhug",
          "road_argb":"0x80fffa73",
          "description":"国道48号線",
          "scene":"0"},
         {"yawDeg":"258.28",
          "panoId":"v_nlqVjL47yWJj_JIE2XcA",
          "road_argb":"0x80fffa73",
          "description":"国道48号線",
          "scene":"0"}]})
JSONDATA
}

1;

__END__


