
/* obtain image url */
/* zoom: 1
http://cbk0.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=1&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=1&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk0.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=1&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* zoom: 2
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=0&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=1&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=1&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=2&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=2&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=3&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=2&x=3&y=1&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* zoom: 3
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=3&x=0&y=0&cb_client=apiv3&fover=2&onerr=3&v=4
http://cbk1.googleapis.com/cbk?output=tile&panoid=EPmej1fRGRj60ZCiQSDqvg&zoom=3&x=6&y=3&cb_client=apiv3&fover=2&onerr=3&v=4
*/
/* cbk[N].googleapis.com N = 0-3 */

$(function() {

    // setting
    var around = 50; // m
    var latlng = new google.maps.LatLng(38.26151, 140.85146);
    var mapOptions = {
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        zoom: 12
    };

    // jquery elements
    var $canvas = $('#map_canvas');
    var $pano = $('#pano');
    var $param = function (name, str) {
        $('#param_'+name).text(str);
    };

    // google map elements
    var map = new google.maps.Map($canvas.get(0), mapOptions);
    var sv = new google.maps.StreetViewService();

    // memory variables
    test_panorama (sv, latlng, around, function (latlng, panoid) {
        view_image($pano, panoid);
        $param('center', latlng.toString());
    });

    //// Events ////
    // jump location
    google.maps.event.addListener(map, 'click', function(event) {
        // Bug ?
        // latlng = new google.maps.LatLng(event.latLng);
        latlng = event.latLng;
        latlng = new google.maps.LatLng(latlng.lat(), latlng.lng());
        test_panorama (sv, latlng, around, function (latlng, panoid) {
            view_image($pano, panoid);
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
        // var url = data.tiles.getTileUrl(panoid, 1, 0, 0); undefined ?
        f (latlng, panoid);
        return true;
    });
}

function view_image ($pano, pid) {
    $pano.prepend('<li><img src="'+image_address(pid,1,1)+'" /></li>');
    $pano.prepend('<li><img src="'+image_address(pid,0,1)+'" /></li>');
}

function image_address (pid, x, z) {
    return 'http://cbk'+x+'.googleapis.com/cbk?output=tile&panoid='+pid+'&zoom='+z+'&x='+x+'&y=0&cb_client=apiv3&fover=2&onerr=3&v=4';
}