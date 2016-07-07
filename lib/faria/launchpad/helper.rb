module Faria
  module Launchpad

    # Rails helper for generating encrypted POST redirect forms
    module Helper

      def post_encrypted_redirect_to(url, payload)
        [
          "<noscript>Your browser has Javascript disabled, please enable it.</noscript>".html_safe,
          form_tag(url, authenticity_token: false, id: "frm"),
          hidden_field_tag("content_type", "application/jwe"),
          hidden_field_tag("payload", payload),
          # submit_tag("submit"),
          "</form>".html_safe,
          javascript_tag("document.getElementById('frm').submit();")
        ].join("\n").html_safe
      end

    end
  end
end
