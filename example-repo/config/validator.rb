# frozen_string_literal: true

Cfer::Auster::ParamValidator.new do |parameters, errors|
  errors << "nope" if parameters.nil?
end
