# frozen_string_literal: true

# User — auth account. A User MAY have a Carrier profile, a Shipper profile,
# or neither. Role state is derived from the relation rows — there are
# NO is_carrier / is_shipper columns on this table (ADR-008).
#
# Auth is provided by Devise (REQ-BE-00023):
# - :database_authenticatable — bcrypt password storage in encrypted_password
# - :registerable             — exposes the registration flow (we wrap it)
# - :validatable              — email format + presence + min password length
#
# Modules deliberately omitted: confirmable, recoverable, trackable, lockable,
# timeoutable, rememberable, omniauthable. See plan Decision A.
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :validatable,
         password_length: 8..128

  has_one :carrier, dependent: :destroy
  has_one :shipper, dependent: :destroy

  before_validation :canonicalise_email

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
end
