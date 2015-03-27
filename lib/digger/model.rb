require 'digger/pattern'

module Digger
  class Model
    @@patterns = {}

    class << self
      def pattern_config
        @@patterns[self.name] ||= {}
      end

      Pattern::TYPES.each do |method|
        define_method method, ->(pairs, &block){
          pairs.each_pair do |key, value|
            pattern_config[key] = Pattern.new(type: method, value: value, block: block)
          end
        }
      end

      def index_page
      end

      def one_page
      end
    end

    def match_page(page)
      result = {}
      self.class.pattern_config.each_pair do |key, pattern|
        result[key] = pattern.match_page(page)
      end
      result
    end

    def dig(url)
      client = Digger::HTTP.new
      page = client.fetch_page(url)
      match_page(page)
    end
  end
end