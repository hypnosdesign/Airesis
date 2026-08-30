module Rack
  class Attack
    # Blocca bot noti e probe di sicurezza comuni.
    # NOTA: l'intera espressione deve essere l'ultima (e unica) nel blocco —
    # Ruby restituisce l'ultimo valore valutato, quindi espressioni separate
    # vengono ignorate.
    Rack::Attack.blocklist('bad-robots') do |req|
      /\S+\.php/.match?(req.path) ||
        CGI.unescape(req.query_string) =~ %r{/etc/passwd} ||
        req.path.include?('wp-admin') ||
        req.path.include?('wp-login') ||
        req.path.include?('/etc/passwd') ||
        req.path.include?('ads.txt')
    end

    # Throttle login: max 5 tentativi per 20 secondi per IP
    Rack::Attack.throttle('logins/ip', limit: 5, period: 20) do |req|
      req.ip if req.path == '/users/sign_in' && req.post?
    end

    token_request = ->(req) { req.path == '/tokens' && req.post? }

    normalized_token_email = lambda do |req|
      next unless token_request.call(req)

      email = req.params['email']
      if email.blank? && req.media_type == 'application/json'
        body = req.body.read
        req.body.rewind
        email = JSON.parse(body)['email'] if body.present?
      end
      email.to_s.strip.downcase.presence
    rescue JSON::ParserError
      nil
    ensure
      req.body.rewind if req.body.respond_to?(:rewind)
    end

    # Protegge l'endpoint che emette token sia dagli attacchi distribuiti su
    # uno stesso account sia dai tentativi concentrati da un singolo IP.
    Rack::Attack.throttle('tokens/ip', limit: 5, period: 20.seconds) do |req|
      req.ip if token_request.call(req)
    end

    Rack::Attack.throttle('tokens/email', limit: 5, period: 1.minute) do |req|
      normalized_token_email.call(req)
    end

    # Throttle registrazione: max 5 tentativi per ora per IP
    Rack::Attack.throttle('registrations/ip', limit: 5, period: 1.hour) do |req|
      req.ip if req.path == '/users' && req.post?
    end

    # Throttle API: max 60 richieste per minuto per IP
    Rack::Attack.throttle('api/ip', limit: 60, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/api/')
    end

    # Throttle admin panel: max 30 azioni per minuto per IP
    Rack::Attack.throttle('admin/ip', limit: 30, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/admin/panel') && req.post?
    end

    # Throttle password reset: max 5 tentativi per ora per IP
    Rack::Attack.throttle('password_reset/ip', limit: 5, period: 1.hour) do |req|
      req.ip if req.path == '/users/password' && req.post?
    end
  end
end
