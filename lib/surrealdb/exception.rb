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
end
