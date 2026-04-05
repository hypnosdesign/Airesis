class Users::FacebookController < ApplicationController
  def setup
    request.env['omniauth.strategy'].options[:scope] = 'email'
    request.env['omniauth.strategy'].options[:client_options] = { ssl: { verify: false, ca_path: '/etc/ssl/certs' } }

    render plain: 'Setup complete.', status: 404
  end
end
