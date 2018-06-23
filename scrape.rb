require 'nokogiri'
require 'open-uri'
require 'csv'

url = 'https://idolmaster.jp/schedule/'

charset = nil

html = open(url) do |f|
    charset = f.charset
    f.read
end

doc = Nokogiri::HTML.parse(html, nil, charset)
doc.xpath('//td').each do |node|
  p node
end
