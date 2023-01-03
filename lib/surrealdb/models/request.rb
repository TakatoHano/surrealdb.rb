# frozen_string_literal: true

require "net/http"
require "json"

module Surrealdb
  # Represents a http response from a SurrealDB server.
  module RPCRequest
    @current_id = 0

    def new(method, params = [])
      {
        id: generate_id,
        method:,
        params:
      }
    end

    def self.generate_id
      id = @current_id % (2**32)
      @current_id += 1

      id.to_s
    end

    module_function :new
  end
end
