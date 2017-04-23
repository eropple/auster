# frozen_string_literal: true
require "cfer/auster/version"

require "yaml"

require "active_support/all"
require "aws-sdk"
require "ice_nine"

module Cfer
  module Auster
    autoload :CferEvaluator,  "cfer/auster/cfer_evaluator"
    autoload :CferHelpers,    "cfer/auster/cfer_helpers"
    autoload :CLI,            "cfer/auster/cli"
    autoload :Config,         "cfer/auster/config"
    autoload :Logging,        "cfer/auster/logging"
    autoload :ParamValidator, "cfer/auster/param_validator"
    autoload :Repo,           "cfer/auster/repo"
    autoload :ScriptExecutor, "cfer/auster/script_executor"
    autoload :Step,           "cfer/auster/step"
  end
end
