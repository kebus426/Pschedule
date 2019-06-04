# encoding: utf-8

require 'nokogiri'
require 'open-uri'
require 'csv'
require 'time'
require 'date'
require 'mysql2'
require 'active_support'
require 'active_support/core_ext/date_time/conversions.rb'

def rubyDateToSqlDate(year,month,day,hour,minute,second)
  return "#{year}-#{format('%.2d',month)}-#{format('%.2d',day)} #{format('%.2d',hour)}:#{format('%.2d',minute)}:#{format('%.2d',second)}"
end

url = 'https://idolmaster.jp/schedule/'
t = Time.now
month = t.month
year = t.year
urlDate = "?ey=#{year}&em=#{month}"
puts url+urlDate

charset = nil

html = open(url+urlDate) do |f|
    charset = f.charset
    f.read
end

day = 0
doc = Nokogiri::HTML.parse(html, nil, charset)

client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")

resultEvent = client.query("SELECT genre, name FROM event")
resultPerformance = client.query("SELECT name, performance FROM performance")
resultTime = client.query("SELECT day, name FROM time WHERE day='#{rubyDateToSqlDate(year,month,1,0,0,0)}'")

doc.xpath('//tr').each do |trNode|
  eventData = {}
  eventTime = []
  eventSpecial = []
  trNode.css('td').each do |tdNode|
    next if tdNode['class'] == nil
    case tdNode['class']
    when 'week2'
      eventData[:week] = tdNode.text.encode('UTF-8') if tdNode.text != ''
    when 'genre2'
      eventData[:genre] = tdNode.text.encode('UTF-8') if tdNode.text != '' 
    when 'day2';
      day += 1
      eventData[:id] = day
    when 'performance2';
      puts "hoge"
      tdNode.css('img').each do |nd|
        puts nd['alt']
        eventData[:performance] = nd['alt'] if nd['alt'] != nil
      end
    when 'article2';
      tdNode.css('a').each do |nd|
        eventData[:url] =  nd['href'] if nd['href'] != nil
      end
      eventData[:name] = tdNode.text.encode('UTF-8') if tdNode.text != '' 
    when 'time2'
      text = tdNode.text.encode('UTF-8')
      if text  == '発売日'
        eventTime.push(DateTime.new(year,month,day))
        eventSpecial.push(text)
      elsif text != ''
        time = text.split('～')
        if(time[0].include?(':'))
            date = time[0].split(':')
            eventTime.push(DateTime.new(year.to_i,month.to_i,day.to_i,time[0].to_i,time[1].to_i,0))
        else
          index = 0
          time.each do |date|
            d = date.split('/')
            if index == 0
              eventSpecial.push('開始日')
              index += 1
            else
              eventSpecial.push('終了日')
            end
            if month > d[0].to_i
              eventTime.push(DateTime.new(year.to_i+1,d[0].to_i,d[1].to_i,0,0,0))
            else
               puts d[0]
               puts d[1]
              eventTime.push(DateTime.new(year.to_i,d[0].to_i,d[1].to_i,0,0,0))
            end
          end
        end
      end
    end
  end

  
  
  eventTime.each do |time|
    puts eventData[:genre]
    query = "insert into event (genre,name,url) values (\"#{eventData[:genre]}\",\"#{eventData[:name]}\",\"#{eventData[:url]}\")"
    client.query(query)
    query = "insert into time (day,name,special) values ('#{rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)}',\"#{eventData[:name]}\",\"\")"
    client.query(query)
    query = "insert into performance (name,performance) values (\"#{eventData[:name]}\",\"#{eventData[:performance]}\")"
    client.query(query)
  end
end
                                                  
                             
                             




