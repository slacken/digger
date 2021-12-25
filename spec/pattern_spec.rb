require 'digger'
require 'json'

describe Digger::Pattern do
  it 'json fetch' do
    json = JSON.parse('{"a":1,"b":[1,2,3]}')
    pt = Digger::Pattern.new
    expect(pt.json_fetch(json, '$')['a']).to eq(1)
    expect(pt.json_fetch(json, '$.a')).to eq(1)
    expect(pt.json_fetch(json, '$.b').length).to eq(3)
    expect(pt.json_fetch(json, '$.b[2]')).to eq(3)
  end


end