require 'digger'

describe Digger::Index do
  it 'batch digger' do
    list = [1, 2, 3, 4, 5, 6, 7, 8]
    pt = Digger::Index.batch(list, 3) do |num|
      sleep(rand(1..3))
      "##{num}"
    end
    expect(pt.join).to eq(list.map { |num| "##{num}" }.join)
  end
end
