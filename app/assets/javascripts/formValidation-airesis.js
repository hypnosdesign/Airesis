this.AiresisFormValidation = class AiresisFormValidation {
  constructor(form) {
    var ckeditorValidator = {
      excluded: false,
      validators: {
        callback: {
          message: Airesis.i18n.validationMessages.notEmpty.default,
          callback: function(value, validator, $field) {
            if (value === '') {
              return false;
            } else {
              var div = $('<div/>').html(value).get(0);
              var text = div.textContent || div.innerText;
              return text.length > 0;
            }
          }
        }
      }
    };
    var translations = {};
    translations[Airesis.i18n.locale] = Airesis.i18n.validationMessages;
    FormValidation.I18n = $.extend(true, FormValidation.I18n || {}, translations);
    form.formValidation({
      locale: Airesis.i18n.locale,
      framework: 'foundation',
      icon: {
        valid: 'fa fa-check',
        invalid: 'fa fa-times',
        validating: 'fa fa-refresh'
      },
      trigger: 'blur',
      row: {
        selector: '.inputs'
      },
      fields: {
        'proposal[title]': {
          trigger: 'change',
          validators: {
            remote: {
              message: Airesis.i18n.validationMessages.alreadyTaken.default,
              url: function() {
                $('a[href="#next"]').addClass('disabled');
                return '/validators/uniqueness/proposal';
              },
              data: function(validator, $field, value) {
                return {
                  'proposal[title]': value,
                  'proposal[id]': $field.data('fv-remote-id')
                };
              },
              type: 'GET',
              delay: 200
            }
          }
        },
        'user[email]': {
          validators: {
            remote: {
              enabled: false,
              message: Airesis.i18n.validationMessages.alreadyTaken.default,
              url: '/validators/uniqueness/user',
              type: 'GET',
              delay: 1000
            }
          }
        },
        'group[name]': {
          validators: {
            remote: {
              message: Airesis.i18n.validationMessages.alreadyTaken.default,
              url: '/validators/uniqueness/group',
              data: function(validator, $field, value) {
                return {
                  'group[name]': value,
                  'group[id]': $field.data('fv-remote-id')
                };
              },
              type: 'GET',
              delay: 1000
            }
          }
        },
        'proposal[proposal_category_id]': {
          excluded: false
        },
        'proposal[sections_attributes][0][seq]': {
          excluded: false,
          validators: {
            callback: {
              message: Airesis.i18n.validationMessages.notEmpty.default,
              callback: function(value, validator, $field) {
                if (value === '') {
                  return false;
                } else {
                  var div = $('<div/>').html(value).get(0);
                  var text = div.textContent || div.innerText;
                  return text.length > 0;
                }
              }
            }
          }
        },
        'group[interest_border_tkn]': {
          excluded: false
        },
        'event[meeting_attributes][place_attributes][municipality_id]': {
          excluded: false
        },
        'group[description]': ckeditorValidator,
        'blog_post[body]': ckeditorValidator,
        'frm_post[text]': ckeditorValidator,
        'frm_topic[posts_attributes][0][text]': ckeditorValidator
      }
    }).on('success.validator.fv', (e, data) => {
      if (data.field === 'proposal[title]' && data.validator === 'remote') {
        $('a[href="#next"]').removeClass('disabled');
      }
    });
    form.filter('[data-remote=true]').on('success.form.fv', function(e) {
      var $form = $(e.target);
      if ($form.data('remote')) {
        e.preventDefault();
        return false;
      }
    });
    form.filter('[data-remote=true]').on('submit', function(e) {
      var $form = $(e.target);
      if ($form.data('remote')) {
        var numInvalidFields = $form.data('formValidation').getInvalidFields().length;
        if (numInvalidFields) {
          e.preventDefault();
          return false;
        }
      }
    });
  }
};
