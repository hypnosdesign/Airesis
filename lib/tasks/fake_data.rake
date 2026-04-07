# Rake tasks per generare dati fake utili a testare l'interfaccia in development.
#
# UTILIZZO RAPIDO:
#   rails airesis:seed:demo:complete       # popola tutto
#   rails airesis:seed:demo:reset          # cancella tutti i dati demo (NON i dati di sistema)
#
# TASK INDIVIDUALI:
#   rails "airesis:seed:demo:users[10]"
#   rails "airesis:seed:demo:groups[3]"
#   rails "airesis:seed:demo:proposals[5]"
#   rails "airesis:seed:demo:forum[2]"
#   rails "airesis:seed:demo:blog[3]"
#   rails "airesis:seed:demo:events[4]"
#
# TASK LEGACY (compatibilità):
#   rails "airesis:seed:more:public_proposals[N]"
#   rails "airesis:seed:more:votable_proposals[N,M]"
#   rails "airesis:seed:more:abandoned_proposals[N]"

DEMO_EMAIL_DOMAIN = '@demo.airesis.local'

def demo_requires
  require 'faker'
  require 'factory_bot_rails'
  require 'timecop'
  Faker::Config.locale = 'it'
end

namespace :airesis do
  namespace :seed do

    # ─────────────────────────────────────────────────────────
    # DEMO NAMESPACE — dati per test UI completo
    # ─────────────────────────────────────────────────────────
    namespace :demo do

      # ── RESET ──────────────────────────────────────────────
      desc 'Cancella tutti i dati demo (utenti @demo.airesis.local e tutto il contenuto associato). NON tocca i dati di sistema (quorum, tipi, stati, geografia).'
      task reset: :environment do
        abort 'Questo task è disponibile solo in development!' unless Rails.env.development?

        puts '⚠️  Reset dati demo in corso...'

        # Cancella in ordine per rispettare le FK
        puts '  → Proposte...'
        Proposal.destroy_all

        puts '  → Forum...'
        Frm::Post.delete_all
        Frm::View.delete_all
        Frm::Topic.delete_all
        Frm::Forum.delete_all
        Frm::Category.delete_all

        puts '  → Blog...'
        BlogComment.delete_all
        PostPublishing.delete_all
        BlogPost.delete_all
        Blog.where.not(user_id: nil).each { |b| b.destroy if b.user&.email&.ends_with?(DEMO_EMAIL_DOMAIN) }

        puts '  → Eventi...'
        Event.destroy_all

        puts '  → Gruppi...'
        Group.destroy_all

        puts '  → Utenti demo...'
        User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").find_each(&:destroy)

        puts '✅  Reset completato.'
      end

      # ── USERS ──────────────────────────────────────────────
      desc 'Crea utenti demo [count=10]. Email: nome.cognome@demo.airesis.local, password: topolino'
      task :users, [:count] => :environment do |_t, args|
        demo_requires
        count = (args[:count] || 10).to_i
        puts "👤 Creo #{count} utenti demo..."
        count.times do |i|
          first = Faker::Name.first_name
          last  = Faker::Name.last_name
          email = "#{first.downcase}.#{last.downcase}.#{i}#{DEMO_EMAIL_DOMAIN}"
          FactoryBot.create(:user, name: first, surname: last, email: email, password: 'topolino', password_confirmation: 'topolino')
          print '.'
        end
        puts "\n✅  #{count} utenti creati (password: topolino)"
      end

      # ── GROUPS ─────────────────────────────────────────────
      desc 'Crea gruppi demo con partecipanti [count=3, participants=8]'
      task :groups, %i[count participants] => :environment do |_t, args|
        demo_requires
        count        = (args[:count] || 3).to_i
        participants = (args[:participants] || 8).to_i

        # Assicura che ci siano abbastanza utenti demo
        existing = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").count
        if existing < participants + 1
          needed = participants + 1 - existing
          puts "👤 Creo #{needed} utenti demo aggiuntivi..."
          needed.times do |i|
            first = Faker::Name.first_name
            last  = Faker::Name.last_name
            email = "#{first.downcase}.#{last.downcase}.grp#{i}#{DEMO_EMAIL_DOMAIN}"
            FactoryBot.create(:user, name: first, surname: last, email: email, password: 'topolino', password_confirmation: 'topolino')
          end
        end

        demo_users = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").to_a

        puts "🏛️  Creo #{count} gruppi con #{participants} partecipanti ciascuno..."
        count.times do |i|
          creator = demo_users[i % demo_users.size]
          group = FactoryBot.create(:group, current_user_id: creator.id, num_participants: 0)

          # Aggiungi partecipanti reali tra gli utenti demo
          participants.times do |j|
            member = demo_users[(i + j + 1) % demo_users.size]
            next if member == creator
            next if group.participants.include?(member)
            group.participation_requests.create!(user: member, group_participation_request_status_id: :accepted)
            group.group_participations.create!(user: member, participation_role_id: group.participation_role_id)
          end
          group.reload
          print "."
        end
        puts "\n✅  #{count} gruppi creati."
      end

      # ── PROPOSALS ──────────────────────────────────────────
      desc 'Crea proposte demo in tutti gli stati [count=5 per stato]'
      task :proposals, [:count] => :environment do |_t, args|
        demo_requires
        count = (args[:count] || 5).to_i

        puts "📄 Creo proposte in dibattito (#{count})..."
        count.times do
          user = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").sample || FactoryBot.create(:user)
          FactoryBot.create(:in_debate_public_proposal, current_user_id: user.id, debate_duration: rand(3..10))
          print '.'
        end

        puts "\n📄 Creo proposte in votazione (#{count})..."
        Timecop.travel(3.days.ago) do
          count.times do
            FactoryBot.create(:in_vote_public_proposal, num_solutions: rand(2..4))
            print '.'
          end
        end

        puts "\n📄 Creo proposte abbandonate (#{[count / 2, 1].max})..."
        Timecop.travel(15.days.ago) do
          [count / 2, 1].max.times do
            FactoryBot.create(:abadoned_public_proposal)
            print '.'
          end
        end

        puts "\n✅  Proposte create."
      end

      # ── FORUM ──────────────────────────────────────────────
      desc 'Crea forum demo per ogni gruppo esistente [topics=5, posts_per_topic=4]'
      task :forum, %i[topics posts_per_topic] => :environment do |_t, args|
        demo_requires
        topics_count    = (args[:topics] || 5).to_i
        posts_per_topic = (args[:posts_per_topic] || 4).to_i

        groups = Group.all.to_a
        abort '⚠️  Nessun gruppo trovato. Esegui prima airesis:seed:demo:groups.' if groups.empty?

        demo_users = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").to_a
        demo_users = FactoryBot.create_list(:user, 3) if demo_users.empty?

        puts "💬 Creo forum per #{groups.size} gruppi..."
        groups.each do |group|
          category = FactoryBot.create(:frm_category, group: group)
          forum    = FactoryBot.create(:frm_forum, category: category, group: group)

          topics_count.times do
            author = demo_users.sample
            topic  = FactoryBot.create(:approved_topic, forum: forum, user: author)

            (posts_per_topic - 1).times do
              FactoryBot.create(:post, topic: topic, user: demo_users.sample)
            end
            print '.'
          end
        end
        puts "\n✅  Forum creati."
      end

      # ── BLOG ───────────────────────────────────────────────
      desc 'Crea blog post demo [posts=5, comments_per_post=3]'
      task :blog, %i[posts comments_per_post] => :environment do |_t, args|
        demo_requires
        posts_count       = (args[:posts] || 5).to_i
        comments_per_post = (args[:comments_per_post] || 3).to_i

        demo_users = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").to_a
        demo_users = FactoryBot.create_list(:user, 3) if demo_users.empty?

        groups = Group.all.to_a

        puts "📝 Creo #{posts_count} blog post..."
        posts_count.times do
          author    = demo_users.sample
          blog      = author.blog || FactoryBot.create(:blog, user: author)
          blog_post = FactoryBot.create(:blog_post, user: author, blog: blog)

          # Pubblica nel primo gruppo disponibile (se esiste)
          if groups.any?
            group = groups.sample
            group.post_publishings.create(blog_post: blog_post)
          end

          comments_per_post.times do
            FactoryBot.create(:blog_comment, blog_post: blog_post, user: demo_users.sample)
          end
          print '.'
        end
        puts "\n✅  Blog post creati."
      end

      # ── EVENTS ─────────────────────────────────────────────
      desc 'Crea eventi demo (incontri) [count=4]'
      task :events, [:count] => :environment do |_t, args|
        demo_requires
        count = (args[:count] || 4).to_i

        demo_users = User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").to_a
        demo_users = FactoryBot.create_list(:user, 2) if demo_users.empty?

        groups = Group.all.to_a

        puts "📅 Creo #{count} eventi..."
        count.times do |i|
          user      = demo_users.sample
          starttime = rand(1..30).days.from_now
          endtime   = starttime + rand(1..4).hours

          event = FactoryBot.create(:meeting_event,
                                    user: user,
                                    starttime: starttime,
                                    endtime: endtime,
                                    private: groups.any?)

          # Associa al gruppo se esiste
          if groups.any?
            group = groups.sample
            group.events << event unless group.events.include?(event)
          end
          print '.'
        end
        puts "\n✅  #{count} eventi creati."
      end

      # ── COMPLETE ───────────────────────────────────────────
      desc 'Popola completamente l\'app con dati demo (utenti, gruppi, proposte, forum, blog, eventi)'
      task complete: :environment do
        abort 'Questo task è disponibile solo in development!' unless Rails.env.development?

        puts '🚀 Popolamento completo dati demo...'
        puts '=' * 50

        Rake::Task['airesis:seed:demo:users'].invoke('12')
        Rake::Task['airesis:seed:demo:groups'].invoke('3', '8')
        Rake::Task['airesis:seed:demo:proposals'].invoke('6')
        Rake::Task['airesis:seed:demo:forum'].invoke('5', '4')
        Rake::Task['airesis:seed:demo:blog'].invoke('6', '3')
        Rake::Task['airesis:seed:demo:events'].invoke('5')

        puts '=' * 50
        puts '✅  Popolamento completato!'
        puts ''
        puts '📊 Riepilogo:'
        puts "   Utenti demo : #{User.where("email LIKE ?", "%#{DEMO_EMAIL_DOMAIN}").count}"
        puts "   Gruppi      : #{Group.count}"
        puts "   Proposte    : #{Proposal.count}"
        puts "   Topic forum : #{Frm::Topic.count}"
        puts "   Blog post   : #{BlogPost.count}"
        puts "   Eventi      : #{Event.count}"
        puts ''
        puts '🔑 Login demo: <email>@demo.airesis.local / topolino'
      end

    end

    # ─────────────────────────────────────────────────────────
    # MORE NAMESPACE — task legacy per compatibilità
    # ─────────────────────────────────────────────────────────
    namespace :more do
      desc 'Create more public proposals in debate'
      task :public_proposals, [:number] => :environment do |_task, args|
        require 'faker'
        require 'factory_bot_rails'
        number = (args[:number] || 1).to_i
        FactoryBot.create_list(:public_proposal, number, current_user_id: FactoryBot.create(:user).id)
      end

      desc 'Create more public proposals in vote for the next three days'
      task :votable_proposals, %i[number num_solutions] => :environment do |_task, args|
        require 'faker'
        require 'factory_bot_rails'
        require 'timecop'
        number = (args[:number] || 1).to_i
        num_solutions = (args[:num_solutions] || 2).to_i

        Timecop.travel(2.days.ago) do
          FactoryBot.create_list(:in_vote_public_proposal, number, num_solutions: num_solutions)
        end
      end

      desc 'Create more abandoned proposals'
      task :abandoned_proposals, [:number] => :environment do |_task, args|
        require 'faker'
        require 'factory_bot_rails'
        require 'timecop'
        number = (args[:number] || 1).to_i

        Timecop.travel(10.days.ago) do
          FactoryBot.create_list(:abadoned_public_proposal, number)
        end
      end

      desc 'Clear all proposals'
      task clear_proposals: :environment do
        Proposal.destroy_all
      end
    end

  end
end
