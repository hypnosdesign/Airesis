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

    # Throttle registrazione: max 5 tentativi per ora per IP
    Rack::Attack.throttle('registrations/ip', limit: 5, period: 1.hour) do |req|
      req.ip if req.path == '/users' && req.post?
    end

    # Throttle API: max 60 richieste per minuto per IP
    Rack::Attack.throttle('api/ip', limit: 60, period: 1.minute) do |req|
      req.ip if req.path.start_with?('/api/')
    end
  end
end
