# frozen_string_literal: true

require "json"
require "eventmachine"
require "websocket-eventmachine-client"
require "surrealdb/models/patch"
require "surrealdb/models/request"
require "surrealdb/models/signin"

module Surrealdb
  module Client
    # Represents a http connection to a SurrealDB server.
    #
    #     Parameters
    #     ----------
    #     url: str
    #         The URL of the SurrealDB server.
    #     namespace: str
    #         The namespace to use for the connection.
    #     database: str
    #         The database to use for the connection.
    #     username: str
    #         The username to use for the connection.
    #     password: str
    #         The password to use for the connection.
    class WS # rubocop:disable Metrics/ClassLength
      attr_reader :namespace, :database, :username, :password, :status, :using, :signed_in

      def initialize(uri, namespace, database, username, password)
        @responses = {}
        @status = :connecting
        @using = false
        @signed_in = false
        @uri = uri

        Thread.new do
          EM.run do
            @ws = ws(uri, namespace, database, username, password)
          end
        end
      end

      # Signs in to the SurrealDB server.
      def connect(uri = @uri)
        return if @status == :connected

        @status = :connecting
        @using = false
        @signed_in = false
        EM.run do
          @ws = ws(uri, @namespace, @database, @username, @password)
        end
      end

      # Signs in to the SurrealDB server.
      def disconnect
        @ws.close
      end

      # Signs in to the SurrealDB server.
      def signin(username, password)
        send(:signin, Signin.new(username, password))
        @username = username
        @password = password
        true
      end

      # Change the namespace and database to use.
      def use(namespace, database)
        send(:use, [namespace, database])
        @namespace = namespace
        @database = database
        true
      end

      # Execute a query against the SurrealDB server.
      #
      #   Parameters
      #   ----------
      #   query: str
      #       The query to execute.
      def execute(query)
        QueryRPCResponse.new(request(:query, [query]))
      end

      # Create a single item in a table.
      #
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to create.
      #   record_id: str
      #       The record ID to create the record.
      #   data: hash
      #       The data to insert into the table.
      def create_with_id(table, record_id, data)
        CRUDRPCResponse.new(request(:create, [table_record_id(table, record_id), data]))
      end

      # Create an item in a table without record_id.
      #
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to create.
      #   data: hash
      #       The data to insert into the table.
      def create(table, data)
        CRUDRPCResponse.new(request(:create, [table, data]))
      end

      # Select all items in a table.
      #
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to find.
      def select_all(table_id)
        CRUDRPCResponse.new(request(:select, [table_id]))
      end

      # Select a single item in a table.
      #
      #   Parameters
      #   ----------
      #   table_or_record_id: str
      #       The table or record ID to find.
      def select_one(table, record_id)
        CRUDRPCResponse.new(request(:select, [table_record_id(table, record_id)]))
      end

      # Replace a single item in a table.
      #
      # This method requires the entire data structure
      # to be sent and will create or update the item.
      #
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to update.
      #   record_id: str
      #       The record ID to update the record.
      #   data: hash
      #       The data to insert into the table.
      def update(table, record_id, data)
        CRUDRPCResponse.new(request(:update, [table_record_id(table, record_id), data]))
      end

      # Replace all items in a table.
      #
      # This method requires the entire data structure
      # to be sent and will create or update the item.
      #
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to update.
      #   data: hash
      #       The data to insert into the table.
      def update_all(table, data)
        CRUDRPCResponse.new(request(:update, [table, data]))
      end

      # Applies `JSON Patch` changes to all records.
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to path.
      #   patches: Array(Patch.json)
      #       The data to modify the record or table with.
      def modify_all(table, patches)
        ModifyRPCResponse.new(request(:modify, [table, patches]))
      end

      # `JSON Patch` changes to a record.
      #   Parameters
      #   ----------
      #   table_id: str
      #       The table ID to modify.
      #   record_id: str
      #       The record ID to path the record.
      #   patche:  Array(Patch)
      #       The data to modify the record or table with.
      def modify(table, record_id, patches)
        ModifyRPCResponse.new(request(:modify, [table_record_id(table, record_id), patches]))
      end

      # Delete all items in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to delete all items from.
      def delete_all(table)
        CRUDRPCResponse.new(request(:delete, [table]))
      end

      # Delete one item in a table.
      #
      #   Parameters
      #   ----------
      #   table_or_record_id: str
      #       The table or record ID to delete.
      def delete(table, record_id)
        CRUDRPCResponse.new(request(:delete, [table_record_id(table, record_id)]))
      end

      private

      def table_record_id(table, record_id = "")
        record_id.empty? ? table : "#{table}:#{record_id}"
      end

      def request(method, params = [])
        EM.next_tick {} until sendable?
        req_id = send(method, params)
        result(req_id)
      end

      def send(method, params = [])
        req = Surrealdb::RPCRequest.new(method, params)
        @ws.send JSON.dump(req)
        req[:id]
      end

      def revieve_response(msg)
        begin
          resp = JSON.parse(msg, symbolize_names: true)
          raise Surrealdb::RPCError, resp[:error] if resp.key?(:error)
        rescue RPCError => e
          raise e if e.critical?

          puts "Error: #{e.message}"
        end
        @responses[resp[:id]] = resp[:result] unless skip?(resp)
      end

      def skip?(resp)
        return false if resp.key?(:error)

        resp.key?(:result) && (signin_response?(resp) || using_response?(resp))
      end

      def signin_response?(resp)
        return false unless resp[:result] == ""

        @signed_in = true
      end

      def using_response?(resp)
        return false unless resp[:result].nil?

        @using = true
      end

      def result(id)
        id_s = id.to_s
        EM.next_tick {} until @responses.key?(id_s)

        @responses.delete(id_s)
      end

      def sendable?
        connect if @status == :closed

        @status == :connected && @signed_in && @using
      end

      def ws(uri, namespace, database, username, password) # rubocop:disable Metrics/MethodLength
        ws = WebSocket::EventMachine::Client.connect(
          uri:
        )

        ws.onopen do
          onopen(namespace, database, username, password)
        end

        ws.onmessage do |msg, _type|
          revieve_response(msg)
        end

        ws.onclose do |code, _reason|
          onclose(code)
        end

        ws.onerror do |error|
          puts "Error occured: #{error}"
          @status = :closed
        end
        ws
      end

      def onopen(namespace, database, username, password)
        puts "WebSocket connection established."
        @status = :connected
        signin(username, password)
        use(namespace, database)
      end

      def onclose(code)
        if [1000, 1002].include?(code)
          puts "WebSocket connection closed."
        else
          puts "WebSocket connection closed with status code: #{code}"
        end
        @status = :closed
      end
    end
  end
end
