# frozen_string_literal: true

require_relative "client/http"
require_relative "client/ws"

module Surrealdb
  # Client for surrealsb
  module Client
    def self.http_client(host, port, namespace, database, username, password) # rubocop:disable Metrics/ParameterLists
      url = "http://#{host}:#{port}"
      Http.new(url, namespace, database, username, password)
    end

    def self.websocket_client(host, port, namespace, database, username, password) # rubocop:disable Metrics/ParameterLists
      url = "ws://#{host}:#{port}/rpc"
      WS.new(url, namespace, database, username, password)
    end
  end
end
