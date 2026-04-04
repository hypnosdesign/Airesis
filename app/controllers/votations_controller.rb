class VotationsController < ApplicationController
  include RotpModule

  layout 'open_space'

  before_action :authenticate_user!

  def vote
    Proposal.transaction do
      @proposal = Proposal.find(params[:proposal_id])
      authorize! :vote, @proposal

      return unless validate_security_token

      vote_type = VoteType.find(params[:data][:vote_type].to_i)

      user_vote = @proposal.user_votes.build(user: current_user)
      user_vote.vote_type = vote_type unless @proposal.secret_vote

      if vote_type.id == VoteType::POSITIVE
        @proposal.vote.positive += 1
      elsif vote_type.id == VoteType::NEGATIVE
        @proposal.vote.negative += 1
      elsif vote_type.id == VoteType::NEUTRAL
        @proposal.vote.neutral += 1
      end
      @proposal.vote.save!
      @proposal.save!
      flash[:notice] = t('votations.create.confirm')
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to votation_path }
      end
    end
  rescue ActiveRecord::ActiveRecordError => e
    Rails.logger.error(e.message)
    Rails.logger.error(e.backtrace.join("\n"))
    Rails.logger.error("Error while creating a Vote.
Proposal errors: #{@proposal.errors.details},
Vote errors: #{@proposal.vote.errors.details}")
    if @proposal.errors[:user_votes]
      flash[:error] = t('errors.votation.already_voted')
      respond_to do |format|
        format.turbo_stream { render 'votations/errors/vote_error' }
        format.html { redirect_to votation_path }
      end
    end
  end

  def vote_schulze
    Proposal.transaction do
      @proposal = Proposal.find(params[:proposal_id])
      authorize! :vote, @proposal

      return unless validate_security_token

      votestring = params[:data][:votes]
      solutions = votestring.split(/;|,/).map(&:to_i).sort
      p_sol = @proposal.solutions.pluck(:id).sort
      unless (p_sol <=> solutions) == 0
        raise StandardError
      end

      schulz = @proposal.schulze_votes.find_by(preferences: votestring)
      if schulz
        schulz.count += 1
        schulz.save!
      else
        schulz = @proposal.schulze_votes.build(preferences: votestring, count: 1)
      end
      vote = @proposal.user_votes.build(user_id: current_user.id)
      vote.vote_schulze = votestring unless @proposal.secret_vote
      @proposal.save!
    end
    respond_to do |format|
      flash[:notice] = t('votations.create.confirm')
      format.turbo_stream { render 'votations/vote_schulze' }
      format.html { render action: :show }
    end
  rescue Exception => e
    respond_to do |format|
      flash[:error] = t('errors.messages.votation')
      format.turbo_stream { render 'votations/errors/vote_error' }
      format.html { redirect_to @proposal }
    end
  end

  protected

  def validate_security_token
    return true unless current_user.rotp_enabled && ::Configuration.rotp
    return true if check_token(current_user, params[:data][:token])

    flash[:error] = t('errors.messages.invalid_token')
    respond_to do |format|
      format.turbo_stream { render 'votations/errors/vote_error' }
    end
    false
  end
end
