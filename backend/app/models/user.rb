# frozen_string_literal: true

# User — auth account. A User MAY have a Carrier profile, a Shipper profile,
# or neither. Role state is derived from the relation rows — there are
# NO is_carrier / is_shipper columns on this table (ADR-008).
#
# Auth is provided by Devise (REQ-BE-00023, REF-BE-00001 / ADR-011):
# - :database_authenticatable — bcrypt password storage in encrypted_password
# - :registerable             — exposes the registration flow (we wrap it)
# - :validatable              — email format + presence + min password length
# - :jwt_authenticatable      — stateless JWT auth via devise-jwt; revocation
#                               is delegated to JTIMatcher (this class itself)
#
# Modules deliberately omitted: confirmable, recoverable, trackable, lockable,
# timeoutable, rememberable, omniauthable. See plan Decision A.
class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher

  devise :database_authenticatable, :registerable, :validatable,
         :jwt_authenticatable,
         jwt_revocation_strategy: self,
         password_length: 8..128

  has_one :carrier, dependent: :destroy
  has_one :shipper, dependent: :destroy

  VALID_ROLES = %w[carrier shipper].freeze

  before_validation :canonicalise_email
  before_save :clear_verified_at_on_email_change
  before_create :set_jti

  validates :email,
            presence: true,
            uniqueness: { case_sensitive: false },
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # Devise's :validatable already enforces presence + length on password;
  # we layer complexity rules (≥1 upper, ≥1 lower, ≥1 digit) on top.
  validates :password,
            password_complexity: true,
            if: -> { password.present? }

  scope :carriers, -> { joins(:carrier).distinct }
  scope :shippers, -> { joins(:shipper).distinct }

  def carrier? = carrier.present?
  def shipper? = shipper.present?

  # Creates a User and attaches the corresponding role profile in one transaction.
  # Raises ActiveRecord::RecordInvalid if role is not in VALID_ROLES or any
  # validation fails, so callers can rely on rescue_from in BaseController.
  def self.register_with_role!(email:, password:, full_name:, role:)
    role = role.to_s
    unless VALID_ROLES.include?(role)
      dummy = new
      dummy.errors.add(:role, I18n.t("errors.messages.inclusion"))
      raise ActiveRecord::RecordInvalid, dummy
    end
    transaction do
      user = create!(email: email, password: password, full_name: full_name)
      role == "carrier" ? user.create_carrier! : user.create_shipper!
      user
    end
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[id email full_name phone verified_at created_at updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[carrier shipper]
  end

  private

  def canonicalise_email
    self.email = email.to_s.strip.downcase.presence
  end

  def clear_verified_at_on_email_change
    return unless persisted?
    self.verified_at = nil if email != email_in_database
  end

  def set_jti
    self.jti ||= SecureRandom.uuid
  end
end
