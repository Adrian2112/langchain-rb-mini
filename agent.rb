require 'colorize'
require 'logger'

class Agent
  MAX_ITERATIONS = 4
  attr_reader :model_path, :llm, :prompt_template, :actions, :max_iterations, :logger

  def initialize(model_path: nil, llm: nil, max_iterations: MAX_ITERATIONS)
    raise 'need model path or llm' if model_path.nil? && llm.nil?
    @model_path = model_path
    @llm = llm || LLM.new(model_path: model_path, stop_token: "Observation:")
    @prompt_template = File.read('prompt_template.txt')
    @max_iterations = max_iterations
    @actions = ["search", "calculator"]
    @logger = Logger.new(STDOUT)
    @logger.formatter = proc { |severity, datetime, progname, msg| "#{msg}\n" }
  end

  def run(question)
    prompt_base = prompt_template

    question_prompt = "Question: #{question}\nThought: "

    prompt = prompt_base + question_prompt

    logger.info question_prompt.colorize(:cyan)
    logger.info prompt.colorize(:cyan)

    iterations = 0
    while iterations < max_iterations
      observation = step(prompt)

      logger.info "#{final_answer(observation)}".colorize(:green) && break if answer_found?(observation)
      logger.info "Observation: #{observation}".colorize(:blue) if observation

      iterations += 1
    end

    observation
  end

  def step(prompt)
    response = llm.generate(prompt)
    logger.info "#{response}\n".colorize(:yellow)
    return response if answer_found?(response)

    action = get_action(response)
    action_input = get_action_input(response)

    if action.nil? || action_input.nil?
      logger.error "No action found. Trying again".colorize(:red) if action.nil?
      logger.error "No action input found. Trying again".colorize(:red) if action_input.nil?
      return
    end

    execute_action(action, action_input)
  end

  def answer_found?(response)
    response.to_s.include?("Final Answer: ")
  end

  def final_answer(response)
    response.match(/Final Answer: (.*)/)[1]
  end

  # [action, args]
  def get_action(response)
    response.
      match(/Action:( ?.+|\n.*)/)&.
      [](1)&.
      strip&.
      downcase&.
      then { |action| actions.find { |a| action.include?(a) } }
  end

  def get_action_input(response)
    response.
      match(/(Action )?Input: (.*)/)&.
      [](2)
  end

  def execute_action(action, args)
    case action
    when "search"
      Search.new.search(args)
    when "calculator"
      logger.error "Calculator not implemented".colorize(:red)
    else
      logger.error "No action found".colorize(:red)
      nil
    end
  end
end
