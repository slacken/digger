require 'digger'
require 'json'

describe Digger::Page do
  it 'page json' do
    json_str = '{"a":1,"b":[1,2,3]}'
    j1 = Digger::Page.new('', body: json_str)
    j2 = Digger::Page.new('', body: "hello(#{json_str});")
    expect(j1.json['a']).to eq(1)
    expect(j2.jsonp['a']).to eq(1)
    expect(j1.json['b'][0]).to eq(1)
    expect(j2.jsonp['b'][1]).to eq(2)
  end
end