# frozen_string_literal: true

RSpec.describe Surrealdb::Client::WS do
  let(:host) { ENV.fetch("DATABASE_HOST", "localhost") }
  let(:port) { ENV.fetch("DATABASE_PORT", 8000) }
  let(:url) { "ws://#{host}:#{port}/rpc" }
  let(:namespace) { "test" }
  let(:database) { "test" }
  let(:username) { "root" }
  let(:password) { "root" }

  let(:client) { Surrealdb::Client::WS.new(url, namespace, database, username, password) }
  skip "TODO: create test case with async method" do
  end
end
