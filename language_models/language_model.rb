class LanguageModel
  attr_reader :prompt

  def initialize(prompt)
    @prompt = prompt
  end

  def generate_response
    raise NotImplementedError, "Subclasses must implement 'generate_response' method"
  end
end
