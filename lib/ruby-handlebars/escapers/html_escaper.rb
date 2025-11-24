require 'cgi'

module Handlebars
  module Escapers
    class HTMLEscaper
      def self.escape(value)
        if value.is_a?(SafeString)
          value.to_s
        else
          CGI::escapeHTML(value.to_s)
        end
      end
    end
  end
end
