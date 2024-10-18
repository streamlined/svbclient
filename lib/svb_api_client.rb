# Encoding: utf-8

##
# client.rb
#
# See for the full documentation https://developer.svb.com/apis/docs-home.
# Email apisupport@svb.com for help.
#

require 'json'
require 'openssl'
require 'base64'
require 'net/https'
require 'uri'

require_relative 'detached_jwt'
require_relative 'api/account_balance'
require_relative 'api/account_transfer'
require_relative 'api/ach'

module SVB
  module API
    class Client
      include AccountBalance
      include AccountTransfer
      include ACH

      def initialize(client_id:, client_secret:, base_url: 'https://uat.api.svb.com')
        @client_id = client_id
        @client_secret = client_secret
        @base_url = base_url
      end

      def get_bearer_token(scope)
        uri = URI.parse(@base_url + '/v1/security/oauth/token')
        request = Net::HTTP::Post.new(uri)
        request.content_type = "application/x-www-form-urlencoded"
        access_token = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

        request["Authorization"] = "Basic #{access_token}"

        request.set_form_data(grant_type: "client_credentials", scope: scope)

        response = send_request(uri, request)

        data = JSON.parse(response.body)
        case response.code.to_i
        when 200
          data["access_token"]
        else
          raise SVB::API::ClientError.new({
                                  code: response.code,
                                  status_text: data["error"] || response.message,
                                  message: data["error_description"] || "An error occurred",
                                  error_uri: data["error_uri"]
                                })
        end
      rescue JSON::ParserError
        raise SVB::API::ClientError.new({
                                code: 500,
                                status_text: "JSON::ParserError",
                                message: "Invalid JSON response"
                              })
      end

      def post(path:, body:, scope:)
        make_request(:post, path: path, body: body, scope: scope)
      end

      def get(path:, scope:)
        make_request(:get, path: path, scope: scope)
      end

      def patch(path:, body:, scope:)
        make_request(:patch, path: path, body: body, scope: scope)
      end

      def make_request(method, path:, body: nil, scope:)
        access_token = get_bearer_token(scope)

        raise SVB::API::ClientError.new("Invalid access token") unless access_token && access_token.is_a?(String)

        uri = URI.parse(@base_url + path)
        request = create_request(method, uri)

        request = set_request_headers(request, access_token)
        if body
          request.body = body.is_a?(Hash) || body.is_a?(Array) ? body.to_json : body
          request = set_jwt_headers(request, body)
        end

        response = send_request(uri, request)
        response_builder(response)
      end

      private

      def create_request(method, uri)
        case method
        when :get
          Net::HTTP::Get.new(uri)
        when :post
          Net::HTTP::Post.new(uri)
        when :patch
          Net::HTTP::Patch.new(uri)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      def set_request_headers(request, access_token)
        request.content_type = "application/json"
        request["Authorization"] = "Bearer #{access_token}"
        request
      end

      def set_jwt_headers(request, payload)
        detached_jwt = DetachedJwt.generate_detached_jwt(payload, @client_secret)
        request['x-jws-signature'] = detached_jwt
        request
      end

      def send_request(uri, request)
        req_options = { use_ssl: uri.scheme == "https" }
        Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
          http.request(request)
        end
      rescue SocketError, Timeout::Error => e
        raise SVB::API::ClientError.new({
                                code: 500,
                                status_text: e.class.name,
                                message: e.message
                              })
      end

      def response_builder(response)
        {
          code: response.code,
          data: JSON.parse(response.body),
        }
      end
    end

    # Custom error class for client errors
    class ClientError < StandardError
      attr_reader :code, :status_text, :message, :error_uri

      def initialize(error_data)
        @code = error_data[:code]
        @status_text = error_data[:status_text]
        @message = error_data[:message]
        @error_uri = error_data[:error_uri]
        super("#{@status_text}: #{@message}")
      end

      def to_h
        {
          code: @code,
          status_text: @status_text,
          message: @message,
          error_uri: @error_uri
        }
      end
    end
  end
end
