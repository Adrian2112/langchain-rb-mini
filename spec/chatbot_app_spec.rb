require 'rspec'
require 'rspec/mocks'
require_relative '../chatbot_app'

RSpec.describe ChatbotApp do
  let(:search) { double('SearchTool', name: 'search') }
  let(:language_model) { double('LocalLanguageModel') }

  subject(:chatbot) { ChatbotApp.new([search], language_model) }

  before do
    allow(search).to receive(:name).and_return('search')
  end

  describe '#run' do
    let(:question) { 'What is the capital of France?' }
    let(:response1) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }
    let(:observation1) { 'Paris is the capital of France.' }
    let(:response2) { "Thought: Now I know the final answer.\nFinal Answer: Paris is the capital of France." }

    it 'runs the main loop and finds the final answer' do
      expect(language_model).to receive(:generate_response).and_return(response1, response2)
      expect(search).to receive(:execute).with('capital of France').and_return(observation1)

      final_answer = chatbot.run(question)
      expect(final_answer).to eq("Paris is the capital of France.")
    end

    context 'when the action is invalid' do
      let(:question) { 'What is the capital of France?' }
      let(:response) { "Thought: I don't know what to do\nAction: invalid_action" }

      it 'skips the run and tries again' do
        expect(language_model).to receive(:generate_response).and_return(response)

        final_answer = chatbot.run(question, max_runs: 1)
        expect(final_answer).to be_nil
      end
    end
  end

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

  describe '#get_action' do
    let(:response) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }

    it 'parses the action and action input from the response' do
      action = chatbot.get_action(response)

      expect(action).to eq('search')
    end

    it 'with action and input in one line' do
      response = 'Answer: Paris. Thought: Use the search tool to find an answer to the question "What is the capital of France?" Action: search the web Action Input: "What is the capital of France?"'

      action = chatbot.get_action(response)

      expect(action).to eq('search')
    end
  end

  describe '#get_action_input' do
    let(:response) { "Thought: I'm not sure. Let me search for it.\nAction: search\nAction Input: capital of France" }

    it 'parses the action and action input from the response' do
      action_input = chatbot.get_action_input(response)

      expect(action_input).to eq('capital of France')
    end

    it 'with action and input in one line' do
      response = 'Answer: Paris. Thought: Use the search tool to find an answer to the question "What is the capital of France?" Action Input: "What is the capital of France?"'

      action_input = chatbot.get_action_input(response)

      expect(action_input).to eq('"What is the capital of France?"')
    end
  end

  describe '#perform_action' do
    let(:search) { double('SearchTool') }
    let(:action) { 'search' }
    let(:action_input) { 'capital of France' }
    let(:observation) { 'Paris is the capital of France.' }

    before do
      allow(search).to receive(:name).and_return('search')
    end

    context 'when the action is valid' do
      before do
        allow(chatbot).to receive(:tools).and_return([search])
        allow(search).to receive(:execute).with(action_input).and_return(observation)
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
      end
    end

    context 'when the action execution fails' do
      before do
        allow(chatbot).to receive(:tools).and_return([search])
        allow(search).to receive(:execute).with(action_input).and_return(nil)
      end

      it 'logs an error and returns nil' do
        result = chatbot.perform_action(action, action_input)

        expect(result).to be_nil
      end
    end
  end
end
