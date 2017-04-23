#! /usr/bin/env ruby
# frozen_string_literal: true

logger.info "!! step 01, post-converge"
logger.info exports.inspect
logger.info "Exported TempBucket1: #{exports[:TempBucket1]}"
logger.info "Exported TempBucket2: #{exports[:TempBucket2]}"
