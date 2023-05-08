**You:**


I want to write a chatgpt like app where you can ask things and it will run a local LLM (large language model) and try to answer the question using varios tools.
Search, Calculator etc.

The LLM will take a base prompt like this
"Answer the following questions as best you can. You have access to the following tools:

search: a search engine. useful for when you need to answer questions about current
        events. input should be a search query.
calculator: useful for getting the result of a math expression. The input to this
            tool should be a valid mathematical expression that could be executed
            by a simple calculator.

Use the following format:

Question: the input question you must answer
Thought: you should always think about what to do
Action: the action to take, should be one of [search, calculator]
Action Input: the input to the action
Observation: the result of the action
... (this Thought/Action/Action Input/Observation can repeat N times)
Thought: I now know the final answer
Final Answer: the final answer to the original input question

Begin!

Question: ${question}
Thought:
"

this is the current implementation of the ChatbotApp

```
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
```

this is the current spec

```
require 'rspec'
require 'rspec/mocks'
require_relative '../chatbot_app'

RSpec.describe ChatbotApp do
  let(:search_tool) { double('SearchTool') }
  let(:calculator_tool) { double('CalculatorTool') }
  let(:local_language_model) { double('LocalLanguageModel') }

  subject(:chatbot) { ChatbotApp.new([search_tool, calculator_tool], local_language_model) }

  before do
    allow(search_tool).to receive(:name).and_return('search')
    allow(calculator_tool).to receive(:name).and_return('calculator')
  end

  describe '#run' do
    let(:question) { 'What is the capital of France?' }
    let(:response1) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }
    let(:observation1) { 'Paris is the capital of France.' }
    let(:response2) { "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." }

    it 'runs the main loop and finds the final answer' do
      expect(local_language_model).to receive(:generate_response).and_return(response1, response2)
      expect(search_tool).to receive(:execute).with('capital of France').and_return(observation1)

      expect { chatbot.run(question) }.to output(/Final Answer: Paris is the capital of France./).to_stdout
    end
  end
end
```

these are the logs and the spec error
```
INFO: Main Prompt: Question: What is the capital of France?
Thought:
INFO: Generated Response: Thought: I'm not sure. Let me search for it.
Action: search
Action Input: capital of France
INFO: Action: search
INFO: Action Input: capital of France
INFO: Observation: Paris is the capital of France.
INFO: Generated Response: Thought: Now I know the final answer.
Final Answer: Paris is the capital of France.
INFO: Action:
INFO: Action Input:
ERROR: Invalid action:
INFO: Observation:
F

Failures:

  1) ChatbotApp#run runs the main loop and finds the final answer
     Failure/Error: expect { chatbot.run(question) }.to output(/Final Answer: Paris is the capital of France./).to_stdout

     NoMethodError:
       undefined method `start_with?' for nil:NilClass
     # ./chatbot_app.rb:31:in `block in run'
     # ./chatbot_app.rb:18:in `loop'
     # ./chatbot_app.rb:18:in `run'
     # ./spec/chatbot_app_spec.rb:27:in `block (4 levels) in <top (required)>'
     # ./spec/chatbot_app_spec.rb:27:in `block (3 levels) in <top (required)>'

Finished in 0.01597 seconds (files took 1.04 seconds to load)
1 example, 1 failure
```

Fix this

------------------
**ChatGPT:**


The error you're encountering is due to the fact that the `parse_action` method in the `ChatbotApp` class is not properly handling the case when there is no action specified in the response. This causes the `action` variable to remain `nil`, leading to the error when checking `observation.start_with?("Final Answer:")`.
To fix this issue, you can update the `parse_action` method to set default values for `action` and `action_input`. Here's an updated version of the method:

```ruby
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

  action ||= ''
  action_input ||= ''

  [action, action_input]
end

```
With this modification, if no action is specified in the response, `action` will be set to an empty string. Therefore, when checking `observation.start_with?("Final Answer:")`, it won't throw a `NoMethodError` and will behave as expected.
After applying this fix, the error should be resolved, and the test case should pass successfully.

------------------
**You:**


can we detect that the llm reached the final answer before parsing the action and we can break at that point
------------------
**ChatGPT:**


Yes, we can modify the code to detect if the generated response from the language model contains the final answer before parsing the action. If the observation starts with "Final Answer:", we can break the loop and skip the action parsing and execution steps.
Here's an updated version of the `run` method in the `ChatbotApp` class that includes this modification:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

  logger.info("Main Prompt: #{prompt}")

  loop do
    response = generate_response(prompt)

    logger.info("Generated Response: #{response}")

    if response.start_with?("Final Answer:")
      logger.info("Final Answer: #{response}".cyan)
      break
    end

    action, action_input = parse_action(response)

    logger.info("Action: #{action}")
    logger.info("Action Input: #{action_input}")

    observation = perform_action(action, action_input)

    prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
    logger.info("Observation: #{observation}")
  end
end

```
With this modification, if the response starts with "Final Answer:", it logs the final answer and breaks out of the loop without parsing the action or performing any further steps.
Now, when the language model generates a response that contains the final answer, the loop will exit, and the test case will complete successfully without encountering the error you previously faced.

------------------
**You:**


the code is cycling. it is not deteting the final answer
------------------
**ChatGPT:**


I apologize for the confusion. It seems I misunderstood your requirement. To detect the final answer in the response and break the loop, we need to check the observation, not the entire response. The observation contains the result of the action performed, including the final answer if it's available.
Here's the modified version of the `run` method that checks the observation for the final answer:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

  logger.info("Main Prompt: #{prompt}")

  loop do
    response = generate_response(prompt)

    logger.info("Generated Response: #{response}")

    action, action_input = parse_action(response)

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

```
With this modification, the code checks if the observation starts with "Final Answer:". If it does, it logs the final answer and breaks the loop. Otherwise, it continues to the next iteration of the loop to generate the next response and perform the corresponding action.
Please give it a try, and let me know if you have any further questions or issues.

------------------
**You:**


the Final Answer is provided as the llm response. It is not going to start with "Final Answer", the response will contain that text
------------------
**ChatGPT:**


Apologies for the confusion. In that case, we need to modify the logic to properly detect the final answer in the response. We can update the code to check if the response contains the text "Final Answer:" instead of using `observation.start_with?("Final Answer:")`.
Here's the updated version of the `run` method that checks if the response contains the final answer:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

  logger.info("Main Prompt: #{prompt}")

  loop do
    response = generate_response(prompt)

    logger.info("Generated Response: #{response}")

    if response.include?("Final Answer:")
      logger.info("Final Answer: #{response}".cyan)
      break
    end

    action, action_input = parse_action(response)

    logger.info("Action: #{action}")
    logger.info("Action Input: #{action_input}")

    observation = perform_action(action, action_input)

    prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
    logger.info("Observation: #{observation}")
  end
end

```
With this modification, the code checks if the response includes the text "Final Answer:". If it does, it logs the final answer and breaks the loop. Otherwise, it continues to the next iteration to generate the next response and perform the corresponding action.
Please give it a try, and let me know if you have any further questions or issues.

------------------
**You:**


do the check after generatin the response
------------------
**ChatGPT:**


Apologies for the oversight. If the final answer is provided in the generated response, we should check for it after generating the response. Here's the modified `run` method with the updated logic:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

  logger.info("Main Prompt: #{prompt}")

  loop do
    response = generate_response(prompt)

    logger.info("Generated Response: #{response}")

    action, action_input = parse_action(response)

    logger.info("Action: #{action}")
    logger.info("Action Input: #{action_input}")

    observation = perform_action(action, action_input)

    prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
    logger.info("Observation: #{observation}")

    if response.include?("Final Answer:")
      logger.info("Final Answer: #{response}".cyan)
      break
    end
  end
end

```
Now, the code checks if the generated response includes the text "Final Answer:". If it does, it logs the final answer and breaks the loop. This ensures that we correctly detect the final answer in the response.
I apologize for the confusion caused earlier. Please try this updated code, and let me know if you have any further questions or issues.

------------------
**You:**


this is the code "  def run(question)
    prompt = "Question: #{question}\nThought:"

    logger.info("Main Prompt: #{prompt}")

    loop do
      response = generate_response(prompt)

      logger.info("Generated Response: #{response}")

      if response.include?("Final Answer:")
        logger.info("Final Answer: #{response}".cyan)
        break
      end

      action, action_input = parse_action(response)

      logger.info("Action: #{action}")
      logger.info("Action Input: #{action_input}")

      observation = perform_action(action, action_input)

      prompt += "\nThought: #{response}\nAction: #{action}\nAction Input: #{action_input}\nObservation: #{observation}"
      logger.info("Observation: #{observation}")
    end
  end
" parse the final answer correctly since the response include more information
------------------
**ChatGPT:**


Apologies for the confusion. To correctly parse the final answer from the response, you can modify the code to extract the final answer by splitting the response and searching for the line that starts with "Final Answer:".
Here's the updated code that correctly parses the final answer:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

  logger.info("Main Prompt: #{prompt}")

  loop do
    response = generate_response(prompt)

    logger.info("Generated Response: #{response}")

    if response.include?("Final Answer:")
      final_answer = response.lines.find { |line| line.start_with?("Final Answer:") }
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
end

```
In this updated code, after generating the response, we search for the line that starts with "Final Answer:" using the `find` method on the response lines. This will correctly extract the final answer line. We then log the final answer using the `logger.info` statement.
Please give it a try, and let me know if you have any further questions or issues.

------------------
**You:**


move the check and parse of the final answer into its own method
------------------
**ChatGPT:**


Certainly! It's a good idea to separate the logic for checking and parsing the final answer into its own method. Here's an updated version of the code that incorporates a separate method for extracting the final answer:

```ruby
def run(question)
  prompt = "Question: #{question}\nThought:"

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
end

def final_answer?(response)
  response.include?("Final Answer:")
end

def parse_final_answer(response)
  response.lines.find { |line| line.start_with?("Final Answer:") }.to_s.strip
end

```

In this updated code, the `final_answer?` method checks if the response includes the text "Final Answer:". The `parse_final_answer` method extracts the final answer line from the response using `find` on the response lines. It then trims any leading or trailing whitespace to obtain the final answer string.
By moving the final answer check and parsing into separate methods, the `run` method becomes more readable and modular.
Please give it a try, and let me know if you have any further questions or issues.

------------------
**You:**


ok now based on that, here is a sample response "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." make final_answer? and parse_final_answer work with that
------------------
**ChatGPT:**


Apologies for the confusion. To handle the sample response format you provided, we can modify the `final_answer?` and `parse_final_answer` methods accordingly.
Here's the updated code that handles the provided response format:

```ruby
def final_answer?(response)
  response.include?("Final Answer:")
end

def parse_final_answer(response)
  final_answer_line = response.lines.find { |line| line.include?("Final Answer:") }
  final_answer = final_answer_line.split("Final Answer:").last.to_s.strip
end

```

In the `final_answer?` method, we check if the response includes the text "Final Answer:". This remains the same.
In the `parse_final_answer` method, we find the line that includes "Final Answer:" using `find`. We then split that line by "Final Answer:" and take the last part of the split to obtain the final answer. We trim any leading or trailing whitespace to obtain the final answer string.
With these modifications, the `final_answer?` and `parse_final_answer` methods should handle the provided response format correctly.
Please give it a try, and let me know if you have any further questions or issues.

------------------
**You:**


generate specs for those methods
------------------
**ChatGPT:**


Certainly! Here are the example specs for the `final_answer?` and `parse_final_answer` methods:

```ruby
RSpec.describe ChatbotApp do
  # ...

  describe '#final_answer?' do
    it 'returns true if response includes "Final Answer:"' do
      response = "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France."
      expect(chatbot.final_answer?(response)).to be true
    end

    it 'returns false if response does not include "Final Answer:"' do
      response = "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France"
      expect(chatbot.final_answer?(response)).to be false
    end
  end

  describe '#parse_final_answer' do
    it 'returns the parsed final answer from the response' do
      response = "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France."
      expect(chatbot.parse_final_answer(response)).to eq "Paris is the capital of France."
    end

    it 'returns an empty string if response does not include "Final Answer:"' do
      response = "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France"
      expect(chatbot.parse_final_answer(response)).to eq ""
    end
  end

  # ...
end

```

In these example specs, we test the behavior of the `final_answer?` and `parse_final_answer` methods.
For `final_answer?`, we check if the method correctly returns `true` when the response includes "Final Answer:", and `false` when the response does not include it.
For `parse_final_answer`, we verify that the method correctly extracts and parses the final answer from the response. We also test that it returns an empty string when the response does not include "Final Answer:".
These specs ensure that the `final_answer?` and `parse_final_answer` methods function as expected.
Please let me know if you have any further questions!

------------------
**You:**


  1) ChatbotApp#parse_final_answer returns an empty string if response does not include "Final Answer:"
     Failure/Error: expect(chatbot.parse_final_answer(response)).to eq ""

     NoMethodError:
       undefined method `split' for nil:NilClass
------------------
**ChatGPT:**


Apologies for the oversight. It seems that the provided response does not include the "Final Answer:" line, which causes an error in the `parse_final_answer` method.
To handle such cases, we can update the `parse_final_answer` method to handle a `nil` value when the "Final Answer:" line is not found. Here's an updated version of the method:

```ruby
def parse_final_answer(response)
  final_answer_line = response.lines.find { |line| line.include?("Final Answer:") }
  final_answer_line ? final_answer_line.split("Final Answer:").last.to_s.strip : ""
end

```

In this updated code, we first check if the `final_answer_line` variable is not `nil` before splitting it to extract the final answer. If the `final_answer_line` is `nil`, it means that the response does not include the "Final Answer:" line, and we return an empty string as the default value.
With this modification, the `parse_final_answer` method should handle cases where the "Final Answer:" line is not found in the response.
Please try running the specs again, and let me know if you encounter any further issues.

------------------
**You:**


this spec is failing "describe '#run' do
    let(:question) { 'What is the capital of France?' }
    let(:response1) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }
    let(:observation1) { 'Paris is the capital of France.' }
    let(:response2) { "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." }

    it 'runs the main loop and finds the final answer' do
      expect(local_language_model).to receive(:generate_response).and_return(response1, response2)
      expect(search_tool).to receive(:execute).with('capital of France').and_return(observation1)

      expect { chatbot.run(question) }.to output(/Final Answer: Paris is the capital of France./).to_stdout
    end
  end
" the log looks correct. Logs "Main Prompt: Question: What is the capital of France?
Thought:
Generated Response: Thought: I'm not sure. Let me search for it.
Action: search
Action Input: capital of France
Action: search
Action Input: capital of France
Observation: Paris is the capital of France.
Generated Response: Thought: Now I know the final answer.
Final Answer: Paris is the capital of France.
Final Answer: Paris is the capital of France."
------------------
**ChatGPT:**


Apologies for the confusion. It seems that the issue lies with the `expect` statement in the spec. The `expect` block is checking if the output matches the regex `/Final Answer: Paris is the capital of France./`, but the output in this case includes additional log lines. Therefore, the expectation is not met, and the spec fails.
To fix the spec, we can update the `expect` block to match the exact output string rather than using a regex. Here's an updated version of the spec:

```ruby
describe '#run' do
  let(:question) { 'What is the capital of France?' }
  let(:response1) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }
  let(:observation1) { 'Paris is the capital of France.' }
  let(:response2) { "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." }

  it 'runs the main loop and finds the final answer' do
    expect(local_language_model).to receive(:generate_response).and_return(response1, response2)
    expect(search_tool).to receive(:execute).with('capital of France').and_return(observation1)

    expect { chatbot.run(question) }.to output("Main Prompt: Question: What is the capital of France?\nThought:\nGenerated Response: Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France\nAction: search\nAction Input: capital of France\nObservation: Paris is the capital of France.\nGenerated Response: Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France.\nFinal Answer: Paris is the capital of France.\n").to_stdout
  end
end

```
In this updated version, the `expect` block checks if the exact output string matches the expected output. This includes the complete log lines generated during the execution of the `run` method.
Please give it a try and let me know if the spec passes successfully.

------------------
**You:**


change the code for run so it return the final answer and we can use that for the spec
------------------
**ChatGPT:**


Certainly! Here's an updated version of the `run` method that returns the final answer:

```ruby
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

```

In this updated version, a `final_answer` variable is introduced to store the final answer when it is detected. If the response includes the "Final Answer:" line, the method extracts and stores the final answer in the `final_answer` variable. The loop is then broken, and the final answer is returned at the end of the `run` method.
Now you can update the spec to verify the returned final answer:

```ruby
describe '#run' do
  let(:question) { 'What is the capital of France?' }
  let(:response1) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }
  let(:observation1) { 'Paris is the capital of France.' }
  let(:response2) { "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." }

  it 'runs the main loop and finds the final answer' do
    expect(local_language_model).to receive(:generate_response).and_return(response1, response2)
    expect(search_tool).to receive(:execute).with('capital of France').and_return(observation1)

    final_answer = chatbot.run(question)
    expect(final_answer).to eq("Paris is the capital of France.")
  end
end

```
In this updated spec, the `run` method is called, and the returned final answer is stored in the `final_answer` variable. Then, an expectation is added to verify that the `final_answer` matches the expected value.
Now when you run the spec, it should pass successfully and validate that the `run` method correctly returns the final answer.
Let me know if you have any further questions!

------------------
**You:**


write specs for parse_action and perform_action
------------------
**ChatGPT:**


Certainly! Here are the specs for the `parse_action` and `perform_action` methods:

```ruby
describe '#parse_action' do
  let(:response) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }

  it 'parses the action and action input from the response' do
    action, action_input = chatbot.parse_action(response)

    expect(action).to eq('search')
    expect(action_input).to eq('capital of France')
  end
end

describe '#perform_action' do
  let(:search_tool) { double('SearchTool') }
  let(:action) { 'search' }
  let(:action_input) { 'capital of France' }
  let(:observation) { 'Paris is the capital of France.' }

  before do
    allow(search_tool).to receive(:name).and_return('search')
  end

  context 'when the action is valid' do
    before do
      allow(chatbot).to receive(:tools).and_return([search_tool])
      allow(search_tool).to receive(:execute).with(action_input).and_return(observation)
    end

    it 'executes the action and returns the observation' do
      result = chatbot.perform_action(action, action_input)

      expect(result).to eq(observation)
    end
  end

  context 'when the action is invalid' do
    it 'logs an error and returns nil' do
      result = chatbot.perform_action('invalid_action', action_input)

      expect(result).to be_nil
      expect(logger).to have_received(:error).with('Invalid action: invalid_action')
    end
  end

  context 'when the action execution fails' do
    before do
      allow(chatbot).to receive(:tools).and_return([search_tool])
      allow(search_tool).to receive(:execute).with(action_input).and_return(nil)
    end

    it 'logs an error and returns nil' do
      result = chatbot.perform_action(action, action_input)

      expect(result).to be_nil
      expect(logger).to have_received(:error).with('Failed to execute action: search')
    end
  end
end

```

In these specs, the `parse_action` method is tested to ensure that it correctly parses the action and action input from the given response.
The `perform_action` method is tested in different scenarios. In the first context, when the action is valid, it expects the method to execute the action using the corresponding tool and return the observation. In the second context, when the action is invalid, it expects the method to log an error and return `nil`. In the third context, when the action execution fails, it expects the method to log an error and return `nil` as well.
Make sure to replace `logger` with the appropriate logger instance in the `perform_action` method implementation.
These specs will help ensure that the `parse_action` and `perform_action` methods behave as expected.
Let me know if there's anything else I can assist you with!

------------------
