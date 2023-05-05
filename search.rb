require 'uri'
require 'json'
require 'net/http'

class Search
   def search(query)
      get_search(query)
   end

   def get_search(query)
      return cache[query] if cache[query]

      raise 'prevent api call'
      uri = URI.parse("https://serpapi.com/search?api_key=#{ENV['SERP_API_KEY']}&q=#{query}")
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      json_response = JSON.parse(response.body)

      result =
         json_response.dig('answer_box', 'answer') ||
            json_response.dig('answer_box', 'snippet') ||
            json_response['organic_results']&.first&.dig('snippet')

      write_cache(query, result)
      result
   end

   def cache
      JSON.parse(File.open(cache_file).read)
   rescue JSON::ParserError
      puts "parse error"
      {}
   end

   def write_cache(key, value)
      cache = cache()
      cache[key] = value

      File.open(cache_file, 'w') do |f|
         f.write(cache.to_json)
      end
   end

   def cache_file
      'search_cache.json'
   end
end
