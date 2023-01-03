# frozen_string_literal: true

require "net/http"
require "json"

module Surrealdb
  # JSON Patch params for modify method
  #
  #   Parameters
  #   ----------
  #   ope: str
  #       The Patch method: add, replace, remove.
  #   path: str
  #       json's key path
  #   value: any(str, bool, int, array, hash...)
  #       add or replace value.
  class Patch
    attr_reader :json

    def initialize(ope, path, value = "")
      @json = {
        op: ope,
        path:,
        value:
      }
    end
  end

  # Add Patch params for modify method
  # e.g.
  # "path": "/tags", "value": ["developer", "engineer"]
  #  tags: ["coder"] -> ["coder", "developer", "engineer"]
  class AddPatch < Patch
    def initialize(path, value)
      super(:add, path, value)
    end
  end

  # Replace Patch params for modify method
  # e.g.
  # "path": "/address"
  #  { name: "Jonny" address: "London" } => { name: "Johny"}
  class ReplacePatch < Patch
    def initialize(path, value)
      super(:replace, path, value)
    end
  end

  # Remove Patch params for modify method
  # e.g.
  # "path": "/address"
  #  { name: "Jonny" address: "London" } => { name: "Johny"}
  class RemovePatch < Patch
    def initialize(path)
      super(:remove, path)
      @json.delete(:value)
    end
  end
end
