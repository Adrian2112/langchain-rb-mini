require_relative '../../tools/search'
require 'webmock/rspec'

RSpec.describe Search do
  let(:api_key) { 'your_api_key_here' }
  let(:query) { 'example query' }
  let(:search_result) { 'example search result' }
  let(:cache_file) { 'custom_cache_file.json' }

  subject { described_class.new('Search Tool', api_key, cache_file) }

  around(:each) do |example|
    FileUtils.rm_f(cache_file)
    example.run
    FileUtils.rm_f(cache_file)
  end

  describe '#execute' do
    context 'when the query is not cached' do
      before do
        stub_request(:get, "https://serpapi.com/search?api_key=#{api_key}&q=#{URI.encode_www_form_component(query)}")
          .to_return(body: { '.answer_box.answer' => search_result }.to_json)
      end

      it 'performs a search and caches the result' do
        result = subject.execute(query)

        expect(result).to eq(search_result)
        expect(subject.query_cache[URI.encode_www_form_component(query)]).to eq(search_result)
      end
    end

    context 'when the query is already cached' do
      before do
        subject.query_cache[URI.encode_www_form_component(query)] = search_result
      end

      it 'returns the cached result' do
        result = subject.execute(query)

        expect(result).to eq(search_result)
      end

      it 'does not perform a new search or update the cache' do
        expect(subject).not_to receive(:extract_search_result)
        expect(subject).not_to receive(:save_cache)

        subject.execute(query)
      end
    end
  end
end
