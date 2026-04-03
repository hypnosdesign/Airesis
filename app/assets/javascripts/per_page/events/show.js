window.EventsShow = {
  init: function() {
    if (!this.votation) {
      this.latlng = new google.maps.LatLng(EventsShow.latitudeOriginal, EventsShow.longitudeOriginal);
      this.center = this.latlng;
      this.myOptions = {
        zoom: this.zoom,
        center: this.center,
        mapTypeId: google.maps.MapTypeId.ROADMAP,
        panControl: false,
        streetViewControl: false,
        mapTypeControl: true,
        draggable: true
      };
      this.map = new google.maps.Map(document.getElementById('map_canvas'), this.myOptions);
      return this.marker = new google.maps.Marker({
        map: this.map,
        position: this.latlng,
        draggable: false
      });
    }
  }
};
