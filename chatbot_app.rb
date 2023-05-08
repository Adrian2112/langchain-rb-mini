require_relative './chatbot_logger'
require 'colorize'
require 'pry'

class ChatbotApp
  attr_reader :tools, :language_model, :logger

  DEFAULT_MAX_RUNS = 10

  def initialize(tools, language_model)
    @tools = tools
    @language_model = language_model
    @logger = ChatbotLogger.new
    @base_prompt = File.open("base_prompt.txt").read
  end

  def run(question, max_runs: DEFAULT_MAX_RUNS)
    prompt = "#{@base_prompt}\nQuestion: #{question}"
    final_answer = nil

    logger.info(prompt.cyan)

    run_count = 0
    while run_count < max_runs
      response = generate_response(prompt)

      logger.info(response.yellow)

      if final_answer?(response)
        final_answer = parse_final_answer(response)
        break
      end

      thought = get_thought(response)

      action = get_action(response)
      action_input = get_action_input(response)

      unless action && action_input
        logger.debug("no action found".magenta)
        run_count += 1
        next
      end

      logger.debug("performing action: #{action} with input: #{action_input}".magenta)
      observation = perform_action(action, action_input)

      logger.info("Observation: #{observation}".blue)

      prompt = "Thought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"

      run_count += 1
    end

    final_answer
  end

  def final_answer?(response)
    response.include?("Final Answer:")
  end

  def parse_final_answer(response)
    final_answer_line = response.lines.find { |line| line.include?("Final Answer:") }
    final_answer_line ? final_answer_line.split("Final Answer:").last.to_s.strip : ""
  end

  def generate_response(prompt)
    language_model.generate_response(prompt)
  end

  def get_thought(response)
    # anything before Action:
    response.gsub("\n", '').match(/(.*)Action:/)&.[](1)
  end

  def get_action(response)
    response.
      match(/Action:( ?.+|\n.*)/)&.
      [](1)&.
      strip&.
      downcase&.
      then { |action| tools.map(&:name).find { |tool_name| tool_name == action } }
  end

  def get_action_input(response)
    response.
      match(/(Action )?Input: (.*)/)&.
      [](2)
  end

  def perform_action(action, action_input)
    tool = tools.find { |t| t.name == action }
    if tool
      result = tool.execute(action_input)
      if result
        result
      else
        logger.error("Failed to execute action: #{action}")
        nil
      end
    else
      logger.error("Invalid action: #{action}")
      nil
    end
  end
end

