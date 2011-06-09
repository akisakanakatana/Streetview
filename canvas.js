
$(function() {

    // == load the image ==
    var img = new Image();
    img.src = "cariconl.png";

    // ===== Check to see if this browser supports <canvas> ===
    if (!document.getElementById('testcanvas').getContext) {
        alert ('Your browser does not support canvas.');
        return false;
    }
    
    var angle = Math.PI/2; // == <canvas> uses radians, not degrees
    var map;

    load();

    // == uses <canvas> to rotate and plot the car ==
    function rotatecar() {
      var cosa = Math.cos(angle);
      var sina = Math.sin(angle);
      canvas.clearRect(0,0,32,32);     // clear the canvas
      canvas.save();                   // save the canvas state
      canvas.rotate(angle);            // rotate the canvas
      canvas.translate(16*sina+16*cosa,16*cosa-16*sina); // translate the canvas 16,16 in the rotated axes
      canvas.drawImage(img,-16,-16);   // plot the car
      canvas.restore();                // restore the canvas state, to undo the rotate and translate
      angle += 0.1;
    }

    function load() {
      if (GBrowserIsCompatible()) {
        // Display the map, with some controls and set the initial location 
        map = new GMap2(document.getElementById("map"));
        map.setCenter(new GLatLng(43.907787,-79.359741),13);
        map.addControl(new GMapTypeControl());
        map.addControl(new GLargeMapControl());

        // == Check if the browser supports <canvas> and if so create a <canvas> inside an ELabel ==
          label = new ELabel(map.getCenter(), '<canvas id="carcanvas" width="32" height="32"><\/canvas>',null,new GSize(-16,16));
          map.addOverlay(label);
          canvas = document.getElementById("carcanvas").getContext('2d');
          angle = Math.PI/2;
//          setInterval(rotatecar, 100);
      }
    }
    // This Javascript is based on code provided by the
    // Community Church Javascript Team
    // http://www.bisphamchurch.org.uk/   
    // http://econym.org.uk/gmap/
});