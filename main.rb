require './llm'
require './search'
require './agent'
require 'dotenv'
require 'optparse'

Dotenv.load

question = "What was the high temperature in SF yesterday in Fahrenheit?"

options = {
  model_path: "../models/ggml-alpaca-7b-q4.bin",
  max_iterations: 10
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby main.rb [options]"

  opts.on("-m", "--model_path PATH", String, "model path") do |o|
    options[:model_path] = o
  end

  # max iterations
  opts.on("-i", "--max_iterations NUMBER", Integer, "max iterations") do |o|
    options[:max_iterations] = o
  end
end.parse!

Agent.new(**options).run(question)

