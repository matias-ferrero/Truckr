# frozen_string_literal: true

# Mailer for CargoOffer lifecycle events.
#
# INF-BE-00005 stub: notify_carrier is declared but sends no real email until
# the mailer infrastructure lands. The controller calls .deliver_later inside
# a rescue block so the CargoOffer is created even if this raises.
class CargoOfferMailer < ApplicationMailer
  def notify_carrier(cargo_offer)
    Rails.logger.info("[CargoOfferMailer] stub — sending placeholder email for CargoOffer##{cargo_offer.id} (INF-BE-00005 pending)")
    mail(
      to: cargo_offer.carrier.user.email,
      subject: I18n.t("cargo_offer_mailer.notify_carrier.subject")
    ) do |format|
      format.text { render plain: "CargoOffer ##{cargo_offer.id} received. (stub)" }
    end
  end
end
