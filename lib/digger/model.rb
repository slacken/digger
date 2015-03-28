
module Digger
  class Model
    @@digger_config = {'pattern'=>{}, 'index'=>{}}

    class << self
      # patterns
      def pattern_config
        @@digger_config['pattern'][self.name] ||= {}
      end

      Pattern::TYPES.each do |method|
        define_method method, ->(pairs, &block){
          pairs.each_pair do |key, value|
            pattern_config[key] = Pattern.new(type: method, value: value, block: block)
          end
        }
      end

      # index page
      def index_config
        @@digger_config['index'][self.name]
      end

      def index_page(pattern, *args)
         @@digger_config['index'][self.name] = Index.new(pattern, args)
      end

      def index_page?
        !index_config.nil?
      end
    end

    def match_page(page)
      result = {}
      self.class.pattern_config.each_pair do |key, pattern|
        result[key] = pattern.match_page(page)
      end
      result
    end

    def dig_url(url)
      client = Digger::HTTP.new
      page = client.fetch_page(url)
      match_page(page)
    end

    def dig_urls(urls, cocurrence = 1)
      Index.batch(urls, cocurrence){|url| dig_url(url) }
    end

    def dig(cocurrence = 1)
      if self.class.index_page?
        self.class.index_config.process(cocurrence){|url| dig_url(url) }
      end
    end
  end
end