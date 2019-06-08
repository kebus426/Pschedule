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
  text.gsub!(/-|〜/,'～')
  text.gsub!(/ /,'')
  return text
end

url = 'https://idolmaster.jp/schedule/'
t = Time.new(2016,7,1,0,0,0)#Time.now

  
client = Mysql2::Client.new(host: "localhost",username: "root", password: "",database: "pschedule")
  
existData = client.query("SELECT day, name, performance FROM time NATURAL JOIN event NATURAL JOIN performance ORDER BY day")

#existData.each do |elm|
#  puts elm["name"]
#end

newData = []

for num in 0..40 do

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
          eventData["performance"] = nd['alt'].split('、') if nd['alt'] != nil
        end
      when 'article2';
        tdNode.css('a').each do |nd|
          eventData["url"] =  nd['href'] if nd['href'] != nil
        end
        eventData["name"] = UNF::Normalizer.normalize(tdNode.text.encode('UTF-8'), :nfkc) if tdNode.text != '' 
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
            eventTime.push(DateTime.new(year.to_i,month.to_i,day.to_i,date[0].to_i % 24,date[1].to_i,0) + date[0].to_i / 24)
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
      if not existData.any?{|elm| elm["name"] == eventData["name"]} and not newData.any?{|elm| elm["name"] == eventData["name"]}
        query = "insert into event (genre,name,url) values (\"#{eventData["genre"]}\",\"#{eventData["name"]}\",\"#{eventData["url"]}\")"
        client.query(query)
      end
      
      dayStr = rubyDateToSqlDate(time.year,time.month,time.day,time.hour,time.minute,time.second)
      
      #今回追加したやつの名前(追加してなくても入れている
      if not existData.any?{|elm| elm["name"] == eventData["name"] and elm["day"].to_s == dayStr + " +0900"} and not newData.any?{|elm| elm["name"] == eventData["name"] and elm["day"] == dayStr}
        query = "insert into time (day,name,special) values ('#{dayStr}',\"#{eventData["name"]}\",\"#{eventData["special"]}\")"
        client.query(query)
      end

      eventData["performance"].each do |perfo|  
        if not existData.any?{|elm| elm["name"] == eventData["name"] and elm["performance"] == perfo}  and not newData.any?{|elm| elm["name"] == eventData["name"] and elm["performance"] == perfo} 
          query = "insert into performance (name,performance) values (\"#{eventData["name"]}\",\"#{perfo}\")"
          client.query(query)
        end
        
        #day,name,performanceだけ切り出して==で比較する?
        if not existData.any?{|elm| elm["name"] == eventData["name"] and elm["performance"] == perfo and elm["day"] == eventData["day"]} and not newData.any?{|elm| elm["name"] == eventData["name"] and elm["performance"] == perfo and elm["day"] == eventData["day"]}
          newElm = {}
          newElm["name"] = eventData["name"]
          newElm["performance"] = perfo
          newElm["day"] =  dayStr
          newData.push(newElm)
        end
      end
    end
  end                                                                    
end                             




