require 'rails_helper'

RSpec.describe 'G10 administration route inventory' do
  it 'keeps the reviewed route and action contract fixed' do
    routes = Rails.application.routes.routes.filter_map do |route|
      controller = route.defaults[:controller] || route.requirements[:controller]
      action = route.defaults[:action] || route.requirements[:action]
      [route.verb, controller, action] if controller.to_s.start_with?('admin/')
    end

    expect(routes.size).to eq(22)
    expect(routes.count { |verb,| verb == 'GET' }).to eq(8)
    expect(routes).to all(satisfy do |_verb, controller, action|
      "#{controller}_controller".camelize.constantize.action_methods.include?(action.to_s)
    end)
  end
end
