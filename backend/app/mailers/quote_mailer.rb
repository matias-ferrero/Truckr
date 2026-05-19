# frozen_string_literal: true

# Mailer for Quote lifecycle events.
#
# INF-BE-00005 stub: notify_carrier is declared but sends no real email until
# the mailer infrastructure lands. The controller calls .deliver_later inside a
# rescue block so the Quote is created even if this raises.
class QuoteMailer < ApplicationMailer
  def notify_carrier(quote)
    Rails.logger.info("[QuoteMailer] stub — sending placeholder email for Quote##{quote.id} (INF-BE-00005 pending)")
    mail(
      to: quote.carrier.user.email,
      subject: I18n.t("quote_mailer.notify_carrier.subject")
    ) do |format|
      format.text { render plain: "Quote ##{quote.id} received. (stub)" }
    end
  end
end
