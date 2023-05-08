notification :terminal_notifier

guard :rspec, cmd: "bundle exec rspec", notification: true, failed_mode: :focus do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^(.+)\.rb$})             { |m| "spec/#{m[1]}_spec.rb" }
  watch(%r{^spec/spec_helper\.rb$})     { "spec" }
end
