window.EventsEdit = {
  init: function() {
    start_end_fdatetimepicker($('#event_starttime'), $("#event_endtime"));
    this.initMunicipalityInput();
    this.initClientSideValidation();
    this.initMapManager();
    if (EventsEdit.votation) {
      this.showPlace('2');
    }
    if ($('#event_all_day').is(':checked')) {
      return fdatetimepicker_only_date($('#event_starttime'), $("#event_endtime"));
    }
  },
  showPlace: function(value) {
    switch (value) {
      case '2': //votazione
        $('#luogo').hide();
        return $('#create_map_canvas').hide();
      default:
        $('#luogo').show();
        return $('#create_map_canvas').show();
    }
  },
  initClientSideValidation: function() {
    return new AiresisFormValidation($('#edit_event_' + EventsEdit.eventId));
  },
  initMunicipalityInput: function() {
    var input = $('#event_meeting_attributes_place_attributes_municipality_id');
    Airesis.select2town(input);
    return input.change(function(e) {
      return $('#edit_event_' + EventsEdit.eventId).formValidation('revalidateField', input);
    });
  },
  initMapManager: () => {
    var center, latlng;
    if (EventsEdit.placeDefined) {
      latlng = new google.maps.LatLng(EventsEdit.latitudeOriginal, EventsEdit.longitudeOriginal);
      center = new google.maps.LatLng(EventsEdit.latitudeCenter, EventsEdit.longitudeCenter);
      return EventsEdit.mapManager = new Airesis.MapManager('edit_map_canvas', latlng, center, this.zoom);
    } else {
      return EventsEdit.mapManager = new Airesis.MapManager('edit_map_canvas');
    }
  }
};
