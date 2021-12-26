require 'digger'

http = Digger::HTTP.new
page = http.fetch_page('http://www.baidu.com/')

pattern = Digger::Pattern.new({ type: 'css_many', value: '#s-top-left>a' })

class Item < Digger::Model
  css_many sites: '#s-top-left>a'
  validate_presence :sites
  validate_includeness :sites
end

describe Digger do
  it "http should fetch a page" do
    expect(page.code).to eq(200)
  end

  it "pattern should match content" do
    sites = pattern.match_page(page)
    expect(sites.include?('新闻')).to eq(true)
  end

  it "model should dig content" do
    item = Item.new.match_page(page)
    expect(item[:sites].include?('新闻')).to be(true)
  end

  it "validation support" do
  end

  it "index multiple threading" do
    
  end
end