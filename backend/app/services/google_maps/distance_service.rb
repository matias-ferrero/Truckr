# frozen_string_literal: true

require "net/http"
require "json"

module GoogleMaps
  module DistanceService
    API_URL    = "https://routes.googleapis.com/directions/v2:computeRoutes"
    FIELD_MASK = "routes.distanceMeters"

    def self.fetch_km(origin_lat, origin_lng, dest_lat, dest_lng)
      api_key = ENV["GOOGLE_MAPS_API_KEY"]
      return nil unless api_key.present?

      uri  = URI(API_URL)
      body = {
        origin:      { location: { latLng: { latitude: origin_lat, longitude: origin_lng } } },
        destination: { location: { latLng: { latitude: dest_lat,   longitude: dest_lng   } } },
        travelMode:               "DRIVE",
        routingPreference:        "TRAFFIC_UNAWARE",
        computeAlternativeRoutes: false
      }.to_json

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"]     = "application/json"
      request["X-Goog-Api-Key"]   = api_key
      request["X-Goog-FieldMask"] = FIELD_MASK

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                                  open_timeout: 5, read_timeout: 5) do |http|
        http.request(request, body)
      end

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.warn("[DistanceService] HTTP #{response.code} from Routes API")
        return nil
      end

      data            = JSON.parse(response.body)
      distance_meters = data.dig("routes", 0, "distanceMeters")

      if distance_meters.nil?
        Rails.logger.warn("[DistanceService] no route in response, body=#{response.body.truncate(500)}")
        return nil
      end

      (distance_meters.to_f / 1000).round(2)
    rescue StandardError => e
      Rails.logger.warn("[DistanceService] #{e.class}: #{e.message}")
      nil
    end
  end
end
