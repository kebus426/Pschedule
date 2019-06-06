# encoding: utf-8
require 'unf'
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

for num in 0..1 do

  month = if t.month + num > 12 then (t.month + num) % 12 else t.month + num end
  month = 12 if month == 0
  year = if t.month + num > 12 then t.year + (t.month+num-1) / 12 else t.year end
  urlDate = "?ey=#{year}&em=#{month}"
  puts urlDate

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
  resultTime = client.query("SELECT day, name FROM time WHERE day>='#{rubyDateToSqlDate(year,month,1,0,0,0)}'")
  
  #今回追加したやつの名前(追加してなくても入れている。問題がないので)
  newNames = []
  
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
        tdNode.css('img').each do |nd|
          eventData[:performance] = nd['alt'] if nd['alt'] != nil
        end
      when 'article2';
        tdNode.css('a').each do |nd|
          eventData[:url] =  nd['href'] if nd['href'] != nil
        end
        eventData[:name] = UNF::Normalizer.normalize(tdNode.text.encode('UTF-8'), :nfkc) if tdNode.text != '' 
      when 'time2'
        text = tdNode.text.encode('UTF-8')
        text = UNF::Normalizer.normalize(text, :nfkc)
        if not text.include?('～') and not text.include?(':') and not text.include?('-') and text != '' 
          eventTime.push(DateTime.new(year,month,day))
          #        eventSpecial.push(text)
          eventData[:special] = text
        elsif text != ''
          text.gsub!(/-/,'～')
          text.gsub!(/ /,'')
          time = text.split('～')
          if(time[0].include?(':'))
            date = time[0].split(':')
            insertDate = DateTime.new(year.to_i,month.to_i,day.to_i,date[0].to_i%24,date[1].to_i,0) + date[0].to_i/24
            eventTime.push(insertDate)
          else
            index = 0
            time.each do |date|
              d = date.split('/')
              if index == 0
                eventData[:special]='開始日'
                index += 1
              else
                eventData[:special]='終了日'
              end
              if month > d[0].to_i
                eventTime.push(DateTime.new(year.to_i+1,d[0].to_i,d[1].to_i,0,0,0))
              else
                eventTime.push(DateTime.new(year.to_i,d[0].to_i,d[1].to_i,0,0,0))
              end
            end
          end
        end
      end
    end
    
  
  
    eventTime.each do |time|
      if not resultEvent.any?{|elm| elm["name"] == eventData[:name]} and not newNames.any?{|elm| elm == eventData[:name]}
        query = "insert into event (genre,name,url) values (\"#{eventData[:genre]}\",\"#{eventData[:name]}\",\"#{eventData[:url]}\")"
        client.query(query)
      end
      if not resultTime.any?{|elm| elm["name"] == eventData[:name]} and not resultTime.any?{|elm| elm["day"] == rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)} 
        query = "insert into time (day,name,special) values ('#{rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)}',\"#{eventData[:name]}\",\"#{eventData[:special]}\")"
        client.query(query)
      end
      if not resultPerformance.any?{|elm| elm["name"] == eventData[:name]} and not newNames.any?{|elm| elm == eventData[:name]}
        query = "insert into performance (name,performance) values (\"#{eventData[:name]}\",\"#{eventData[:performance]}\")"
        client.query(query)
      end
      if not newNames.any?{|elm| elm == eventData[:name]}
        puts eventData[:name]
        newNames.push(eventData[:name])
      end
    end
  end
                                                  
                             
end                             




