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
    
    TYPES = 0.upto(MATCH_MAX).map{|i| "match_#{i}"} + %w{match_many css_one css_many}

    def regexp?
      TYPES.index(type) <= MATCH_MAX + 1 # match_many in addition
    end

    def match_page(page, &callback)
      blk = callback || safe_block
      if regexp? # regular expression
        index = TYPES.index(type)
        blk ||= ->(text){text.strip}
        # content is String
        if type == 'match_many'
          match = page.body.gsub(value).to_a
        else
          matches = page.body.match(value)
          match = matches.nil? ? nil : matches[index]
        end
      else # css expression
        blk ||= ->(node){node.content.strip}
        # content is Nokogiri::HTML::Document
        if type == 'css_one'
          match = page.doc.css(value).first
        elsif type == 'css_many' # css_many
          match = page.doc.css(value)
        end
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