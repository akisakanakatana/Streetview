
var sv = new google.maps.StreetViewService();

$(function() {
    var latlng = new google.maps.LatLng(38.26151, 140.85146);
    var heading = 0;
    var mapOptions = {
        center: latlng,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        zoom: 12
    };

    var $canvas = $('#map_canvas').get(0);
    var $pano = $('#pano li');
    var $slider = $('#heading');
    var $param = function (name, str) {
        $('#param_'+name).text(str);
    };

    var map = new google.maps.Map($canvas, mapOptions);

    var processSVData = function(data, status) {
        if (status == google.maps.StreetViewStatus.OK) {
            var res = "";
            dump (data, function() {
                res += '<ul>';
            }, function(k,v) {
                res += '<li>'+k+':'+v+'</li>';
            }, function() {
                res += '</ul>';
            });
            $('body').append(res);
//             var marker = new google.maps.Marker({
//                 position: data.location.latLng,
//                 map: map,
//                 title: data.location.description
//             });
//             google.maps.event.addListener(marker, 'click', function() {
                
//                 var markerPanoID = data.location.pano;
//                 // Set the Pano to use the passed panoID
//                 panorama.setPano(markerPanoID);
//                 panorama.setPov({
//                     heading: 270,
//                     pitch: 0,
//                     zoom: 1
//                 });
//                 panorama.setVisible(true);
//             });
        } else {
            // Failed to street view
            alert('Failed');
        }
    };

    google.maps.event.addListener(map, 'click', function(event) {
        // Why doesn't this work ?
        // var clicked = new google.maps.LatLng(event.latLng);
        latlng = event.latLng;
        latlng =
            new google.maps.LatLng(latlng.lat(), latlng.lng());
        sv.getPanoramaByLocation(latlng, 50, processSVData);
        map.panTo(latlng);
        $param('center', latlng.toString());
    });

    $param('center', latlng.toString());
});

function dump (data, start, f, end) {
    start();
    for (var i in data) {
        f (i, data[i]);
        if (typeof data[i] == "object") {
            dump (data[i], start, f, end);
        }
    }
    end();
}

/*
result:undefined
location: {
    latLng:(38.26145, 140.85131)
    Ia:38.26145
    Ja:140.85131
    toString:function(){return"("+this.lat()+", "+this.lng()+")"}
    equals:function(a){if(!a)return!1;return nd(this.lat(),a.lat())&&nd(this.lng(),a.lng())}
    lat:function(){return this[a]}
    lng:function(){return this[a]}

    toUrlValue:function(a){a=sd(a)?a:6;return Md(this.lat(),a)+","+Md(this.lng(),a)}
    description:'',
    pano:Jtxj6mh5aWppDi_l-sAyGQ
},
copyright:c 2011 Google,
links: {
    0: {
        heading:63,
        description:'',
        pano:EPmej1fRGRj60ZCiQSDqvg,
        roadColor:#ffffff,
        roadOpacity:0.5019607843137255
    },
    1: {
        heading:243,
        description:'',
        pano:DwExLhPXVyfhVKY-sPpfuw,
        roadColor:#ffffff,
        roadOpacity:0.5019607843137255,
}}
tiles: {
    worldSize:(3328, 1664)
    width:3328
    height:1664
    A:px
    n:px
    toString:function(){return"("+this[u]+", "+this[H]+")"}
    equals:function(a){if(!a)return!1;return a[u]==this[u]&&a[H]==this[H]}
    tileSize:(512, 512)
    width:512
    height:512
    A:px
    n:px
    toString:function(){return"("+this[u]+", "+this[H]+")"}
    equals:function(a){if(!a)return!1;return a[u]==this[u]&&a[H]==this[H]}
    centerHeading:242.51
    originHeading:242.51
}
*/