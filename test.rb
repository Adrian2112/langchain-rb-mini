require './llm'
require './search'
require './agent'
require 'pry'
require 'colorize'

def assert(value, message = nil)
  message = message || caller_locations(1, 1)[0].label
  if value
    puts "Success: #{message}".colorize(:green)
  else
    puts "Failed: #{message || value}".colorize(:red)
  end
end

class Test
  def test_return_final_answer
    llm = LLM.new
    class << llm
      def generate(_)
        <<~RESPONSE
    ### Assistant: To find the high temperature in San Francisco (SF) in Fahrenheit, you could use a search engine to look for current weather conditions in SF. You can input a query such as "high temperature in SF yesterday in Fahrenheit" and the search engine will return the answer for you.

    Action:
    Use the search engine to find the high temperature in SF yesterday in Fahrenheit.

    Action Input: A search query of "high temperature in SF yesterday in Fahrenheit"
        RESPONSE
      end
    end

    question = "What was the high temperature in SF yesterday in Fahrenheit?"
    result = Agent.new(llm: llm, max_iterations: 1).run(question)
    assert(result == "High: 53.6ºf @12:05 AM Low: 51.8ºf @1:00 AM Approx.")
  end

  def test_action_with_new_line
    agent = Agent.new(llm: LLM.new)
    response =
      <<~RESPONSE
        Action:
        Use the search engine to find the high temperature in SF yesterday in Fahrenheit.

        Action Input: A search query of "high temperature in SF yesterday in Fahrenheit"
      RESPONSE
    action = agent.get_action(response)

    assert(action == "search")
  end

  def test_action_with_no_space
    agent = Agent.new(llm: LLM.new)
    response =
      <<~RESPONSE
        Action:Use the search engine to find the high temperature in SF yesterday in Fahrenheit.
        Action Input: A search query of "high temperature in SF yesterday in Fahrenheit"
      RESPONSE
    action = agent.get_action(response)

    assert(action == "search")
  end

  def test_action_input_with_no_action_prefix
    agent = Agent.new(llm: LLM.new)
    response =
      <<~RESPONSE
        Action: Use the search engine to find the high temperature in SF yesterday in Fahrenheit.
        Input: high temperature in SF yesterday in Fahrenheit
      RESPONSE
    input = agent.get_action_input(response)

    assert(input == "high temperature in SF yesterday in Fahrenheit")
  end

  def test_action_input
    agent = Agent.new(llm: LLM.new)
    response =
      <<~RESPONSE
        Action: Use the search engine to find the high temperature in SF yesterday in Fahrenheit.
        Action Input: high temperature in SF yesterday in Fahrenheit
      RESPONSE
    input = agent.get_action_input(response)

    assert(input == "high temperature in SF yesterday in Fahrenheit")
  end
end

test_methods = ARGV[0].to_s

test = Test.new
test.
  methods.
  select { |m| m.to_s.start_with?('test_') }.
  select { |m| test_methods.empty? || m.to_s.include?(test_methods) }.
  each {|m| test.send(m)}
