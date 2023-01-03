# frozen_string_literal: true

require "net/http"
require "json"

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
    class Http
      def initialize(url, namespace, database, username, password)
        uri = URI.parse(url)
        @http = Net::HTTP.start(uri.host, uri.port)
        @username = username
        @password = password
        @headers = {
          "Accept": "application/json",
          "NS": namespace,
          "DB": database
        }
      end

      # Execute a query against the SurrealDB server.
      #
      #   Parameters
      #   ----------
      #   query: str
      #       The query to execute.
      #
      #   Returns
      #   -------
      #   result as JSON
      def execute(query)
        response = JSON.parse(@http.request(post_req("/sql", query)).body, symbolize_names: true)
        response[0][:result]
      end

      # Create multiple items in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to create the item in.
      #   data: hash
      #       The data to insert into the table.
      #
      #   Returns
      #   -------
      #   result as JSON
      def create_all(table, data)
        response = JSON.parse(@http.request(post_req("/key/#{table}", JSON.dump(data))).body, symbolize_names: true)
        response(response)
      end

      # Create a single item in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to create the item in.
      #   id: str
      #       The id of the item to select.
      #   data: hash
      #       The data to insert into the table.
      #
      #   Returns
      #   -------
      #   result as JSON
      def create_one(table, id, data)
        response = JSON.parse(@http.request(post_req("/key/#{table}/#{id}", JSON.dump(data))).body,
                              symbolize_names: true)
        response(response)
      end

      # Select all items in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to select from.
      #
      #   Returns
      #   -------
      #   result as JSON
      def select_all(table)
        response = JSON.parse(@http.request(get_req("/key/#{table}")).body, symbolize_names: true)
        response(response)
      end

      # Select a single item in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to select from.
      #   id: str
      #       The id of the item to select.
      #
      #   Returns
      #   -------
      #   result as JSON
      def select_one(table, id)
        response = JSON.parse(@http.request(get_req("/key/#{table}/#{id}")).body, symbolize_names: true)
        response(response)
      end

      # Replace a single item in a table.
      #
      # This method requires the entire data structure
      # to be sent and will create or update the item.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to create the item in.
      #   id: str
      #       The id of the item to select.
      #   data: hash
      #       The data to insert into the table.
      #
      #   Returns
      #   -------
      #   result as JSON
      def replace_one(table, id, data)
        response = JSON.parse(@http.request(put_req("/key/#{table}/#{id}", JSON.dump(data))).body,
                              symbolize_names: true)
        response(response)
      end

      # Upserts a single item in a table.
      #
      # This method requires only the fields you wish to be updated,
      # assuming that this id exists. If it doesn't exist, it will be created with the data.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to create the item in.
      #   id: str
      #       The id of the item to select.
      #   data: hash
      #       The data to insert into the table.
      #
      #   Returns
      #   -------
      #   result as JSON
      def upsert_one(table, id, data)
        response = JSON.parse(@http.request(patch_req("/key/#{table}/#{id}", JSON.dump(data))).body,
                              symbolize_names: true)
        response(response)
      end

      # Delete all items in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table to delete all items from.
      def delete_all(table)
        response = JSON.parse(@http.request(delete_req("/key/#{table}")).body,
                              symbolize_names: true)
        response(response)
      end

      # Delete one item in a table.
      #
      #   Parameters
      #   ----------
      #   table: str
      #       The table the item is in.
      #   id: str
      #       The id of the item to delete.
      def delete_one(table, id)
        response = JSON.parse(@http.request(delete_req("/key/#{table}/#{id}")).body,
                              symbolize_names: true)
        response(response)
      end

      # private

      def get_req(uri)
        request(Net::HTTP::Get.new(uri))
      end

      def post_req(uri, body)
        request(Net::HTTP::Post.new(uri), body)
      end

      def put_req(uri, body)
        request(Net::HTTP::Put.new(uri), body)
      end

      def patch_req(uri, body)
        request(Net::HTTP::Patch.new(uri), body)
      end

      def delete_req(uri)
        request(Net::HTTP::Delete.new(uri))
      end

      def request(req, body = nil)
        req.initialize_http_header(@headers)
        req.body = body unless body.nil?
        req.basic_auth(@username, @password)
        req
      end

      def response(res)
        Surrealdb::SurrealResponse.new(res)
      end
    end
  end
end
