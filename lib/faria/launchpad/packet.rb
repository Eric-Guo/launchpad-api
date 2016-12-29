require 'jwe'
require 'jwt'
require 'json'
require 'addressable'

module Faria
  module Launchpad
    module Packet

      VERSION = "v0.2"

      class MismatchedRequestURL < StandardError
      end

      class MissingRemoteKey < StandardError
      end

      class ExpiredSignature < StandardError
        attr_accessor :expired_by
        def initialize(msg, expired_by)
          super(msg)
          @expired_by = expired_by
        end
      end

      # encrypting is done with LaunchPad public key
      # signing is done with local private key

      def self.encrypt(data, options = {}, local_key:, remote_key: )
        packet = { "data" => data}
        packet = add_issued_at(packet)
        packet = add_expires(packet, options[:expires_in]) if options[:expires_in]
        packet = add_api_url(packet, options[:api_url]) if options[:api_url]
        # packet = add_issuer(packet, options[:issuer])
        packet = add_source(packet, options[:source]) if options[:source]

        payload = JWT.encode(packet, local_key, 'RS512')
        "#{VERSION};" + JWE.encrypt(payload, remote_key) # public
      end

      # for cases where you known in advance the remote key to use (such
      # as LaunchPad clients which will only be receiving messages from
      # LaunchPad and therefore will only use it's public key for verifying
      # signatures
      def self.decrypt(raw_data, options = {}, local_key:, remote_key: )
        version, jwe = raw_data.split(";", 2)
        jwt = JWE.decrypt(jwe, local_key)
        arr = JWT.decode(jwt, remote_key, true, { :algorithm => 'RS512' })
        payload, header = arr

        # validate_expiration will be handled by JWT decode
        validate_url!(payload, options[:actual_url])

        payload["data"]
      end

      # for cases where the signature key is not known in advance and must
      # be determined by source information embedded in the JWT header
      def self.decrypt_variable_key(raw_data, options = {}, local_key:, remote_key_func: )
        version, jwe = raw_data.split(";", 2)
        jwt = JWE.decrypt(jwe, local_key)
        header, payload = JWT::Decode.new(jwt, nil, false, {}).decode_segments[0..1]
        remote_key = remote_key_func.call(header, payload)
        fail(MissingRemoteKey) if remote_key.nil?

        arr = JWT.decode(jwt, remote_key, true, { :algorithm => 'RS512' })
        payload, header = arr

        # validate_expiration will be handled by JWT decode
        validate_url!(payload, options[:actual_url])

        payload["data"]
      end

      private

      def self.add_source(packet, source)
        packet[:faria_source] = source
        packet
      end

      def self.add_issuer(packet, issuer)
        packet[:iss] = issuer
        packet
      end

      def self.add_api_url(packet, url)
        packet["api_url"] = Addressable::URI.parse(url).normalize.to_s
        packet
      end

      def self.add_issued_at(packet)
        packet[:iat] = Time.now.utc.to_i
        packet
      end

      def self.add_expires(packet, expires_in)
        packet[:exp] = Time.now.utc.to_i + expires_in
        packet
      end

      def self.validate_url!(payload, actual_url)
        return unless payload.include?('api_url')

        normalized_url = Addressable::URI.parse(actual_url).normalize.to_s
        if payload['api_url'] != normalized_url
          fail(MismatchedRequestURL)
        end
      end

      def self.validate_expiration!(payload)
        return unless payload.include?('exp')
        leeway = 0

        valid_until = (Time.now.utc.to_i - leeway)
        if payload['exp'].to_i < valid_until
          diff = valid_until - payload['exp'].to_i
          error = ExpiredSignature.new("Signature expired", diff)
          fail(error)
        end
      end

    end
  end
end
