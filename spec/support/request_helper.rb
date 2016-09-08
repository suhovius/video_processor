module Requests
  module JsonHelpers
    def json
      JSON.parse(last_response.body)
    end

    def http_status_for(symbol)
      ::Rack::Utils::SYMBOL_TO_STATUS_CODE[symbol]
    end
  end
end
