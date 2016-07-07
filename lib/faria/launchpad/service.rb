require 'net/https'
require 'addressable'

module Faria
  module Launchpad
    class Service

      LAUNCHPAD_NAME = "Launchpad"

      def self.noauth(endpoint, quiet: false)
        unless quiet
          puts "************************************************************************\n" \
          "\007\007\007NOTICE: noauth is only intended as a somewhat easy way to call `ping`\n" \
            "and `pubkey`. Nothing else is going to work since keys are required for\n" \
            "general API usage.\n" \
            "************************************************************************\n"
          sleep 2
        end
        new(endpoint, keys: { local: nil, remote: nil }, source: {name: "No one"})
      end

      DEFAULTS = {
        expires_in: 60 # 1 minute
      }

      def initialize(endpoint, options = {})
        @endpoint = endpoint
        @my_key = options[:keys][:local]
        @remote_key = options[:keys][:remote]
        @source = options[:source]
        @app_name = options[:source][:name]

        @options = DEFAULTS.merge(options)
      end

      # utils

      def ping
        get_without_auth "ping"
      end

      def pubkey
        resp = raw_get_without_auth("pubkey")
        return resp.body if resp.code == '200'
      end

      # utils requiring auth

      def info
        get "info"
      end

      def echo(params={})
        put "echo", params
      end

      # sessions

      def retrieve_session(session_id, params = {})
        get "authentication_sessions/#{session_id}", params
      end

      # data is intended to be JSON encoded data if passed
      def approve_session(session_id, data = {})
        params = data.empty? ? {} : { data: data }
        post "authentication_sessions/#{session_id}/approve", params
      end

      # data is intended to be JSON encoded data if passed
      def decline_session(session_id, data = {})
        params = data.empty? ? {} : { data: data }
        post "authentication_sessions/#{session_id}/decline", params
      end

      # identities

      def show_identity(uuid)
        get "identities/#{uuid}"
      end

      def update_identity(identity_representation, uuid)
        patch "identities/#{uuid}", identity: identity_representation
      end

      # by_value allows the unique pairing value to be used to perform
      # queries or updates instead of Launchpad's internal UUID
      def show_identity_by_pairing_value(pairing_value)
        get "identities/by_pairing_value/#{pairing_value}"
      end

      def update_identity_by_pairing_value(identity_representation, pairing_value)
        patch "identities/by_pairing_value/#{pairing_value}", identity: identity_representation
      end

      # final provisioning step (server side)
      def provision(params = {})
        raise "you need an :approval_code" if params[:approval_code].blank?
        raise "you need an :identity" if params[:identity].blank?

        post("pairing/provision", params)
      end

      # direct methods (for undocumented api?)

      def post(url, params = {})
        resp = raw_request(:post, url, params)
        parse_response(resp)
      end

      def get(url, params = {})
        resp = raw_request(:get, url, params)
        parse_response(resp)
      end

      def put(url, params = {})
        resp = raw_request(:put, url, params)
        parse_response(resp)
      end

      def patch(url, params = {})
        resp = raw_request(:patch, url, params)
        parse_response(resp)
      end

      def parse_response(resp)
        hash = JSON.parse(resp.body)
        # be railsy if we can
        hash = hash.with_indifferent_access if hash.respond_to?(:with_indifferent_access)
        hash
      rescue JSON::ParserError
        raise JSON::ParserError, resp.body
      end

      # lower-level HTTP code

      def get_without_auth(url, params={})
        parse_response raw_get_without_auth(url, params)
      end

      def raw_get_without_auth(url, params={})
        uri = full_url(url)
        Net::HTTP.get_response(URI(uri))
      end

      def raw_request(verb, url, params = {})
        uri = full_url(url)
        a = Addressable::URI.parse(uri)
        Net::HTTP.start(a.host, a.inferred_port) do |http|
          http.use_ssl = a.scheme == 'https'
          # http.verify_mode = OpenSSL::SSL::VERIFY_NONE
          request = verb_to_http_class(verb).new a.request_uri
          payload = encrypt_payload(params, a)
          if verb == :get
            request['Faria-JWE'] = payload
          else
            request['Content-Type'] = "application/jwe"
            request.body = payload
          end
          http.request request
        end
      end

      # url helpers

      def pairing_request_url
        rooted_url "third/pairing/request"
      end

      def pairing_complete_url
        rooted_url "third/pairing/complete"
      end

      private

      VALID_VERBS = %w(get put patch post get delete)

      # can't guarantee we have Rails or AS so we use eval vs
      # constantize/classify, etc
      def verb_to_http_class(verb)
        raise "#{verb} is not a valid HTTP verb." unless VALID_VERBS.include?(verb.to_s)

        Net::HTTP.const_get(verb.to_s.capitalize)
      end

      def encrypt_payload(params, address)
        Faria::Launchpad::Packet.encrypt(
          params,
          {
            api_url: address.normalize.to_s,
            source: @source,
            expires_in: @options[:expires_in]
          },
          remote_key: @remote_key,
          local_key: @my_key
        )
      end

      def rooted_url(url)
        File.join(base_url(@endpoint), url)
      end

      def base_url(url)
        url.gsub(%r{/api/v[^/]+/$},"")
      end

      def full_url(url)
        File.join(@endpoint, url)
      end

    end
  end
end
