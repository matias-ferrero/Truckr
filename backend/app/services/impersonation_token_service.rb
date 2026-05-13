# frozen_string_literal: true

# Mints a devise-jwt-compatible JWT for `user`, signed with the same secret
# the warden-jwt-auth dispatcher uses, so the token validates against the
# regular `authenticate_user!` middleware. The `impersonated_by` claim is
# carried for audit/UI purposes; logout in the frontend skips the revoke
# call when this claim is present so an impersonation session can't rotate
# the real user's JTI and kick them out.
class ImpersonationTokenService
  EXPIRATION = 1.hour

  def initialize(user, admin_user)
    @user = user
    @admin_user = admin_user
  end

  def call
    JWT.encode(build_payload, Warden::JWTAuth.config.secret, "HS256")
  end

  private

  def build_payload
    now = Time.now.to_i
    {
      sub:             @user.id.to_s,
      scp:             "user",
      jti:             @user.jti,
      iat:             now,
      exp:             now + EXPIRATION.to_i,
      impersonated_by: @admin_user.email
    }
  end
end
