require_relative './tool_base'
require 'net/http'
require 'json'

class Search < ToolBase
  attr_reader :query_cache

  def initialize(name, api_key, cache_file = 'search_cache.json')
    super(name)
    @api_key = api_key
    @cache_file = cache_file
    @query_cache = load_cache
  end

  def execute(input)
    query = URI.encode_www_form_component(input)

    if query_cached?(query)
      return @query_cache[query]
    end

    url = "https://serpapi.com/search?api_key=#{@api_key}&q=#{query}"

    uri = URI(url)
    response = Net::HTTP.get(uri)
    json_response = JSON.parse(response)

    search_result = extract_search_result(json_response)

    @query_cache[query] = search_result
    save_cache

    search_result
  end

  def load_cache
    @query_cache = File.exist?(@cache_file) ? JSON.parse(File.read(@cache_file)) : {}
  end

  private

  def query_cached?(query)
    @query_cache.key?(query)
  end

  def extract_search_result(json_response)
    if json_response.key?('.answer_box.answer')
      json_response['.answer_box.answer']
    elsif json_response.key?('.answer_box.snippet')
      json_response['.answer_box.snippet']
    elsif json_response.key?('organic_results') && !json_response['organic_results'].empty?
      json_response['organic_results'][0]['snippet']
    end
  end

  def save_cache
    File.open(@cache_file, 'w') do |file|
      file.write(JSON.pretty_generate(@query_cache))
    end
  end
end

