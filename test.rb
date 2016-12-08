require './BookingCom_module.rb'
require 'mechanize'
require 'net/http'
require 'net/https'
require 'uri'
include BookingComModule

username = "username"
password = "password"

def booking_login(username, password)

  uri = URI.parse("https://admin.booking.com/hotel/hoteladmin/login.html")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  cookie = response.response['set-cookie']
  puts response.code
  puts cookie


  #cookie = response['set-cookie']
  noko = Nokogiri.HTML(response.body).at_xpath("//section[@id='hotel_admin_login']/form/div/input[@id='ses']")
  token = noko['value']
  

  # LOGIN POST
  uri = URI.parse("https://admin.booking.com/hotel/hoteladmin/login.html")
  data = URI.encode("lang=en&login=Login&ses=#{token}&loginname=#{username}&password=#{password}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.request_uri)
  request.body = data
  request['Cookie'] = cookie
  response = http.request(request)
  cookie = response.response['set-cookie']
  location = response.response['location']
  puts response.code
  puts location
  puts cookie
  
  
  uri = URI.parse("https://admin.booking.com#{location}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Cookie'] = cookie
  response = http.request(request)
  cookie = response.response['set-cookie']
  location = response.response['location']
  puts response.code
  puts location
  puts cookie

  
  
  uri = URI.parse("https://admin.booking.com#{location}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Cookie'] = cookie
  response = http.request(request)
  #cookie = response.response['set-cookie']
  location = response.response['location']
  puts response.code
  puts location
  puts cookie
  
  
  uri = URI.parse("https://admin.booking.com#{location}")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Get.new(uri.request_uri)
  request['Cookie'] = cookie
  response = http.request(request)
  puts response.inspect
  
  if response.kind_of? Net::HTTPOK
    puts ":)"
  else
    puts ":("
  end




  puts "-----------------------------------------------------"

 
  return token, cookie
  
end



token, cookie = booking_login(username, password)

auth_token = cookie.sub(/.*=([0-9]*);(.*)/) { $1 }
cookie_jar = Mechanize::Cookie.new("auth_token", auth_token)
cookie_jar.domain = "admin.booking.com"
cookie_jar.path = "/"

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
agent.cookie_jar.add(cookie_jar)


# Grab list of rooms ID
roomID_list = Array.new
properties_url = "https://admin.booking.com/hotel/hoteladmin/extranet_ng/manage/rooms.html?lang=en&ses=#{token}&hotel_id=#{username}"
agent.get(properties_url).search("div#room_summaries").css("a.edit-room.btn-default.btn").each do |link|
  roomID_list << link["data-room-id"]
end


# For test purpose, use RoomID #1
roomID = roomID_list[0]





data = URI.encode('data={"dates":{"2015-04-21":"4916606"},"rooms_to_sell":"0","room_price":"400","min_stay_through":3}')
puts data
headers= {
  'Cookie' => cookie,
}

# Construct the URL for the JSON request
url = "https://admin.booking.com"
uri = URI.parse(url)
http = Net::HTTP.new(uri.host, uri.port)
http.use_ssl = true
http.verify_mode = OpenSSL::SSL::VERIFY_NONE


# Send the JSON request to create a reservation
res = http.start { |req|
  req.send_request('POST', "/hotel/hoteladmin/extranet_ng/manage/json/calendarsavedates.json?room_id=#{roomID}&roomtype_id=1&rate_id=4916606&lang=en&ses=#{token}&hotel_id=#{username}", data, headers)
}


# Return the reservationID or -1 in case of failure
if res.kind_of? Net::HTTPSuccess
  puts ":)"
else
  puts ":("
end


# Update the availability / price / min stay through dynamic code
# Log any errors and make sure than success / error is caught before terminating.
# The script must accept and update single date and accept requests to update a batch of dates in one shot. Booking.com allows both