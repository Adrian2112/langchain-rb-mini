require_relative './chatbot_logger'
require 'colorize'
require 'pry'

class ChatbotApp
  attr_reader :tools, :language_model, :logger

  def initialize(tools, language_model)
    @tools = tools
    @language_model = language_model
    @logger = ChatbotLogger.new
  end

  def run(question)
    prompt = "Question: #{question}\nThought:"
    final_answer = nil

    logger.info("Main Prompt: #{prompt}")

    loop do
      response = generate_response(prompt)

      logger.info("Generated Response: #{response}")

      if final_answer?(response)
        final_answer = parse_final_answer(response)
        logger.info("Final Answer: #{final_answer}".cyan)
        break
      end

      action, action_input = parse_action(response)

      logger.info("Action: #{action}")
      logger.info("Action Input: #{action_input}")

      observation = perform_action(action, action_input)

      prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
      logger.info("Observation: #{observation}")
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

  def parse_action(response)
    lines = response.split("\n")
    action = nil
    action_input = nil

    lines.each do |line|
      line.strip!
      if line.start_with?('Action:')
        action = line.gsub('Action:', '').strip
      elsif line.start_with?('Action Input:')
        action_input = line.gsub('Action Input:', '').strip
      end
    end

    [action, action_input]
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
