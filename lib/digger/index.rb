module Digger
  class Index < Struct.new(:pattern, :args)
    class NoBlockError < ArgumentError; end

    def process(cocurrence = 1, &block)
      Index.batch(urls, cocurrence, &block)
    end

    def urls
      @urls ||= begin
        args = self.args.map { |a| a.respond_to?(:each) ? a.to_a : [a] }
        args.shift.product(*args).map { |arg| pattern_applied_url(arg) }
      end
    end

    def pattern_applied_url(arg)
      pattern.gsub('*').each_with_index { |_, i| arg[i] }
    end

    def self.batch(entities, cocurrence = 1, &block)
      raise NoBlockError, 'No block given' unless block

      if cocurrence > 1
        results = Array.new(entities.size)
        entities.each_slice(cocurrence).with_index do |group, idx1|
          threads = []
          group.each_with_index do |entity, idx2|
            index = idx1 * cocurrence + idx2
            threads << Thread.new(entity) do |ent|
              results[index] = block.call(ent)
            end
          end
          threads.each(&:join)
        end
        results
      else
        entities.map { |ent| block.call(ent) }
      end
    end
  end
end
