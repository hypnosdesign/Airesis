window.EventsIndex = {
  init: function() {
    var fullCalendarOptions;
    $('.create_event').on('click', function() {
      var create_event_ = $('#create_event_dialog');
      create_event_.empty();
      create_event_.append($('.choose_event_type').clone().show());
      $('.event_model_option', create_event_).click(function() {
        var create_event_inner_ = $('.choose_event_type', create_event_);
        var type_id = $(this).data('id');
        create_event_inner_.hide(1000, function() {
          create_event_inner_.remove();
          create_event_.append(EventsIndex.loadingFragment);
          $.ajax({
            url: EventsIndex.newEventUrl,
            data: {
              event_type_id: type_id
            },
            dataType: 'script'
          });
        });
      });
      create_event_.foundation('reveal', 'open', {
        closeOnBackgroundClick: false,
        closeOnEsc: false
      });
      return false;
    });
    $(window).resize(function() {
      $('#calendar').fullCalendar('option', 'height', $(window).height() - 170);
    });
    fullCalendarOptions = {
      editable: true,
      height: $(window).height() - 185,
      header: {
        left: 'today prev,next',
        center: 'title',
        right: 'list,month,agendaWeek,agendaDay'
      },
      eventLimit: true,
      views: {
        month: {
          eventLimit: 4
        }
      },
      defaultView: 'month',
      slotMinutes: 15,
      events: EventsIndex.eventsUrl,
      columnFormat: {
        month: 'ddd',
        week: 'ddd M/D',
        day: 'dddd'
      },
      axisFormat: 'H:mm',
      dragOpacity: '0.5',
      eventDrop: function(event, delta, revertFunc, jsEvent, ui, view) {
        return jQuery.ajax({
          data: {
            day_delta: delta.days(),
            minute_delta: delta.minutes()
          },
          dataType: 'script',
          type: 'post',
          url: `/events/${event.id}/move`
        });
      },
      eventResize: function(event, delta, revertFunc, jsEvent, ui, view) {
        return jQuery.ajax({
          data: {
            day_delta: delta.days(),
            minute_delta: delta.minutes()
          },
          dataType: 'script',
          type: 'post',
          url: `/events/${event.id}/resize`
        });
      },
      eventClick: function(event, jsEvent, view) {
        return window.location = event.url;
      },
      eventRender: function(event, element) {
        if (event.editable) {
          element.css('cursor', 'pointer');
        }
      }
    };
    fullCalendarOptions = $.extend(fullCalendarOptions, EventsIndex.calendarI18n);
    if (EventsIndex.createEvent) {
      fullCalendarOptions = $.extend(fullCalendarOptions, {
        dayClick: function(date, jsEvent, view) {
          $.ajax({
            data: {
              starttime: date.valueOf(),
              has_time: date.hasTime(),
              event_type_id: EventsIndex.defaultEventType
            },
            url: EventsIndex.newEventUrlClick,
            dataType: 'script'
          });
        }
      });
    } else {
      fullCalendarOptions = $.extend(fullCalendarOptions, {
        disableDragging: true,
        disableResizing: true
      });
    }
    $('#calendar').fullCalendar(fullCalendarOptions);
    if (EventsIndex.autoOpen) {
      return $.ajax({
        url: EventsIndex.autoOpenUrl,
        dataType: 'script'
      });
    }
  }
};
