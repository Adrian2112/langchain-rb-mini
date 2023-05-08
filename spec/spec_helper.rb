require 'webmock/rspec'

RSpec.configure do |config|
  # Run only the examples with :focus metadata
  config.filter_run focus: true

  # Run all examples when everything is filtered
  config.run_all_when_everything_filtered = true

  # Other configuration options...
end
