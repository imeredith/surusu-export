require 'rubygems'
require 'scrapi'
require 'digest/md5'
require 'net/http'

username = ARGV[0]
password = Digest::MD5.hexdigest(ARGV[1])

http = Net::HTTP.new('surusu.com')

auth_cookie = "usernamecookie=#{username}; passwordcookie=#{password}"

headers = {
  'Cookie' => auth_cookie,
  'Referer' => 'http://surusu.com/viewallitems.php',
  'Content-Type' => 'application/x-www-form-urlencoded'
}
surusu_row = Scraper.define do
  array :columns
  process "td[width=40%]", :columns => :text 
  result :columns
end

surusu = Scraper.define do
  array :rows
  process "form[name=itemtable] table tr",
          :rows => surusu_row
  result  :rows
end
surusu.parser_options :show_warnings => true, :char_encoding => 'utf8'

#### Change decks #####
post_data = "selecteddeck=#{ARGV[2]}&switchdeck=Switch Deck&referringpage=/viewallitems.php"
resp, data = http.post("/switchdeck.php", post_data, headers)
headers['Cookie'] = resp["set-cookie"].split(";")[0]

#### page enumarator ####
page_numbers = Enumerator.new do |yielder|
  number = 1
  loop do
    yielder.yield number
    number += 1
  end
end

#### get first page
loop do
  resp, data = http.get("/viewallitems.php?page=#{page_numbers.next()}", headers)
  cards = surusu.scrape(data)
  if cards.nil?
    break
  end
  cards.each do |front, back|
    puts "#{front.gsub(/\n/,'<br/>')}\t#{back.gsub(/\n/,'<br/>')}"
  end
end











