# Encoding: utf-8

##
# svb-client.rb
#
# Example of HMAC request signing for use with the SVB API.
# See for the full documentation http://docs.svbplatform.com/authentication/.
# Email apisupport@svb.com for help!
#

require 'json'
require 'openssl'
require 'base64'
require 'net/https'
require 'uri'

class SVBClientV2
  def initialize(client_id, client_secret, base_url: 'https://api.svb.com')
    @client_id = client_id
    @client_secret = client_secret
    @base_url = base_url
  end

  def get_bearer_token(scope: nil)
    uri = URI.parse(@base_url + '/v1/security/oauth/token')
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/x-www-form-urlencoded"
    access_token = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    request["Authorization"] = "Basic #{access_token}"

    request.set_form_data("grant_type" => "client_credentials", "scope" => "accountbalance")
    req_options = {
      use_ssl: uri.scheme == "https"
    }
    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    data = JSON.parse(response.body)
    data["access_token"]
  rescue => e
    error_builder(e)
  end

  def post(path, body, scope)
    access_token = get_bearer_token(scope: scope)
    auth_header = "Bearer #{access_token}"

    uri = URI.parse(@base_url + "/v1/accounts/balances")
    request = Net::HTTP::Post.new(uri)
    request.content_type = "application/json"

    request["Authorization"] = auth_header
    request.body = body
    req_options = {
      use_ssl: uri.scheme == "https"
    }

    response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
      http.request(request)
    end
    response_builder(response)
  end

  def error_builder(error)
    {
      code: error.http_code,
      status_text: error.message,
      message: JSON.parse(error.response)
    }
  end

  def response_builder(response)
    {
      code: response.code,
      data: JSON.parse(response.body),
    }
  end
end

class SVBClientV2::AccountBalance
  def initialize(client)
    raise 'provide an API client' if client.nil?
    @client = client
  end

  def get_account_balance(account_number)
    body = {account: account_number}.to_json
    @client.post("/v1/accounts/balances", body, 'accountbalance')
  end
end


