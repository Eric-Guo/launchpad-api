require 'active_support/concern'

module Faria
  module Launchpad

    # module to include in Rails controllers to make sending/receiving
    # of JWE signed/encrypted packets much simpler
    module Controller
      extend ActiveSupport::Concern

      # class_methods do
      module ClassMethods
        def launchpad_config(config=nil)
          return @launchpad_config if config.nil?

          @launchpad_config = config
        end
      end

      included do
        helper Faria::Launchpad::Helper
      end

      private

      def handle_jwe_payload(request)
        if request.content_type == "application/jwe"
          packet = request.body.read()
        elsif params[:payload].present? && params[:content_type] == "application/jwe"
          packet = params[:payload]
        else
          packet = request.headers["Faria-JWE"]
        end
        return unless packet.present?
        logger.info "packet is #{packet}"

        keys = self.class.launchpad_config.keys
        data = Faria::Launchpad::Packet.decrypt(
          packet,
          { actual_url: request.original_url },
          local_key: keys[:local],
          remote_key: keys[:remote]
        )

        if request.post? || request.put?
          Rails.logger.info "  Parameters (JWT): #{data.inspect}"
          data.with_indifferent_access
        else
          params.except(:controller, :action)
        end
      end

      def post_encrypted_redirect_to(url, params = {})
        config = self.class.launchpad_config

        uri = Addressable::URI.parse(url)
        params = (uri.query_values || {}).merge(params)
        uri.query_values = nil

        payload = Faria::Launchpad::Packet.encrypt(
          params,
          {
            api_url: uri.normalize.to_s,
            source: config.source,
            expires_in: 60
          },
          local_key: config.keys[:local],
          remote_key: config.keys[:remote]
        )

        render html: view_context.post_encrypted_redirect_to(
          uri.normalize.to_s,
          payload
        )
      end

    end
  end
end
