require 'nokogiri'

module Digger
  # Extractor patterns definition
  class Pattern
    attr_accessor :type, :value, :block

    def initialize(hash = {})
      hash.each_pair do |key, value|
        send("#{key}=", value) if %w[type value block].include?(key.to_s)
      end
    end

    def safe_block(&default_block)
      if block.nil? || (block.is_a?(String) && block.strip.empty?)
        default_block || ->(v) { v }
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

    TYPES_REGEXP = 0.upto(MATCH_MAX).map { |i| "match_#{i}" } + %w[match_many match_all]
    TYPES_CSS = %w[css_one css_many css_all].freeze
    TYPES_JSON = %w[json jsonp].freeze
    TYPES_OTHER = %w[cookie plain lines header body].freeze

    TYPES = TYPES_REGEXP + TYPES_CSS + TYPES_JSON + TYPES_OTHER

    def match_page(page)
      return unless page.success?

      if TYPES_REGEXP.include?(type) # regular expression
        regexp_match(page.body)
      elsif TYPES_CSS.include?(type) # css expression
        css_match(page.doc)
      elsif TYPES_JSON.include?(type)
        json_match(page)
      elsif TYPES_OTHER.include?(type)
        send("get_#{type}", page)
      end
    end

    def get_header(page)
      header = (page.headers[value.to_s.downcase] || []).first
      safe_block.call(header)
    end

    def get_body(page)
      safe_block.call(page.body)
    end

    def get_plain(page)
      safe_block.call(page.doc&.text)
    end

    def get_lines(page)
      block = safe_block
      page.body.split("\n").map(&:strip).filter { |line| !line.empty? }.map { |line| block.call(line) }
    end

    def get_cookie(page)
      cookie = page.cookies.find { |c| c.name == value }&.value
      safe_block.call(cookie)
    end

    def json_match(page)
      json = page.send(type)
      keys = json_index_keys(value)
      match = json_fetch(json, keys)
      safe_block.call(match)
    end

    def css_match(doc)
      # content is Nokogiri::HTML::Document
      contents = doc.css(value)
      if type == 'css_many'
        block = safe_block { |node| node&.content&.strip }
        contents.map { |node| block.call(node) }
      elsif type == 'css_all'
        block = safe_block
        block.call(contents)
      else
        block = safe_block { |node| node&.content&.strip }
        block.call(contents.first)
      end
    end

    def regexp_match(body)
      # content is String
      if %w[match_many match_all].include? type
        regexp = value.is_a?(Regexp) ? value : Regexp.new(value.to_s)
        matches = body.gsub(regexp).to_a
        if type == 'match_many'
          block = safe_block(&:strip)
          matches.map { |node| block.call(node) }
        else
          block = safe_block
          block.call(matches)
        end
      else
        index = TYPES_REGEXP.index(type)
        matches = body.match(value)
        block = safe_block(&:strip)
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

    class ::Nokogiri::XML::Node
      def inner_one(expr, &block)
        fn = block || ->(node) { node&.content&.strip }
        fn.call(css(expr)&.first)
      end

      def inner_many(expr, &block)
        fn = block || ->(node) { node&.content&.strip }
        css(expr)&.map { |node| fn.call(node) }
      end

      def source
        to_xml
      end

      def inner_number
        content&.match(/\d+/).to_s.to_i
      end
    end
  end
end
