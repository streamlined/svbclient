require 'jwt'
require 'securerandom'

class DetachedJwt
  def self.generate_detached_jwt(payload, secret)
    headers = {
      kid: SecureRandom.uuid,
      typ: 'JOSE',
      alg: 'HS256'
    }

    token = JWT.encode(payload, secret, 'HS256', headers)
    parts = token.split('.')
    "#{parts[0]}..#{parts[2]}"
  end
end