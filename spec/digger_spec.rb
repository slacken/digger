require 'digger'

http = Digger::HTTP.new
page = http.fetch_page('http://nan.so/')

pattern = Digger::Pattern.new({type: 'css_many', value: '.sites>a>span' })

class Item < Digger::Model
  css_many sites: '.sites>a>span'
end

describe Digger do
  it "http should fetch a page" do
    expect(page.code).to eq(200)
  end

  it "pattern should match content" do
    sites = pattern.match_page(page)
    expect(sites.include?('百度网盘')).to eq(true)
  end

  it "model should dig content" do
    item = Item.new.match_page(page)
    expect(item[:sites].include?('读远')).to be(true)
  end

  it "index multiple threading" do
    
  end
end