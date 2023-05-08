require 'llama_cpp'

class LocalLanguageModel
  def initialize(model_path, stop_token:, seed: nil)
    @stop_token = stop_token
    params = LLaMACpp::ContextParams.new
    params.seed = seed || rand(0..1000)
    @context = LLaMACpp::Context.new(model_path: model_path, params: params)
  end

  def generate_response(prompt)
    response = LLaMACpp.generate(@context, prompt, n_threads: 4)
    # find the first stop token and remove the rest of the string
    response.split(@stop_token).first.to_s
  end

  def suppress_stderr
    original_stderr = $stderr.clone
    $stderr.reopen(File.new('/dev/null', 'w'))
    yield
  ensure
    $stderr.reopen(original_stderr)
  end
end
