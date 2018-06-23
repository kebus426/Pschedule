# encoding: utf-8

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
  puts node.text.encode('UTF-8')
end


