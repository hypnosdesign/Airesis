class GroupInvitation < ApplicationRecord
  has_many :group_invitation_emails
  belongs_to :inviter, class_name: 'User', foreign_key: :inviter_id
  belongs_to :group

  before_validation :build_data, on: :create
  validate :invitable_emails_present, on: :create

  attr_accessor :emails_list

  protected

  def build_data
    return unless group

    already_built = group_invitation_emails.map { |invitation_email| invitation_email.email.to_s.downcase }
    normalized_emails.each do |email|
      next if already_built.include?(email)
      next if rejected_email?(email)

      group_invitation_emails.build(email: email)
    end
  end

  def normalized_emails
    emails_list.to_s.split(/[;,\n]/).map { |email| email.strip.downcase }.uniq.grep(URI::MailTo::EMAIL_REGEXP)
  end

  def rejected_email?(email)
    BannedEmail.exists?(['LOWER(email) = ?', email]) ||
      group.group_invitation_emails.exists?(['LOWER(email) = ?', email]) ||
      group.participants.exists?(['LOWER(email) = ?', email])
  end

  def invitable_emails_present
    return if group_invitation_emails.any?

    errors.add(:emails_list, :invalid)
  end
end
