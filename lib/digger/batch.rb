module Digger
  module Batch
    class NoBlockError < ArgumentError; end
    
    def self.do(cocurrence, entities, &block)
      raise NoBlockError, "No block given" unless block
      entities.each_slice(cocurrence) do |group|
        threads = []
        group.each do |entity|
          threads << Thread.new(entity) do |ent|
            block.call(ent)
          end
        end
        threads.each{|thread| thread.join}
      end
  end
end