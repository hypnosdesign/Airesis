require 'simple_form/components/minlength'
# SimpleForm wrapper using DaisyUI classes (replaces Foundation wrapper)
SimpleForm.setup do |config|
  config.wrappers :daisyui, class: 'form-control mb-3',
                             hint_class: 'form-hint',
                             error_class: 'form-control-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :maxlength
    b.use :minlength
    b.optional :pattern
    b.use :min_max
    b.optional :readonly
    b.use :label
    b.use :input
    b.use :error, wrap_with: { tag: :p, class: 'text-error text-sm mt-1' }
    b.use :hint,  wrap_with: { tag: :p, class: 'text-base-content/60 text-sm mt-1' }
  end

  # CSS class for buttons
  config.button_class = 'btn'

  # CSS class for error notification banner
  config.error_notification_class = 'alert alert-error mb-4'

  # Default wrapper
  config.default_wrapper = :daisyui
end
