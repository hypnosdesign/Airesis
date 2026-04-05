require 'simple_form/components/minlength'

# SimpleForm wrapper using DaisyUI + Tailwind classes
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
    b.use :label, class: 'label label-text font-semibold'
    b.use :input, class: 'input input-bordered w-full', error_class: 'input-error'
    b.use :error, wrap_with: { tag: :p, class: 'text-error text-sm mt-1' }
    b.use :hint,  wrap_with: { tag: :p, class: 'text-base-content/60 text-sm mt-1' }
  end

  config.wrappers :daisyui_textarea, class: 'form-control mb-3',
                                      hint_class: 'form-hint',
                                      error_class: 'form-control-error' do |b|
    b.use :html5
    b.use :placeholder
    b.use :maxlength
    b.use :minlength
    b.optional :readonly
    b.use :label, class: 'label label-text font-semibold'
    b.use :input, class: 'textarea textarea-bordered w-full', error_class: 'textarea-error'
    b.use :error, wrap_with: { tag: :p, class: 'text-error text-sm mt-1' }
    b.use :hint,  wrap_with: { tag: :p, class: 'text-base-content/60 text-sm mt-1' }
  end

  config.wrappers :daisyui_boolean, class: 'form-control mb-3',
                                     hint_class: 'form-hint',
                                     error_class: 'form-control-error' do |b|
    b.use :html5
    b.use :label, class: 'label cursor-pointer gap-2'
    b.use :input, class: 'checkbox checkbox-primary'
    b.use :error, wrap_with: { tag: :p, class: 'text-error text-sm mt-1' }
    b.use :hint,  wrap_with: { tag: :p, class: 'text-base-content/60 text-sm mt-1' }
  end

  config.wrappers :daisyui_select, class: 'form-control mb-3',
                                    hint_class: 'form-hint',
                                    error_class: 'form-control-error' do |b|
    b.use :html5
    b.use :label, class: 'label label-text font-semibold'
    b.use :input, class: 'select select-bordered w-full', error_class: 'select-error'
    b.use :error, wrap_with: { tag: :p, class: 'text-error text-sm mt-1' }
    b.use :hint,  wrap_with: { tag: :p, class: 'text-base-content/60 text-sm mt-1' }
  end

  # Mapping input types to wrappers
  config.wrapper_mappings = {
    boolean: :daisyui_boolean,
    text: :daisyui_textarea,
    select: :daisyui_select,
    collection: :daisyui_select,
    grouped_select: :daisyui_select
  }

  # CSS class for buttons
  config.button_class = 'btn btn-primary'

  # CSS class for error notification banner
  config.error_notification_class = 'alert alert-error mb-4'

  # Default wrapper
  config.default_wrapper = :daisyui
end
