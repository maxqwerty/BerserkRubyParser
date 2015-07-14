#coding: utf-8
require 'rubygems'
require 'hpricot'
require 'open-uri'
require "net/http"
require 'sqlite3'

def check_url_bers(file_name)
  uri = URI.parse(file_name)
  request = Net::HTTP.new(uri.host, uri.port)
  puts file_name + ' is ==> ' + request.request_head(file_name).code
  request.request_head(file_name).code.to_i == 200
end

def clear_string(str)
  str.delete!("\t")
  str.delete!("\n")
  str.delete!("\r")
  str.delete!("()")
  str.delete!(160.chr(Encoding::UTF_8))
  str
end

$db = SQLite3::Database.new "berserk.db"
puts $db.get_first_value 'SELECT SQLITE_VERSION()'

$db.execute "CREATE TABLE IF NOT EXISTS Card
    (Id INTEGER PRIMARY KEY, 
    card_ind INTEGER, 
    fname TEXT, 
    rarity TEXT, 
    edition TEXT, 
    ed_numb INTEGER,
    element TEXT, 
    price INTEGER, 
    elite INTEGER, 
    health INTEGER, 
    movement INTEGER, 
    light_strike INTEGER, 
    middle_strike INTEGER, 
    hard_strike INTEGER, 
    additions TEXT, 
    descr TEXT,
    legend TEXT)"
    
$stm = $db.prepare ("SELECT * FROM Card")
    
$ind = ARGV.first.to_i

$cards_list = []

class Card 
  def initialize
    @card_ind = 0
    @fname = 'buf'
    @rarity  = ''
    @edition = ''
    @ed_numb = 0
    @element = ''
    @price = 0
    @elite = 0
    @health = 0
    @movement = 0
    @light_strike = 0
    @middle_strike = 0
    @hard_strike = 0
    @additions = ''
    @descr = ''
    @legend = ''
  end
  attr_accessor :card_ind, :fname, :rarity, :edition, :ed_numb, :element, :price, :elite, :health, :movement, :light_strike, :middle_strike, :hard_strike, :additions, :descr, :legend
end
    
class Parser
  def start i
    index = i
      
    url = 'http://berserk.ru/card?card=' + index.to_s
    if check_url_bers(url)
      
      the_card = Card.new
      
      hp = Hpricot(open(url))
      
      the_card.card_ind = index
      
      image = hp.at("div.product_image/img") ? hp.at("div.product_image/img")['src'] : nil
      
      char_name = hp.at("div.product_information/h1") ? hp.at("div.product_information/h1").inner_text : 'no_name'
      
      fname = the_card.card_ind.to_s + '_' + char_name + ".png"
      puts the_card.fname = fname
      
      rarity = hp.at("#InlineEnclosure-5") ? hp.at("#InlineEnclosure-5").inner_text : 'no_rarity'
      rarity = clear_string(rarity)
      rarity.sub!(/Редкость:/, '')
      puts the_card.rarity = rarity
      
      edition = hp.at("#InlineEnclosure-7") ? hp.at("#InlineEnclosure-7").inner_text : 'no_edition'
      edition = clear_string(edition)
      edition.sub!(/Выпуск:/, '')
      puts the_card.edition = edition
      
      number = '999'
      (hp/"div.main_stats/div").each do |div|
	if div.inner_text.include?("Номер:")
	  number = div.inner_text
	  number = clear_string(number)
	  number.sub!(/Номер:/, '')
	end
      end
      puts the_card.ed_numb = number.to_i
      
      element = hp.at("#InlineEnclosure-9") ? hp.at("#InlineEnclosure-9").inner_text : 'no_element'
      element = clear_string(element)
      element.sub!(/Стихия:/, '')
      puts the_card.element = element
      
      price = hp.at("#InlineEnclosure-10") ? hp.at("#InlineEnclosure-10").inner_text : '999'
      price = clear_string(price)
      price.sub!(/Стоимость:/, '')
      puts the_card.price = price.to_i
      
      elite = 'empty'
      elite = hp.at("#InlineEnclosure-10/img") ? hp.at("#InlineEnclosure-10/img")['src'] : elite
      puts the_card.elite = elite.include?('34153') ? 1 : 0
      
      health = hp.at("#InlineEnclosure-11") ? hp.at("#InlineEnclosure-11").inner_text : '999'
      health = clear_string(health)
      health.sub!(/Здоровье:/, '')
      puts the_card.health = health.to_i

      movement = hp.at("#InlineEnclosure-12") ? hp.at("#InlineEnclosure-12").inner_text : '999'
      movement = clear_string(movement)
      movement.sub!(/Движение:/, '')
      puts the_card.movement = movement
      
      fight_force = hp.at("#InlineEnclosure-13") ? hp.at("#InlineEnclosure-13").inner_text : '999-999-999'
      fight_force = clear_string(fight_force)
      fight_force.sub!(/Простой удар:/, '')
      light_strike = fight_force.sub(/-(\d)*-(\d)*/,'')
      middle_strike = fight_force.sub(/(\d)*-/,'').sub(/-(\d)*/,'')
      hard_strike = fight_force.sub(/(\d)*-(\d)*-/,'')
      puts the_card.light_strike = light_strike
      puts the_card.middle_strike = middle_strike
      puts the_card.hard_strike = hard_strike
      
      additions = ''
      if hp.at("div.description/img")
	if hp.at("div.description/img")['title']
	  (hp/"div.description/img").each do |title|
	    if title['title']
	      additions = additions + title['title'] + '|'
	    end
	  end
	end
      end
      puts the_card.additions = additions
      
      description = ''
      (hp/"div.description").each do |txt|
	description = txt.inner_text
      end
      puts the_card.descr = description
      
      legend = ''
      (hp/"div.legend").each do |txt|
	legend = txt.inner_text
      end
      puts the_card.legend = legend
      
      $cards_list.push(the_card)
      
      #page = open(url)
      #text = page.read
      #image = text.scan(%r{product_image"><img src="./(.*)"></div><h1>})
      #char_name = text.scan(%r{</div><h1>(.*)</h1><div class="main_stats">})
      
      
      if image
	img_url = 'http://berserk.ru/' + image #.first.first
	uri = URI.parse("http://berserk.ru")
	card = img_url.sub(/http:\/\/berserk.ru/, '')
	http = Net::HTTP.new(uri.host, uri.port)
	http.start do |http|
	  resp = http.get("#{card}")
	  open("#{'images/' + fname}", "wb") do |file|
	      file.write(resp.body)
	      puts fname
	  end
	end
      end
    end
  end
end

while $ind < ARGV.first.to_i + 500
  t1 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t2 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t3 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t4 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t5 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t6 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t7 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t8 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t9 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t10 = Thread.fork {p1 = Parser.new; p1.start($ind += 1)}
  t1.join
  t2.join
  t3.join
  t4.join
  t5.join
  t6.join
  t7.join
  t8.join
  t9.join
  t10.join
end



$cards_list.each do |card|
  $stm = $db.prepare "INSERT INTO Card(card_ind, fname, rarity, edition, ed_numb, element, price, elite, 
  health, movement, light_strike, middle_strike, hard_strike, additions, descr, legend)
			  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"
  $stm.bind_params(card.card_ind, card.fname, card.rarity, card.edition, card.ed_numb, card.element, card.price, card.elite, card.health, card.movement, card.light_strike, card.middle_strike, card.hard_strike, card.additions, card.descr, card.legend)
  $stm.execute 
  puts $db.last_insert_row_id
end

puts 'last id is: ' + $ind.to_s

$stm.close
