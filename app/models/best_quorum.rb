# Quorum di tipo "best" — il modello di quorum standard usato per le proposte deliberative.
#
# Gestisce due timer separati:
#   - **dibattito** (`minutes`): durata della fase di dibattito (valutazione)
#   - **votazione** (`vote_minutes`): durata della fase di voto
#
# I tempi di votazione sono memorizzati in minuti in DB ma esposti all'utente come
# giorni/ore/minuti tramite gli accessori `vote_days_m`, `vote_hours_m`, `vote_minutes_m`.
#
# La transizione di fase (dibattito → voto) è gestita da `check_phase`.
# La chiusura del voto e calcolo del risultato Schulze/standard è in `close_vote_phase`.
class BestQuorum < Quorum
  validates :minutes, numericality: { only_integer: true, greater_than_or_equal_to: 5 }

  # Accessori per la UI: l'utente inserisce giorni/ore/minuti, `populate_vote` li converte in minuti totali.
  attr_accessor :vote_days_m, :vote_hours_m, :vote_minutes_m

  # Chiamato SOLO alla creazione: calcola `vote_minutes` se non è già impostato.
  # Permette di importare quorum con `vote_minutes` già valorizzato senza sovrascrivere.
  before_save :populate_vote

  # Chiamato ad ogni UPDATE: ricalcola sempre `vote_minutes` dagli accessori UI.
  # Il comportamento differisce da `before_save` perché in update si assume che l'utente abbia modificato i valori.
  before_update :populate_vote!

  after_find :populate_accessor

  def valutations
    (self[:valutations]) || 1
  end

  # Scompone `vote_minutes` (intero in DB) negli accessori UI giorni/ore/minuti.
  # Chiamato da `after_find` per pre-popolare i campi del form di editing.
  def populate_accessor
    super
    self.vote_minutes_m = vote_minutes
    return unless vote_minutes_m
    return unless vote_minutes_m > 59

    self.vote_hours_m = vote_minutes_m / 60
    self.vote_minutes_m = vote_minutes_m % 60
    return unless vote_hours_m > 23

    self.vote_days_m = vote_hours_m / 24
    self.vote_hours_m = vote_hours_m % 24
  end

  # Calcola `vote_minutes` dagli accessori UI solo se non è già impostato.
  # Usato nel `before_save` (solo create): preserva un valore già esistente (es. import da admin).
  # Imposta anche `bad_score = good_score` (i nuovi quorum non hanno un punteggio "cattivo" separato).
  #
  # @return [void]
  def populate_vote
    unless vote_minutes
      self.vote_minutes = vote_minutes_m.to_i + (vote_hours_m.to_i * 60) + (vote_days_m.to_i * 24 * 60)
      self.vote_minutes = nil if vote_minutes == 0 # 0 minuti = durata libera (l'utente sceglie)
    end
    self.bad_score = good_score
  end

  # Ricalcola SEMPRE `vote_minutes` dagli accessori UI.
  # Usato nel `before_update`: in edit si assume che l'utente abbia inserito nuovi valori.
  #
  # @return [void]
  def populate_vote!
    self.vote_minutes = vote_minutes_m.to_i + (vote_hours_m.to_i * 60) + (vote_days_m.to_i * 24 * 60)
    self.vote_minutes = nil if vote_minutes == 0 # 0 minuti = durata libera
  end

  def or?
    raise StandardError
  end

  def and?
    raise StandardError
  end

  def time_fixed?
    true # new quora are all time fixed
  end

  def vote_time_set?
    t_vote_minutes == 's'
  end

  def vote_time_free?
    t_vote_minutes == 'f'
  end

  # text to show in the stop cursor of rank bar
  def end_desc
    I18n.l ends_at
  end

  # short description of time left to show in the rank bar and proposals list
  def time_left
    amount = ends_at - Time.zone.now # left in seconds
    if amount > 0
      left = I18n.t('time.left.seconds', count: amount.to_i)
      if amount >= 60 # if more or equal than 60 seconds left give me minutes
        amount_min = amount / 60
        left = I18n.t('time.left.minutes', count: amount_min.to_i)
        if amount_min >= 60 # if more or equal than 60 minutes left give me hours
          amount_hour = amount_min / 60
          left = I18n.t('time.left.hours', count: amount_hour.to_i)
          if amount_hour > 24 # if more than 24 hours left give me days
            amount_days = amount_hour / 24
            left = I18n.t('time.left.days', count: amount_days.to_i)
          end
        end
      end
      left.upcase
    else
      I18n.t('models.quorum.stalled', default: 'STALLED')
    end
  end

  # show the total time of votation
  def vote_time
    case t_vote_minutes
    when 'f'
      I18n.t('models.quorum.free', default: 'free')
    when 's'
      min = vote_minutes if vote_minutes

      if min && min > 0
        if min > 59
          hours = min / 60
          min = min % 60
          if hours > 23
            days = hours / 24
            hours = hours % 24
            min = 0 if hours != 0
            if days > 30
              months = days / 30
              days = days % 30
              min = 0
            end
          end
        end
        ar = []
        ar << I18n.t('time.left.months', count: months) if months && months > 0
        ar << I18n.t('time.left.days', count: days) if days && days > 0
        ar << I18n.t('time.left.hours', count: hours) if hours && hours > 0
        ar << I18n.t('time.left.minutes', count: min) if min && min > 0
        retstr = ar.join(" #{I18n.t('words.and')} ")
      else
        retstr = nil
      end
      retstr
    when 'r'
      'ranged'
    end
  end

  # Verifica se la proposta ha superato il quorum di dibattito e decide la transizione di stato.
  # Chiamato da `ProposalsWorker` allo scadere del timer o forzato manualmente (portavoce).
  #
  # Flusso:
  # - Se rank >= good_score E valutations superate → passa a WAIT o WAIT_DATE (a seconda se la data è già scelta)
  # - Altrimenti → la proposta viene abbandonata e può essere rigenerata con un nuovo quorum
  #
  # @param force_end [Boolean] se true ignora il timer e forza la transizione (usato dai portavoce)
  # @return [void]
  def check_phase(force_end = false)
    return unless force_end || (Time.zone.now > ends_at) # salta se il timer non è ancora scaduto

    vpassed = !valutations || (proposal.valutations >= valutations)
    if (proposal.rank >= good_score) && vpassed # quorum di dibattito superato
      if proposal.vote_defined # the user already chose the votation period! that's great, we can just sit along the river waiting for it to begin
        proposal.proposal_state_id = ProposalState::WAIT
        # automatically create
        if proposal.vote_event_id
          @event = Event.find(proposal.vote_event_id)
        else
          event_p = {
            event_type_id: EventType::VOTATION,
            title: "Votation #{proposal.title}",
            starttime: proposal.vote_starts_at,
            endtime: proposal.vote_ends_at,
            description: "Votation #{proposal.title}",
            user: proposal.users.first
          }
          @event = if proposal.private?
                     proposal.groups.first.events.create!(event_p)
                   else
                     Event.create!(event_p)
                   end
        end
        proposal.vote_period = @event
      else
        proposal.proposal_state_id = ProposalState::WAIT_DATE # we passed the debate, we are now waiting for someone to choose the vote date
        NotificationProposalReadyForVote.perform_later(proposal.id)
      end
      proposal.save
    else
      proposal.abandon
    end
    proposal.reload
  end

  # Chiude la fase di voto e calcola il risultato finale.
  #
  # Per il metodo **Schulze** (più di una soluzione):
  # - Costruisce la stringa di voti nel formato atteso dalla gem `vote-schulze`
  # - Assegna `schulze_score` a ciascuna soluzione in ordine di ID
  # - Proposta ACCEPTED se i voti >= `vote_valutations`, altrimenti REJECTED
  #
  # Per il voto **standard** (binario):
  # - Proposta ACCEPTED se positivi/(positivi+negativi) > soglia percentuale E voti >= `vote_valutations`
  #
  # @return [void]
  # @raise [ActiveRecord::RecordInvalid] se il salvataggio fallisce
  def close_vote_phase
    if proposal.is_schulze?
      vote_data_schulze = proposal.schulze_votes
      Proposal.transaction do
        # Formato atteso da SchulzeBasic: "N=preferenze\n" dove N è il conteggio voti identici
        votesstring = ''
        vote_data_schulze.each do |vote|
          # each row is composed by the vote string and, if more then one, the number of votes of that kind
          votesstring += vote.count > 1 ? "#{vote.count}=#{vote.preferences}\n" : "#{vote.preferences}\n"
        end
        num_solutions = proposal.solutions.count
        vs = SchulzeBasic.do votesstring, num_solutions
        solutions_sorted = proposal.solutions.sort_by(&:id) # order the solutions by the id (as the plugin output the results)
        solutions_sorted.each_with_index do |c, i|
          c.schulze_score = vs.ranking[i].to_i # save the result in the solution
          c.save!
        end
        votes = proposal.schulze_votes.sum(:count)
        proposal.proposal_state_id = votes >= vote_valutations ? ProposalState::ACCEPTED : ProposalState::REJECTED
      end # end of transaction
    else
      vote_data = proposal.vote
      positive = vote_data.positive
      negative = vote_data.negative
      neutral = vote_data.neutral
      votes = positive + negative + neutral
      proposal.proposal_state_id = if ((positive + negative) > 0) && ((positive.to_f / (positive + negative)) > (vote_good_score.to_f / 100)) && (votes >= vote_valutations) # se ha avuto più voti positivi allora diventa ACCETTATA
                                     ProposalState::ACCEPTED
                                   else # se ne ha di più negativi allora diventa RESPINTA
                                     ProposalState::REJECTED
                                   end
    end
    proposal.save!
    NotificationProposalVoteClosed.perform_later(proposal.id)
  end

  def has_bad_score?
    false # new quora does not have bad score
  end

  # Percentuale di avanzamento temporale del dibattito (0-100).
  # Usa `min(Time.now, ends_at)` per non superare 100% anche se il timer è scaduto.
  #
  # @return [Float] valore 0-100
  def debate_progress
    minimum = [Time.zone.now, ends_at].min
    minimum = ((minimum - started_at) / 60)
    percentagetime = minimum.to_f / minutes
    percentagetime * 100
  end

  protected

  # Calcola il numero minimo di partecipanti al dibattito basandosi sulla percentuale del quorum.
  # Per gruppi: usa i partecipanti con permesso `participate_proposals`.
  # Per open space: usa il 0.1% degli utenti totali (fattore ridotto per la scala globale).
  # Aggiunge sempre +1 per garantire che almeno 1 persona partecipi.
  #
  # @return [Integer]
  def min_participants_pop
    percentage_f = percentage.to_f
    count = if group
              percentage_f * 0.01 * group.scoped_participants(:participate_proposals).count
            else
              percentage_f * 0.001 * User.count # 0.1% per open space (scala globale)
            end
    [count, 0].max.floor + 1 # +1 garantisce almeno 1 partecipante
  end

  # Come `min_participants_pop` ma per la fase di voto.
  # Usa il permesso `vote_proposals` che può differire da `participate_proposals`.
  #
  # @return [Integer]
  def min_vote_participants_pop
    vote_percentage_f = vote_percentage.to_f
    count = if group
              vote_percentage_f * 0.01 * group.scoped_participants(:vote_proposals).count
            else
              vote_percentage_f * 0.001 * User.count
            end
    [count, 0].max.floor + 1 # +1 garantisce almeno 1 votante
  end

  def explanation_pop
    []
    ''
    ret = if assigned? # explain a quorum assigned to a proposal
            if proposal_life.present? || proposal.abandoned?
              terminated_explanation_pop
            else
              assigned_explanation_pop
                  end
          else
            unassigned_explanation_pop # it a non assigned quorum
          end

    ret += '.'
    ret.html_safe
  end


  # explain a quorum when assigned to a proposal in it's current state
  def assigned_explanation_pop
    ''
    time = "<b>#{self.time}</b> "
    time += I18n.t('models.quorum.until_date', date: I18n.l(ends_at))
    ret = I18n.translate('models.quorum.time_condition_1', time: time) # display the time left for discussion
    ret += '<br/>'
    participants = I18n.t('models.quorum.participants', count: valutations)
    ret += I18n.translate('models.best_quorum.good_score_condition', good_score: good_score, participants: participants)
    ret
  end

  # explain a quorum in a proposal that has terminated her life cycle
  def terminated_explanation_pop
    ''
    time = "<b>#{self.time(true)}</b> " # show total time if the quorum is terminated
    time += I18n.t('models.quorum.until_date', date: I18n.l(ends_at))
    ret = I18n.translate('models.quorum.time_condition_1_past', time: time) # display the time left for discussion
    ret += '<br/>'
    participants = I18n.t('models.quorum.participants_past', count: valutations)
    ret += I18n.translate('models.best_quorum.good_score_condition_past', good_score: good_score, participants: participants)
    ret
  end

  # explain a non assigned quorum
  def unassigned_explanation_pop
    ''
    time = "<b>#{self.time}</b> "
    ret = I18n.translate('models.quorum.time_condition_1', time: time) # display the time left for discussion
    ret += '<br/>'
    participants = I18n.t('models.quorum.participants', count: min_participants)
    ret += I18n.translate('models.best_quorum.good_score_condition', good_score: good_score, participants: participants)
    ret
  end
end
