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
  module Signin
    def new(user, pass)
      [
        { user:, pass: }
      ]
    end
    module_function :new
  end
end
