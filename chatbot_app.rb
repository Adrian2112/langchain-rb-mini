class ChatbotApp
  attr_reader :tools, :language_model

  def initialize(tools, language_model)
    @tools = tools
    @language_model = language_model
  end

  def run(question)
    prompt = "Question: #{question}\nThought:"

    loop do
      response = generate_response(prompt)
      action, action_input = parse_action(response)
      observation = perform_action(action, action_input)
      prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"

      if observation.start_with?("Final Answer:")
        puts observation
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
    tool.execute(action_input)
  end
end
