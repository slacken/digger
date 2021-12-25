require 'nokogiri'

module Digger
  class Pattern
    attr_accessor :type, :value, :block

    def initialize(hash = {})
      hash.each_pair{|key, value| send("#{key}=", value) if %w{type value block}.include?(key.to_s)}
    end

    def safe_block
      block && begin
        if block.respond_to?(:call)
          block
        elsif block.strip == '' # 
          nil
        else
          proc{ $SAFE = 2; eval block }.call
        end
      rescue StandardError
        nil
      end
    end

    def self.wrap(hash)
      Hash[hash.map{|key, value| [key, value.is_a?(Pattern) ? value : Pattern.new(value)]}]
    end

    MATCH_MAX = 3

    TYPES_REGEXP = 0.upto(MATCH_MAX).map{|i| "match_#{i}"} + %w{match_many}
    TYPES_CSS = %w{css_one css_many}
    TYPES_JSON = %w{json jsonp}
    
    TYPES = TYPES_REGEXP + TYPES_CSS + TYPES_JSON

    def match_page(page, &callback)
      blk = callback || safe_block
      if TYPES_REGEXP.include?(type) # regular expression
        blk ||= ->(text){ text.strip }
        # content is String
        if type == 'match_many'
          match = page.body.gsub(value).to_a
        else
          index = TYPES_REGEXP.index(type)
          matches = page.body.match(value)
          match = matches.nil? ? nil : matches[index]
        end
      elsif TYPES_CSS.include?(type) # css expression
        blk ||= ->(node){ node.content.strip }
        # content is Nokogiri::HTML::Document
        if type == 'css_one'
          match = page.doc.css(value).first
        else
          match = page.doc.css(value)
        end
      elsif TYPES_JSON.include?(type)
        json = page.send(type)
        match = json_fetch(json, value)
      end
      if match.nil?
        nil
      elsif %w{css_many match_many}.include? type
        match.map{|node| blk.call(node) }.uniq
      else
        blk.call(match)
      end
    rescue
      nil
    end

    def json_fetch(json, keys)
      if keys.is_a? String
        # parse json keys like '$.k1.k2[0]'
        parts = keys.match(/^\$[\S]*$/)[0].scan(/(\.([\w]+)|\[([\d]+)\])/).map do |p|
          p[1].nil? ? { index: p[2].to_i  } : { key: p[1] }
        end
        json_fetch(json, parts)
      elsif keys.is_a? Array
        if keys.length == 0
          json
        else
          pt = keys.shift
          json_fetch(json[pt[:index] || pt[:key]], keys)
        end
      end
    end

    class Nokogiri::XML::Node
      %w{one many}.each do |name|
        define_method "inner_#{name}" do |css, &block| 
          callback = ->(node) do
            if node
              (block || ->(n){n.text.strip}).call(node)
            else
              nil
            end
          end
          if name == 'one' # inner_one
            callback.call(self.css(css).first)
          else # inner_many
            self.css(css).map{|node| callback.call(node)}
          end
        end
      end
      def source
        to_xml
      end
    end # nokogiri
  end
end