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

def normalize(text)
  text = UNF::Normalizer.normalize(text, :nfkc)
  text.gsub!(/-/,'～')
  text.gsub!(/ /,'')
  return text
end

def dataInclude?(array,elms,keywords)
  isIncluded = true
  keywords.each do |keyword|
    isIncluded = isIncluded and array.any?{|aElms| aElms[keyword] == elms[keyword]}
  end
  return isIncluded
end

url = 'https://idolmaster.jp/schedule/'
t = Time.now

  
client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
  
existData = client.query("SELECT day, name, performance FROM time NATURAL JOIN event NATURAL JOIN performance")

newData = {}

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

  doc.xpath('//tr').each do |trNode|
    eventData = {}
    eventTime = []
    eventSpecial = []
    trNode.css('td').each do |tdNode|
      next if tdNode['class'] == nil
      case tdNode['class']
      when 'week2'
        eventData["week"] = tdNode.text.encode('UTF-8') if tdNode.text != ''
      when 'genre2'
        eventData["genre"] = tdNode.text.encode('UTF-8') if tdNode.text != '' 
      when 'day2';
        day += 1
      when 'performance2';
        tdNode.css('img').each do |nd|
          eventData["performance"] = nd['alt'] if nd['alt'] != nil
        end
      when 'article2';
        tdNode.css('a').each do |nd|
          eventData["url"] =  nd['href'] if nd['href'] != nil
        end
        eventData["name"] = tdNode.text.encode('UTF-8') if tdNode.text != '' 
      when 'time2'
        text = tdNode.text.encode('UTF-8')
        text = normalize(text)
        if not text.include?('～') and not text.include?(':') and text != ''
          eventTime.push(DateTime.new(year,month,day))
          eventData["special"] = text
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
                eventData["special"] = '開始日'
                index += 1
              else
                eventData["special"] = '終了日'
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

      puts existData.any?{|elm| elm["name"] == eventData["name"]}
      if not existData.any?{|elm| elm["name"] == eventData["name"]} and not newData.any?{|elm| elm["name"] == eventData["name"]}
        query = "insert into event (genre,name,url) values (\"#{eventData["genre"]}\",\"#{eventData["name"]}\",\"#{eventData["url"]}\")"
        client.query(query)
      end
      
      #今回追加したやつの名前(追加してなくても入れている
      puts day = rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)
      puts day 
      puts '2019-06-03 21:00:00 +0900' == day
      puts existData.any?{|elm| elm["day"] == (day)}
      puts eventData["name"]
      #      existData.select{|elm| elm["name"] == 'デレラジ☆(スター)'}.each do |hoge|
      #        puts hoge["day"]
      #      end
      if not existData.any?{|elm| elm["name"] == eventData["name"] and elm["day"] == day} and not newData.any?{|elm| elm["name"] == eventData["name"] and elm["day"] == day}
        query = "insert into time (day,name,special) values ('#{rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)}',\"#{eventData["name"]}\",\"#{eventData["special"]}\")"
        client.query(query)
      end
      
      puts "debug"
      if not dataInclud?(existData,eventData,["name","performance"]) and not dataIncluded?(newData,eventData,["name","performance"])
        query = "insert into performance (name,performance) values (\"#{eventData["name"]}\",\"#{eventData["performance"]}\")"
        client.query(query)
      end
      
      if not dataInclud?(newData,eventData,["name","performance","day"]) and not dataIncluded?(existData,eventData,["name","performance","day"])
        newElm["name"] = eventData["name"]
        newElm["performance"] = eventData["performance"]
        newElm["day"] =  day
        newData.push(newElm)
      end
    end
  end                                                                    
end                             




