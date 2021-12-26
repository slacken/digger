require 'digger'
require 'json'

describe Digger::Pattern do
  it 'json fetch' do
    json = JSON.parse('[{"a":1,"b":[1,2,3]}]')
    pt = Digger::Pattern.new
    expect(pt.json_fetch(json, '$[0]')['a']).to eq(1)
    expect(pt.json_fetch(json, '$[0].a')).to eq(1)
    expect(pt.json_fetch(json, '$[0].b').length).to eq(3)
    expect(pt.json_fetch(json, '$[0].b[2]')).to eq(3)
  end


end