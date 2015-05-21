require 'digger'

class Item < Digger::Model
  # css_many sites: '.sites>a>span'
  css_one logo: '.logo'
  css_one title: '.title'

  validate_presence :sites
  validate_includeness :sites, :logo, :title
end