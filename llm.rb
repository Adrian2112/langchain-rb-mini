require 'llama_cpp'
require "stringio"

class LLM
  attr_reader :model_path

  def initialize(model_path: nil, stop_token: nil)
    @model_path = model_path || '../models/ggml-vicuna-7b-q4_0.bin'
    @stop_token = stop_token
  end

  def generate(prompt, seed: rand(1..100))
    suppress_stderr do
      params = LLaMACpp::ContextParams.new
      params.seed = seed

      context = LLaMACpp::Context.new(model_path: model_path, params: params)

      response = LLaMACpp.generate(context, prompt, n_threads: 4)
      # find the first stop token and remove the rest of the string
      response.split(@stop_token).first
    end
  end

  def suppress_stderr
    original_stderr = $stderr.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    yield
  ensure
    $stderr.reopen(original_stderr)
  end
end
