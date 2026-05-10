# frozen_string_literal: true

# Enforces password complexity rules: ≥1 uppercase, ≥1 lowercase, ≥1 digit.
# Length (≥8) is enforced via a separate validates :length on the model.
#
# Error messages live in config/locales/{en,es}.yml under
# `errors.messages.password_complexity.*`.
class PasswordComplexityValidator < ActiveModel::EachValidator
  RULES = {
    upper: /[A-Z]/,
    lower: /[a-z]/,
    digit: /\d/
  }.freeze

  def validate_each(record, attribute, value)
    return if value.blank?

    RULES.each do |key, regex|
      next if value.match?(regex)

      record.errors.add(attribute, :"password_complexity_#{key}",
                        message: I18n.t("errors.messages.password_complexity.#{key}"))
    end
  end
end
