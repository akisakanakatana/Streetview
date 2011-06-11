
/* obtain image url */

$(function() {

    // setting
    var around = 50; // m
    var latlng = new google.maps.LatLng(38.26151, 140.85146);
    var mapOptions = {
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        zoom: 12
    };
    var view_image = false;

    // jquery elements
    var $canvas = $('#map_canvas');
    var $pano = $('#pano');
    var $image = $('#image');
    var $param = function (name, str) {
        $('#param_'+name).text(str);
    };

    // google map elements
    var map = new google.maps.Map($canvas.get(0), mapOptions);
    var sv = new google.maps.StreetViewService();

    // memory variables
    var link = {};
    var stack = []; // string list
    var timer;
    var step = 1;

    var stop_walk = function () {
        clearInterval (timer);
        step = 1;
    };
    var log_walk = function (latlng, panoid, links) {
        $.each (links, function (i,v) { stack.push (v); });
        var img = view_image ?
            $.map (image_zoom3 (panoid), function (v,i) {
                return '<img src="'+v+'" width="128" height="128" />';
            }) : [];
        var data = img.join(' ')+'Latlng:'+latlng.toString()+', id:'+panoid;
        link[panoid] = data;
        $pano.prepend ('<li>'+data+'</li>');
        $.map (image_zoom1 (panoid), function (v,i) { $image.append('<li>'+v+'</li>'); });
        $.map (image_zoom2 (panoid), function (v,i) { $image.append('<li>'+v+'</li>'); });
        $.map (image_zoom3 (panoid), function (v,i) { $image.append('<li>'+v+'</li>'); });
    };
    var walk = function() {
        if (--step < 0) {
            stop_walk();
            alert ('All step clear!!');
        }
        var next = stack.pop();
        while (next && link[next]) {
            next = stack.shift();
        }
        if (!next) {
            stop_walk();
            alert ('Finish');
        }
        test_panoid (sv, next, log_walk);
    };
    test_panorama (sv, latlng, around, function (latlng, panoid, links) {
        log_walk (latlng, panoid, links);
        timer = setInterval (walk, 500);
    });

    //// Events ////
    // stop timer
    $('#stop').click(function() {
        stop_walk();
        alert ('Stop');
    });
    // jump location
    google.maps.event.addListener(map, 'click', function(event) {
        // Bug ?
        // latlng = new google.maps.LatLng(event.latLng);
        latlng = event.latLng;
        latlng = new google.maps.LatLng(latlng.lat(), latlng.lng());
        clearInterval (timer);
        test_panorama (sv, latlng, around, function (latlng, panoid, links) {
            log_walk (latlng, panoid, links);
            timer = setInterval (walk, 500);
            map.panTo(latlng);
            $param('center', latlng.toString());
        });
    });
});

function test_panorama (sv, l, around, f) {
    sv.getPanoramaByLocation (l, around, function (data, status) {
        if (status != google.maps.StreetViewStatus.OK) {
            alert ('Street view not supported.');
            return false;
        }
        var panoid = data.location.pano;
        var latlng = data.location.latLng;
        var link = $.map (data.links, function (v,i) { return v.pano; });
        f (latlng, panoid, link);
        return true;
    });
}
function test_panoid (sv, pid, f) {
    sv.getPanoramaById (pid, function (data, status) {
        if (status != google.maps.StreetViewStatus.OK) {
            alert ('Panorama id is invalid.');
            return false;
        }
        var latlng = data.location.latLng;
        var link = $.map (data.links, function (v,i) { return v.pano; });
        f (latlng, pid, link);
        return true;
    });
}

function image_zoom1 (pid) {
    return [image_address (pid,0,0,1), image_address (pid,1,0,1)];
}
function image_zoom2 (pid) {
    return [ image_address (pid,0,0,2), image_address (pid,1,0,2),
             image_address (pid,2,0,2), image_address (pid,3,0,2),
             image_address (pid,0,1,2), image_address (pid,1,1,2),
             image_address (pid,2,1,2), image_address (pid,3,1,2)];
}
function image_zoom3 (pid) {
    return $.map ([0,1,2,3], function (y,v) {
        return $.map ([0,1,2,3,4,5,6], function (x,w) {
            return image_address (pid,x,y,3);
        });
    });
}

var image_address = (function(){
    var server = -1;
    return function (pid, x, y, z) {
        server = (server + 1) % 4;
        return 'http://cbk'+server+'.googleapis.com/cbk?output=tile&panoid='+pid+'&zoom='+z+'&x='+x+'&y='+y+'&cb_client=apiv3&fover=2&onerr=3&v=4';
    };
})();

/* zoom: 1 - x4
http://cbk0.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=1&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* zoom: 2 - x8
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=0&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=1&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=1&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=2&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=2&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=3&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=3&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* zoom: 3 - x28
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=3&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=3&x=6&y=3&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* cbk[N].googleapis.com N = 0-3 */
