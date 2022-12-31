# frozen_string_literal: true

require "net/http"
require "json"

module Surrealdb
  # Represents a http response from a SurrealDB server.
  class SurrealResponse
    attr_reader :table, :data

    def initialize(response)
      @time = response[0][:time]
      @status = response[0][:status]
      result = response[0][:result]
      return if result.empty?

      @table = result[0][:id].split(":")[0]
      data = to_data(result)
      @data = data.length == 1 ? data[0] : data
    end

    def no_data?
      @data.nil?
    end

    private

    def to_data(result)
      result.map do |rec|
        id = rec[:id].split(":")[1]
        rec[:id] = id
        rec
      end
    end
  end
end
