# Quorum legacy (precedente a `BestQuorum`) con logica OR/AND tra condizioni di tempo e partecipanti.
#
# A differenza di `BestQuorum`, `OldQuorum` supporta:
# - Condizione **OR**: il quorum è soddisfatto se scade il tempo OPPURE raggiunge i partecipanti
# - Condizione **AND**: richede entrambe le condizioni
# - Punteggio negativo (`bad_score`) diverso da quello positivo (`good_score`)
#   → una proposta può essere abbandonata se scende sotto `bad_score`
#
# `OldQuorum` è ancora in uso per le proposte create con il vecchio sistema.
# I nuovi quorum usano `BestQuorum` (sempre OR implicito, nessun bad_score distinto).
class OldQuorum < Quorum
  validate :minutes_or_percentage
  validates :condition, inclusion: { in: %w[OR AND] }

  # Almeno uno tra tempo (days/hours/minutes) e percentuale deve essere specificato.
  # Senza questo vincolo si creerebbe un quorum che non può mai terminare.
  def minutes_or_percentage
    errors.add(:minutes, 'Devi indicare la durata della proposta o il numero minimo di partecipanti') if days_m.blank? && hours_m.blank? && minutes_m.blank? && !percentage && !minutes
  end

  # @return [Boolean] true se la condizione è OR (scadenza tempo O raggiungimento partecipanti)
  def or?
    condition&.casecmp('OR')&.zero?
  end

  # @return [Boolean] true se la condizione è AND (scadenza tempo E raggiungimento partecipanti)
  def and?
    condition&.casecmp('AND')&.zero?
  end

  # Un quorum è "time_fixed" (durata definita) se ha i minuti impostati, nessuna percentuale,
  # e il bad_score è uguale al good_score o non definito.
  # Usato per decidere se schedulare automaticamente le notifiche di scadenza.
  #
  # @return [Boolean]
  def time_fixed?
    minutes && !percentage && ((good_score == bad_score) || !bad_score)
  end

  # text to show in the stop cursor of rank bar
  def end_desc
    conds = []
    conds << "#{I18n.l ends_at} " if ends_at
    conds << " #{I18n.t('pages.proposals.new_rank_bar.valutations', count: valutations)}" if valutations
    conds.join(or? ? I18n.t('words.or') : I18n.t('words.and'))
  end

  # short description of time left
  def time_left
    ret = []
    if ends_at
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
        ret << left.upcase
      end
    end
    if valutations
      valutations = self.valutations - proposal.valutations
      ret << I18n.t('pages.proposals.new_rank_bar.valutations', count: valutations) if valutations > 0
    end
    if !ret.empty?
      ret.join(or? ? " #{I18n.t('words.or').upcase} " : " #{I18n.t('words.and').upcase} ")
    else
      I18n.t('models.quorum.stalled', default: 'STALLED')
    end
  end

  # Verifica se la proposta ha superato il quorum con logica OR/AND.
  # A differenza di `BestQuorum#check_phase`, gestisce tre esiti:
  # - rank >= good_score → WAIT o WAIT_DATE (transizione a votazione)
  # - rank < bad_score   → ABANDONED (proposta abbandonata)
  # - bad_score <= rank < good_score → nessuna azione, il dibattito continua
  #
  # @param force_end [Boolean] se true ignora il timer e forza la valutazione
  # @return [void]
  def check_phase(force_end = false)
    proposal = self.proposal
    passed = false
    timepassed = (!ends_at || Time.zone.now > ends_at)
    vpassed = (!valutations || proposal.valutations >= valutations)
    # Valuta la condizione OR/AND solo se entrambi i parametri sono definiti.
    # Se uno solo è definito, basta che quell'uno sia vero (l'altro è sempre true per default).
    if ends_at && valutations
      if or?
        passed = (timepassed || vpassed)
      else
        and?
        passed = (timepassed && vpassed)
      end
    else # solo uno dei due parametri è definito: l'altro è true per default
      passed = (timepassed && vpassed)
    end
    passed ||= force_end # forzatura da portavoce o job amministrativo

    if passed
      if proposal.rank >= good_score # quorum di dibattito superato
        if proposal.vote_defined # l'utente ha già scelto il periodo di votazione
          proposal.proposal_state_id = ProposalState::WAIT
          # automatically create
          if proposal.vote_event_id
            @event = Event.find(proposal.vote_event_id)
          else
            event_p = {
              event_type_id: EventType::VOTATION,
              title: "Votazione #{proposal.title}",
              starttime: proposal.vote_starts_at,
              endtime: proposal.vote_ends_at,
              description: "Votazione #{proposal.title}"
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

        # remove the timer if is still there
        proposal.save

      elsif proposal.rank < bad_score # if we have not passed the debate quorum abandon it
        proposal.abandon
      else # if we are between bad and good score just do nothing...continue the debate
        return
      end
      proposal.reload
    end
  end

  def close_vote_phase
    if proposal.is_schulze?
      vote_data_schulze = proposal.schulze_votes
      Proposal.transaction do
        votesstring = '' # this is the string to pass to schulze library to calculate the score
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
        proposal.proposal_state_id = ProposalState::ACCEPTED
      end # end of transaction
    else
      vote_data = proposal.vote
      positive = vote_data.positive
      negative = vote_data.negative
      neutral = vote_data.neutral
      positive + negative + neutral
      if positive > negative # se ha avuto più voti positivi allora diventa ACCETTATA
        proposal.proposal_state_id = ProposalState::ACCEPTED
      elsif positive <= negative # se ne ha di più negativi allora diventa RESPINTA
        proposal.proposal_state_id = ProposalState::REJECTED
      end
    end
    proposal.save!
    NotificationProposalVoteClosed.perform_later(proposal.id)
  end

  def has_bad_score?
    bad_score && (bad_score != good_score)
  end

  # Percentuale di avanzamento del dibattito tenendo conto della condizione OR/AND.
  # - OR: prende il MAX tra le percentuali (basta che una condizione stia per essere soddisfatta)
  # - AND: prende il MIN (entrambe le condizioni devono essere soddisfatte)
  # Usa `min(now, ends_at)` e `min(valutations_correnti, valutations_richieste)` per non superare 100%.
  #
  # @return [Float, nil] 0-100 o nil se nessuna condizione è definita
  def debate_progress
    percentages = []
    if valutations
      minimum = [proposal.valutations, valutations].min
      percentagevals = minimum.to_f / valutations
      percentagevals *= 100
      percentages << percentagevals
    end
    if minutes
      minimum = [Time.zone.now, ends_at].min
      minimum = ((minimum - started_at) / 60)
      percentagetime = minimum.to_f / minutes
      percentagetime *= 100
      percentages << percentagetime
    end

    if or?
      percentages.max # OR: il progresso è il massimo tra le due condizioni
    else
      percentages.min # AND: il progresso è limitato dalla condizione più lenta
    end
  end

  protected

  def min_participants_pop
    1
    if percentage
      count = if group
                (percentage.to_f * 0.01 * group.scoped_participants(:participate_proposals).count)
              else
                (percentage.to_f * 0.001 * User.count)
              end
      [count, 1].max.floor
    end
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
    ret = ''
    if time_left? # if the quorum has a minimum time and there is still time remaining
      time = "<b>#{self.time}</b> "
      time += I18n.t('models.quorum.until_date', date: I18n.l(ends_at))

      if valutations_left?
        participants = I18n.t('models.quorum.participants', count: valutations)
        ret = if or?
                I18n.translate('models.quorum.or_condition_1', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)
              else # and
                I18n.translate('models.quorum.and_condition_1', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)

              end
      else # only time
        ret = I18n.translate('models.quorum.time_condition_1', time: time) # display the time left for discussion
      end
    elsif valutations_left? # if the quorum has only valutations left
      participants = I18n.t('models.quorum.participants', count: valutations)
      ret = I18n.translate('models.quorum.participants_condition_1',
                           percentage: percentage,
                           participants_num: participants) # display only number of required evaluations
      # stalled

    end
    ret += '<br/>'
    ret += if bad_score && (bad_score != good_score) # if quorum has negative quorum and it is not the same as positive quorum
             I18n.translate('models.quorum.bad_score_explain', good_score: good_score, bad_score: bad_score)
           else # if quorum has negative quorum and it is the same as positive quorum
             I18n.translate('models.quorum.good_score_condition', good_score: good_score)
           end
    ret
  end

  # explain a quorum in a proposal that has temrinated her life cycle
  def terminated_explanation_pop
    ret = ''
    if minutes # if the quorum has a minimum time
      time = "<b>#{self.time(true)}</b> " # show total time if the quorum is terminated
      time += I18n.t('models.quorum.until_date', date: I18n.l(ends_at))
      if percentage
        participants = I18n.t('models.quorum.participants_past', count: valutations)
        ret = if or?
                I18n.translate('models.quorum.or_condition_1_past', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)
              else # and
                I18n.translate('models.quorum.and_condition_1_past', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)
              end
      else # only time
        ret = I18n.translate('models.quorum.time_condition_1_past', time: time) # display the time left for discussion
      end
    else # only valutations
      participants = I18n.t('models.quorum.participants_past', count: valutations)
      ret = I18n.translate('models.quorum.participants_condition_1_past',
                           percentage: percentage,
                           participants_num: participants) # display only number of required evaluations
    end
    ret += '<br/>'
    ret += if bad_score && (bad_score != good_score) # if quorum has negative quorum and it is not the same as positive quorum
             I18n.translate('models.quorum.bad_score_explain_past', good_score: good_score, bad_score: bad_score)
           else # if quorum has negative quorum and it is the same as positive quorum
             I18n.translate('models.quorum.good_score_condition_past', good_score: good_score)
           end
    ret
  end

  # explain a non assigned quorum
  def unassigned_explanation_pop
    ret = ''
    if minutes # if the quorum has a minimum time
      time = "<b>#{self.time}</b> "
      if percentage
        participants = I18n.t('models.quorum.participants', count: min_participants)
        ret = if or?
                I18n.translate('models.quorum.or_condition_1', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)
              else # and
                I18n.translate('models.quorum.and_condition_1', # display number of required evaluations and time left
                               percentage: percentage,
                               time: time,
                               participants_num: participants)
              end
      else # if the quorum has only minimum time of discussion
        ret = I18n.translate('models.quorum.time_condition_1', time: time) # display the time left for discussion
      end
    else # only evaluations
      participants = I18n.t('models.quorum.participants', count: min_participants)
      ret = I18n.translate('models.quorum.participants_condition_1', participants_num: participants) # display number of required evaluations
    end
    ret += '<br/>'
    ret += if bad_score && (bad_score != good_score) # if quorum has negative quorum and it is not the same as positive quorum
             I18n.translate('models.quorum.bad_score_explain', good_score: good_score, bad_score: bad_score)
           else # if quorum has negative quorum and it is the same as positive quorum
             I18n.translate('models.quorum.good_score_condition', good_score: good_score)
           end
    ret
  end
end
