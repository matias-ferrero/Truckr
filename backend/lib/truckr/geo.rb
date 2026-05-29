# frozen_string_literal: true

module Truckr
  # Geo — pure-function geographic helpers.
  #
  # Haversine in Ruby is deliberate, not a fallback: per CLAUDE.md "Database
  # policy" the product runs SQLite forever and never adopts PostGIS. Distance
  # filtering and ordering must happen in application code.
  module Geo
    EARTH_RADIUS_KM   = 6371.0
    KM_PER_LAT_DEGREE = 111.0

    module_function

    # Great-circle distance in kilometres between two [lat, lng] points
    # using the Haversine formula. Points are expressed in decimal degrees.
    def haversine_km(point_a, point_b)
      lat1, lng1 = point_a
      lat2, lng2 = point_b
      d_lat = to_rad(lat2 - lat1)
      d_lng = to_rad(lng2 - lng1)
      a = (Math.sin(d_lat / 2)**2) +
          (Math.cos(to_rad(lat1)) * Math.cos(to_rad(lat2)) *
           (Math.sin(d_lng / 2)**2))
      EARTH_RADIUS_KM * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    end

    # Axis-aligned bounding box covering every point within `radius_km` of
    # the anchor [lat, lng]. Returns [min_lat, max_lat, min_lng, max_lng] in
    # decimal degrees. Used as a cheap SQL prefilter before the Haversine
    # pass in TransportWindow.within_bbox_of.
    #
    # Latitude span is ~111 km/° everywhere; longitude span shrinks toward the
    # poles, so it is widened by 1 / cos(lat_radians). At Ushuaia (~54°S) the
    # widening is ~1.7× — necessary for the bbox to actually contain the disk.
    def bbox_for(lat, lng, radius_km)
      lat_delta = radius_km / KM_PER_LAT_DEGREE
      cos_lat   = Math.cos(to_rad(lat)).abs
      cos_lat   = 1e-6 if cos_lat < 1e-6
      lng_delta = (radius_km / KM_PER_LAT_DEGREE) / cos_lat
      [ lat - lat_delta, lat + lat_delta, lng - lng_delta, lng + lng_delta ]
    end

    def to_rad(deg) = deg * Math::PI / 180
  end
end
