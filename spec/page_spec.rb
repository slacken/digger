require 'digger'
require 'json'
require 'uri'

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

  it 'fetch baidu' do
    http = Digger::HTTP.new
    page = http.fetch_page('http://www.baidu.com/')
    expect(page.code).to eq(200)
  end

  it 'page uri' do
    link ='https://www.baidu.com/s?wd=%E5%93%88%E5%93%88#hello'
    link = link.to_s.encode('utf-8', 'binary', invalid: :replace, undef: :replace, replace: '').gsub(/#[\w]*$/, '')
    p link
  end
end