# frozen_string_literal: true

require_relative "client/http"

module Surrealdb
  # Client for surrealsb
  class Client
    # TODO: implement web_socket client
    def initialize(url, namespace, database, username, password)
      @client = Surrealdb::Client::Http.new(url, namespace, database, username, password)
    end

    def execute(query)
      @client.execute(query)
    end

    def create_all(table, data)
      @client.create_all(table, data)
    end

    def create_one(table, id, data)
      @client.create_one(table, id, data)
    end

    def select_all(table)
      @client.select_all(table)
    end

    def select_one(table, id)
      @client.select_one(table, id)
    end

    def replace_one(table, id, data)
      @client.replace_one(table, id, data)
    end

    def upsert_one(table, id, data)
      @client.upsert_one(table, id, data)
    end

    def delete_all(table)
      @client.delete_all(table)
    end

    def delete_one(table, id)
      @client.delete_one(table, id)
    end
  end
end
