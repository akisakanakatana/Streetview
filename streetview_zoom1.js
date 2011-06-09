
function gcd (a, b) {
    function f (x, y) {
        var m = x % y;
        return m == 0 ? y : f (y, m);
    }
    return a < b ? f (b, a) : f (a, b);
}

function tiles (w, h, tw, th) {
//  w = 3328, h = 1664, tw = 512, th = 512 => 13
    return h / gcd(gcd(w,tw),gcd(h,th));
}

$(function() {

    // setting
    var around = 50; // m
    var latlng = new google.maps.LatLng(38.26151, 140.85146);
    var mapOptions = {
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        zoom: 12
    };
    var panoramaOptions = {
        addressControl: false,
        linksControl: false,
        enableCloseButton: false,
        navigationControl: false
    };

    // jquery elements
    var $canvas = $('#map_canvas');
    var $pano = $('#pano');
    var $slider = $('#heading');
    var $param = function (name, str) {
        $('#param_'+name).text(str);
    };

    // google map elements
    var map = new google.maps.Map($canvas.get(0), mapOptions);
    var sv = new google.maps.StreetViewService();

    // memory variables
    var heading = 0;
    var panorama = [];
    var pid = '';

    test_panorama (sv, latlng, around, function (latlng, panoid) {
        panorama = init_panorama ($pano, panoid, panoramaOptions);
        $param('center', latlng.toString());
        pid = panoid;
    });

    //// Events ////
    // jump location
    google.maps.event.addListener(map, 'click', function(event) {
        // Bug ?
        // latlng = new google.maps.LatLng(event.latLng);
        latlng = event.latLng;
        latlng = new google.maps.LatLng(latlng.lat(), latlng.lng());
        test_panorama (sv, latlng, around, function (latlng, panoid) {
            move_panorama (panorama, panoid, heading);
            map.panTo(latlng);
            $param('center', latlng.toString());
            pid = panoid;
        });
    });

    // rotation bar
    // jquery does not support input[type=range].change
    $slider.get(0).addEventListener('change', function() {
        heading = $slider.get(0).value;
        move_panorama (panorama, pid, heading);
        $param('heading', heading);
    }, true);
});

function test_panorama (sv, l, around, f) {
    sv.getPanoramaByLocation (l, around, function (data, status) {
        if (status != google.maps.StreetViewStatus.OK) {
            alert ('Street view not supported.');
            return false;
        }
//        var d = data.tiles;
//         var width = d.worldSize.width;
//         var height = d.worldSize.height;
//         var twidth = d.tileSize.width;
//         var theight = d.tileSize.height;
//         var tile = tiles (width, height, twidth, theight);
        var panoid = data.location.pano;
        var latlng = data.location.latLng;
//        var heading = data.centerHeading;
        f (latlng, panoid);
        return true;
    });
}

function move_panorama (panorama, panoid, heading) {
    var opt_itr = pano_itr(heading, 45);
    $.each(panorama, function(i, cell) {
        cell.setPano(panoid);
        cell.setPov(opt_itr());
    });
}

function init_panorama ($pano, panoid, option) {
    $pano.empty(); // reset panorama box
//    alert('init_panorama: tile='+tile+', panoid='+panoid);
    var opt_itr = pano_itr(0, 45);
    var width = Math.floor(parseInt($pano.width()) / 4) + 'px';
    var panorama = [];
    for (var j = 0; j < 4; j++) {
        var $li = $('<li/>').width(width);
        $pano.append($li);
        var cell = new google.maps.StreetViewPanorama($li.get(0), option);
        cell.setPano(panoid);
        cell.setPov(opt_itr());
        cell.setVisible(true);
        panorama.push(cell);
    }
    return panorama;

        // Disable streetview control
//       var donothing = function() {};
//       google.maps.event.addListener(p, 'pano_changed', donothing);
//       google.maps.event.addListener(p, 'links_changed', donothing);
//       google.maps.event.addListener(p, 'position_changed', donothing);
//       google.maps.event.addListener(p, 'visible_changed', donothing);
}

function pano_itr (heading, pitch) {
    var h = 0;
    return function() {
        if (h == 4) h = 0;
        return {
            pitch: 0,
            heading: heading - 180 + 90 * ((h++) + 0.5),
            zoom: 1
        };
    };
}