# frozen_string_literal: true

RSpec.describe Surrealdb::Client::Http do # rubocop:disable Metrics/BlockLength
  let(:host) { ENV.fetch("DATABASE_HOST", "localhost") }
  let(:port) { ENV.fetch("DATABASE_PORT", 8000) }
  let(:url) { "http://#{host}:#{port}" }
  let(:namespace) { ENV.fetch("DATABASE_NAMESPACE", "test") }
  let(:database) { ENV.fetch("DATABASE_DATABASE", "test") }
  let(:username) { ENV.fetch("DATABASE_USERNAME", "root") }
  let(:password) { ENV.fetch("DATABASE_PASSWORD", "root") }

  let(:client) { Surrealdb::Client::Http.new(url, namespace, database, username, password) }

  context "remove all records" do
    let(:table) { "hospital" }
    it do
      client.delete_all(table)
      expect(client.select_all(table).length).to eq 0
    end
  end

  context "create, select, replace and delete onece" do
    let(:table) { "hospital" }
    let(:custom_id) { "customidhere" }
    let(:name) { "A second Hospital" }
    let(:location) { "earth" }
    let(:data) { { name:, location: } }

    let(:result) { { id: "#{table}:#{custom_id}", name:, location: } }
    it "create_with_id" do
      expect(client.create_one(table, custom_id, data)).to eq result
    end
    it "select_one" do
      expect(client.select_one(table, custom_id)).to eq result
    end

    let(:new_name) { "A Replacement Hospital" }
    let(:new_location) { "not earth" }
    let(:new_data) { { name: new_name, location: new_location } }
    let(:new_result) { { id: "#{table}:#{custom_id}", name: new_name, location: new_location } }

    it "replace_one" do
      expect(client.replace_one(table, custom_id, new_data)).to eq new_result
    end

    it "delete_one" do
      client.delete_one(table, custom_id)
      expect(client.select_one(table, custom_id)).to eq nil
    end
  end

  context "upsert" do
    let(:table) { "hospital" }
    let(:custom_id) { "customidhere" }
    let(:name) { "A second Hospital" }
    let(:location) { "earth" }
    let(:data) { { name:, location: } }

    let(:result) { { id: "#{table}:#{custom_id}", name:, location: } }
    it "if the record does not exist, upsert behaves as an insert" do
      expect(client.upsert_one(table, custom_id, data)).to eq result
    end

    let(:new_name) { "A Replacement Hospital" }
    let(:new_location) { "not earth" }
    let(:new_data) { { name: new_name, location: new_location } }
    let(:new_result) { { id: "#{table}:#{custom_id}", name: new_name, location: new_location } }

    it "if the record exists, upsert behaves as update" do
      expect(client.upsert_one(table, custom_id, new_data)).to eq new_result
    end

    it "delete_one" do
      client.delete_one(table, custom_id)
      expect(client.select_one(table, custom_id)).to eq nil
    end
  end

  context "create multiple, select all" do
    let(:table) { "hospital" }
    let(:names) { ["A first Hospital", "A secound Hospital"] }
    let(:locations) { ["earth", "not earth"] }
    let(:data) do
      { name: names, location: locations }
    end

    it "create_all" do
      result = client.create_all(table, data)
      expect(result[0][:name]).to eq names
      expect(result[0][:location]).to eq locations
    end
    it "select_all" do
      result = client.select_all(table)
      expect(result[0][:name]).to eq names
      expect(result[0][:location]).to eq locations
    end
    it "remove all" do
      client.delete_all(table)
      expect(client.select_all(table).length).to eq 0
    end
  end
end
