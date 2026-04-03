window.EventsNew = {
  init: function() {
    var form = $('#new_event');
    form.steps({
      headerTag: ".legend",
      bodyTag: ".step",
      autoFocus: true,
      labels: {
        previous: '<i class="fa-solid fa-arrow-left"></i>' + Airesis.i18n.buttons.goBack,
        next: Airesis.i18n.buttons.next + '<i class="fa-solid fa-arrow-right"></i>',
        finish: Airesis.i18n.buttons.eventsFinish
      },
      onStepChanging: function(e, currentIndex, newIndex) {
        var $container = form.find('.step.current');
        var fv = form.data('formValidation');
        fv.validateContainer($container);
        var isValidStep = fv.isValidContainer($container);
        return !(isValidStep === false || isValidStep === null);
      },
      onStepChanged: function(event, currentIndex, priorIndex) {
        return setTimeout((function() {
          if (!EventsEdit.votation) {
            EventsNew.mapManager.refresh();
          }
        }), 1000);
      },
      onFinishing: function(e, currentIndex) {
        var $container = form.find('.step.current');
        var fv = form.data('formValidation');
        fv.validateContainer($container);
        var isValidStep = fv.isValidContainer($container);
        return !(isValidStep === false || isValidStep === null);
      },
      onFinished: function(e, currentIndex) {
        return form.formValidation('defaultSubmit');
      },
      onInit: function(e, currentIndex) {
        return form.find('[role="menuitem"]').addClass('btn').addClass('blue');
      }
    });
    $('#create_event_dialog:not(".open")').foundation('reveal', 'open', {
      closeOnBackgroundClick: false,
      closeOnEsc: false
    });
    start_end_fdatetimepicker($('#event_starttime'), $("#event_endtime"));
    this.initMunicipalityInput();
    this.initMapManager();
    return new AiresisFormValidation(form);
  },
  initMunicipalityInput: function() {
    var input = $('#event_meeting_attributes_place_attributes_municipality_id');
    Airesis.select2town(input);
    return input.change(function(e) {
      return $('#new_event').formValidation('revalidateField', input);
    });
  },
  initMapManager: function() {
    if (!EventsEdit.votation) {
      return EventsNew.mapManager = new Airesis.MapManager('create_map_canvas');
    }
  }
};
