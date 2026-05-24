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

  def notify_shipper_offer_accepted(cargo_offer)
    @cargo_offer = cargo_offer
    @cargo = cargo_offer.cargo

    mail(
      to: @cargo.shipper.user.email,
      subject: I18n.t("cargo_offer_mailer.notify_shipper_offer_accepted.subject")
    ) do |format|
      format.text do
        render plain: "Cargo ##{@cargo.id} has an accepted offer. Continue payment at /cargos/#{@cargo.id}/pay"
      end
    end
  end

  def notify_shipper_offer_rejected(cargo_offer)
    @cargo_offer = cargo_offer
    @cargo = cargo_offer.cargo

    mail(
      to: @cargo.shipper.user.email,
      subject: I18n.t("cargo_offer_mailer.notify_shipper_offer_rejected.subject")
    ) do |format|
      format.text do
        render plain: "CargoOffer ##{cargo_offer.id} for Cargo ##{@cargo.id} was rejected."
      end
    end
  end
end
