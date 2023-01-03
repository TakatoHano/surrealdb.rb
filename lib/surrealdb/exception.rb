# frozen_string_literal: true

module Surrealdb
  # Base exception for SurrealDB client library.
  class SurrealException < StandardError
    def initialize(error)
      code = error[:code]
      details = error[:details]
      description = error[:description]
      super("#{code} #{details}: #{description}")
    end
  end

  # Base exception for SurrealDB client library.
  class RPCError < StandardError
    attr_reader :code

    SAFETY_CODES = [-32_602, -32_000].freeze

    def initialize(error)
      @code = error[:code]
      message = error[:message]
      super("#{@code}: #{message}")
    end

    def critical?
      SAFETY_CODES.none?(@code)
    end
  end
end
