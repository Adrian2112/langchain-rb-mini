class Tool
  attr_reader :name

  def initialize(name)
    @name = name
  end

  def execute(input)
    raise NotImplementedError, "Subclasses must implement 'execute' method"
  end
end
