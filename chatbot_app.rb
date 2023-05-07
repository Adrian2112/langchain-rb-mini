require_relative './chatbot_logger'
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

    logger.info("Main Prompt: #{prompt}")

    loop do
      response = generate_response(prompt)
      action, action_input = parse_action(response)

      logger.info("Generated Response: #{response}")
      logger.info("Action: #{action}")
      logger.info("Action Input: #{action_input}")

      observation = perform_action(action, action_input)

      prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
      logger.info("Observation: #{observation}")

      if observation.start_with?("Final Answer:")
        logger.info("Final Answer: #{observation}".cyan)
        break
      end
    end
  end

  def generate_response(prompt)
    language_model.generate_response(prompt)
  end

  def parse_action(response)
    # Parse the response to extract the action and action input
    # Return action, action_input
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
