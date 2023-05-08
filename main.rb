require 'optparse'
require 'dotenv/load'
require_relative 'chatbot_app'
require_relative 'tools/search'
require_relative 'language_models/local_language_model'

Dotenv.load

# Parse command line options
options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: main.rb [options]'

  opts.on('-m', '--model MODEL_PATH', 'Path to the language model') do |model_path|
    options[:model_path] = model_path
  end

  opts.on('-r', '--runs MAX_RUNS', Integer, 'Maximum number of runs') do |max_runs|
    options[:max_runs] = max_runs
  end
end.parse!

# Validate required options
unless options[:model_path]
  puts 'Error: Model path is required.'
  exit 1
end

# Create tools
tools = [
  Search.new('search', ENV.fetch('SEARCH_API_KEY'))
]

# Load the language model
language_model = LocalLanguageModel.new(options[:model_path], stop_token: 'Observation:')

# Create the chatbot app
chatbot = ChatbotApp.new(tools, language_model)

# Get the question from the command line argument
question = ARGV[0]

# Run the chatbot
final_answer = chatbot.run(question, max_runs: options[:max_runs] || 10)

# Display the final answer
puts final_answer
