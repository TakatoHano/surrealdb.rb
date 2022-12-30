# frozen_string_literal: true

RSpec.describe Surrealdb do
  it "has a version number" do
    expect(Surrealdb::VERSION).not_to be nil
  end
end
