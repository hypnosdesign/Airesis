web: bundle exec puma -C config/puma.rb
worker: bundle exec rails solid_queue:start
mailman: ruby script/mailman_server.rb
release: bundle exec rails db:migrate
