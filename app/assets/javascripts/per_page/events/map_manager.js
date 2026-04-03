Airesis.MapManager = class MapManager {
  constructor(mapCanvasId, latng, center, zoom) {
    this.mapField = this.mapField.bind(this);
    this.putMarker = this.putMarker.bind(this);
    this.listenMarkerPosition = this.listenMarkerPosition.bind(this);
    this.listenCenterChanged = this.listenCenterChanged.bind(this);
    this.listenZoomChanged = this.listenZoomChanged.bind(this);
    this.basename = 'event_meeting_attributes_place_attributes_';
    this.geocoder = new google.maps.Geocoder();
    this.latlng = latng != null ? latng : new google.maps.LatLng(42.407235, 14.260254);
    this.center = center != null ? center : this.latlng;
    this.zoom = zoom != null ? zoom : 8;
    this.mapCanvasId = mapCanvasId;
    this.myOptions = {
      zoom: this.zoom,
      center: this.center,
      mapTypeId: google.maps.MapTypeId.ROADMAP,
      panControl: true,
      streetViewControl: false,
      mapTypeControl: false
    };
    this.map = new google.maps.Map(document.getElementById(this.mapCanvasId), this.myOptions);
    this.markerCache = {};
    this.marker = new google.maps.Marker({
      map: this.map,
      position: this.latlng,
      draggable: true
    });
    google.maps.event.addListener(this.marker, 'dragend', this.listenMarkerPosition);
    google.maps.event.addListener(this.map, 'center_changed', this.listenCenterChanged);
    google.maps.event.addListener(this.map, 'zoom_changed', this.listenZoomChanged);
    this.mapField('municipality_id').on('change', () => {
      return this.codeAddress();
    });
    this.mapField('address').on('keyup', () => {
      return this.codeAddress();
    });
  }

  listenMarkerPosition() {
    var location_ = this.marker.getPosition();
    this.mapField('latitude_original').val(location_.lat());
    return this.mapField('longitude_original').val(location_.lng());
  }

  listenCenterChanged() {
    var location_ = this.map.getCenter();
    this.mapField('latitude_center').val(location_.lat());
    return this.mapField('longitude_center').val(location_.lng());
  }

  listenZoomChanged() {
    return this.mapField('zoom').val(this.map.getZoom());
  }

  mapField(name) {
    return $(`#${this.basename}${name}`);
  }

  putMarker(address) {
    if (this.markerCache[address] === undefined) {
      $('.loading_place').show();
      this.geocoder.geocode({
        'address': address
      }, (results, status) => {
        if (status === google.maps.GeocoderStatus.OK) {
          this.markerCache[address] = results;
          this.posizionaMappa(results[0].geometry.location, results[0].geometry.viewport);
          this.listenMarkerPosition();
          return $('.loading_place').hide();
        }
      });
    } else {
      this.listenMarkerPosition();
    }
  }

  codeAddress() {
    Airesis.delay((() => {
      var address, comune;
      comune = $('#event_meeting_attributes_place_attributes_municipality_id').find(':selected').text();
      if (comune !== null) {
        address = comune + ', ' + this.mapField('address').val();
        this.putMarker(address);
      }
    }), 600);
  }

  posizionaMappa(latlng, viewport) {
    this.map.setCenter(latlng);
    this.marker.setPosition(latlng);
    return this.map.fitBounds(viewport);
  }

  refresh() {
    google.maps.event.trigger(this.map, 'resize');
    return this.map.setCenter(this.latlng);
  }
};
