require 'digger'
require 'json'

describe Digger::Pattern do
  # it 'json fetch' do
  #   json = JSON.parse('[{"a":1,"b":[1,2,3]}]')
  #   pt = Digger::Pattern.new
  #   expect(pt.json_fetch(json, '$[0]')['a']).to eq(1)
  #   expect(pt.json_fetch(json, '$[0].a')).to eq(1)
  #   expect(pt.json_fetch(json, '$[0].b').length).to eq(3)
  #   expect(pt.json_fetch(json, '$[0].b[2]')).to eq(3)
  # end

  it 'parse cookie & others' do
    page = Digger::HTTP.new.fetch_page('https://xueqiu.com/')
    p1 = Digger::Pattern.new({ type: 'cookie', value: 'xq_a_token', block: ->(v) { "!!#{v}" } })
    # cookie
    result = p1.match_page(page)
    expect(result.length).to eq(42)
    # header
    p2 = Digger::Pattern.new({ type: 'header', value: 'transfer-encoding' })
    expect(p2.match_page(page)).to eq('chunked')
    # get_plain
    p3 = Digger::Pattern.new({ type: 'plain' })
    expect(p3.match_page(page).length).to be > 100
  end
end
