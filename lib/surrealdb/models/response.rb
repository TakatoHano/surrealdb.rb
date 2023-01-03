# frozen_string_literal: true

require "net/http"
require "json"

module Surrealdb
  # Represents a http response from a SurrealDB server.
  class SurrealResponse
    attr_reader :table, :data

    def initialize(response) # rubocop:disable Metrics/AbcSize
      raise Surrealdb::SurrealException, response unless valid?(response)

      @status = response[0][:status]
      @time = response[0][:time]
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

    def valid?(response)
      response.instance_of?(Array)
    end
  end

  # Represents an RPC response from a SurrealDB server.
  class RPCResponse < SurrealResponse
  end

  # Represents an RPC response from a SurrealDB server.
  class QueryRPCResponse < RPCResponse
    def initialize(result)
      return if result.nil?

      super(result)
    end
  end

  # Represents an RPC response from a SurrealDB server.
  class CRUDRPCResponse < RPCResponse
    def initialize(result)
      return if result.nil?

      new_result = [{}]
      new_result[0][:result] = result
      super(new_result)
    end
  end

  # Represents an RPC response from a SurrealDB server.
  class ModifyRPCResponse < RPCResponse
    def initialize(result)
      return if result.nil?

      data = to_data(result)
      @data = data.length == 1 ? data[0] : data
      super([{ result: [] }])
    end

    def no_change?
      no_data? || @data.all?(nil)
    end

    private

    def to_data(result)
      result.map do |rec|
        rec[0]
      end
    end
  end
end
