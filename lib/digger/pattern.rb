require 'nokogiri'

module Digger
  # Extractor patterns definition
  class Pattern
    attr_accessor :type, :value, :block

    def initialize(hash = {})
      hash.each_pair { |key, value| send("#{key}=", value) if %w[type value block].include?(key.to_s)}
    end

    def safe_block(&default_block)
      if block.nil? || (block.is_a?(String) && block.strip.empty?)
        default_block
      elsif block.respond_to?(:call)
        block
      else
        proc {
          $SAFE = 2
          eval block
        }.call
      end
    end

    def self.wrap(hash)
      hash.transform_values { |value| value.is_a?(Pattern) ? value : Pattern.new(value) }
    end

    MATCH_MAX = 3

    TYPES_REGEXP = 0.upto(MATCH_MAX).map { |i| "match_#{i}" } + %w[match_many]
    TYPES_CSS = %w[css_one css_many].freeze
    TYPES_JSON = %w[json jsonp].freeze

    TYPES = TYPES_REGEXP + TYPES_CSS + TYPES_JSON

    def match_page(page)
      return unless page.success?
      if TYPES_REGEXP.include?(type) # regular expression
        regexp_match(page.body)
      elsif TYPES_CSS.include?(type) # css expression
        css_match(page.doc)
      elsif TYPES_JSON.include?(type)
        json_match(page)
      end
    end

    def json_match(page)
      block = safe_block { |j| j }
      json = page.send(type)
      keys = json_index_keys(value)
      match = json_fetch(json, keys)
      block.call(match)
    end

    def css_match(doc)
      block = safe_block { |node| node.content.strip }
      # content is Nokogiri::HTML::Document
      contents = doc.css(value)
      if type == 'css_many'
        contents.map { |node| block.call(node) }.uniq
      else
        block.call(contents.first)
      end
    end

    def regexp_match(body)
      block = safe_block(&:strip)
      # content is String
      if type == 'match_many'
        body.gsub(value).to_a.map { |node| block.call(node) }.uniq
      else
        index = TYPES_REGEXP.index(type)
        matches = body.match(value)
        block.call(matches[index]) unless matches.nil?
      end
    end

    def json_fetch(json, keys)
      if keys.empty?
        json
      else
        pt = keys.shift
        json_fetch(json[pt[:index] || pt[:key]], keys)
      end
    end

    def json_index_keys(keys)
      keys.to_s.match(/^\$\S*$/)[0].scan(/(\.(\w+)|\[(\d+)\])/).map do |p|
        p[1].nil? ? { index: p[2].to_i } : { key: p[1] }
      end
    end

    private :json_index_keys, :json_fetch

    # Nokogiri node methods
    class Nokogiri::XML::Node
      %w[one many].each do |name|
        define_method "inner_#{name}" do |css, &block|
          callback = ->(node) { (block || ->(n) { n.text.strip }).call(node) if node }
          if name == 'one' # inner_one
            callback.call(self.css(css).first)
          else # inner_many
            self.css(css).map { |node| callback.call(node) }
          end
        end
      end
      def source
        to_xml
      end
    end
  end
end
