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

  it 'slow down' do
    list = [1, 2, 3, 4]
    conf = {
      sleep_range_seconds: 1...2,
      fail_unit_seconds: 1,
      fail_max_cnt: 2,
      when_fail: ->(_, e, nth) { puts "#{nth}: #{e.message}" }
    }
    pt = Digger::Index.slow_down(list, conf) do |num|
      raise 'error' if num == 3
      num
    end
    p pt
    expect(pt.size).to eq(2)
  end
end
