module BookingComModule

  # Log into the admin panel of booking.com
  #
  # @return [String] The session token (SES) and the session cookie
  # @overload booking_login()
  #   @args username [String] Username used to login (or hotel ID).
  #   @args password [String] Password of the account.
  def booking_login(username, password)
    
    # Go to the login page
    uri = URI.parse("https://admin.booking.com/hotel/hoteladmin/login.html")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    cookie = response.response['set-cookie']
  
  
    # Get the SES token for the session
    noko = Nokogiri.HTML(response.body).at_xpath("//section[@id='hotel_admin_login']/form/div/input[@id='ses']")
    token = noko['value']
    
  
    # Perform the login process (1 POST and 3 Redirected GET)
    
    # Login POST
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

    
    # First redirection
    uri = URI.parse("https://admin.booking.com#{location}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Cookie'] = cookie
    response = http.request(request)
    cookie = response.response['set-cookie']
    location = response.response['location']
  

    # Second redirection
    uri = URI.parse("https://admin.booking.com#{location}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Cookie'] = cookie
    response = http.request(request)
    location = response.response['location']

    
    # Third and last redirection
    uri = URI.parse("https://admin.booking.com#{location}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Get.new(uri.request_uri)
    request['Cookie'] = cookie
    response = http.request(request)

    
    if response.kind_of? Net::HTTPOK
      puts "Login succeed"
    else
      puts "Login failed"
      token = cookie = false
    end
    
    puts "---------------------------------------------------------------------"
    
    return token, cookie

  end
  
  
################################################################################
################################################################################
  
  
  # Get all the room ID from an account.
  #
  # @return [Array] The list of room's ID
  # @overload get_roomID_list()
  #   @args username [String] Username used to login (or hotel ID).
  #   @args token [String] The token session (SES) from the login process.
  #   @args cookie [String] The session cookie from the login process.
  def get_roomID_list(username, token, cookie)
    
    # Use the cookie from login process to create Mechanize::CookieJar
    auth_token = cookie.sub(/.*=([0-9]*);(.*)/) { $1 }
    cookie_jar = Mechanize::Cookie.new("auth_token", auth_token)
    cookie_jar.domain = "admin.booking.com"
    cookie_jar.path = "/"
    
    # Create the Mechanize agent
    agent = Mechanize.new
    agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
    agent.cookie_jar.add(cookie_jar)
    
    
    # Grab the list of all rooms ID
    roomID_list = Array.new
    properties_url = "https://admin.booking.com/hotel/hoteladmin/extranet_ng/manage/rooms.html?lang=en&ses=#{token}&hotel_id=#{username}"
    agent.get(properties_url).search("div#room_summaries").css("a.edit-room.btn-default.btn").each do |link|
      roomID_list << link["data-room-id"]
    end
    
    puts "We found #{roomID_list.length} rooms ID in your account."
    puts "---------------------------------------------------------------------"
    
    return roomID_list
    
  end
  
  
################################################################################
################################################################################
  
  
  # Update the calendar.
  #
  # @raise [FalseClass] Error raised when supplied arguments are not valid and return.
  # @return [TrueClass] Success when the calendar is updated as expected
  # @overload update_calendar()
  #   @args username [String] Username used to login (or hotel ID).
  #   @args token [String] The token session (SES) from the login process.
  #   @args cookie [String] The session cookie from the login process.
  #   @args roomID [String] The room ID to update.
  #   @args dates [String] or [Array] The dates to updates. Must be YEAR-MONTH-DAY
  #   @args rooms_to_sell [String] Is the room available ? "1" : Yes | "0" : No
  #   @args room_price [String] The price of the room.
  #   @args min_stay_through [Integer] The minimum stay for the room.
  def update_calendar(username, token, cookie, roomID, dates, rooms_to_sell, room_price, min_stay_through)
    
    # Construct the data to send according to parameters
    data_string = "data={\"dates\":{"
    
    if dates.is_a?(String)
      data_string += "\"#{dates}\":\"4916606\""
    elsif dates.is_a?(Array)
      # For each dates
      dates.each {|x| data_string += "\"#{x}\":\"4916606\"," }
      # Remove the last ','
      data_string = data_string[0...-1]
    else
      puts "You must specified at least one date"
      puts "---------------------------------------------------------------------"
      return false
    end
    
    
    if !rooms_to_sell and !room_price and !min_stay_through
      puts "You must specified at least one of the following data : rooms_to_sell, room_price, min_stay_through"
      puts "---------------------------------------------------------------------"
      return false
    end
    
    
    data_string += "}"
    
    
    if rooms_to_sell
      data_string += ",\"rooms_to_sell\":\"#{rooms_to_sell}\""
    end
    
    
    if room_price
      data_string += ",\"room_price\":\"#{room_price}\""
    end
    
    
    if min_stay_through
      data_string += ",\"min_stay_through\":#{min_stay_through}"
    end
    
    
    data_string += "}"
    
    
    data = URI.encode(data_string)

    
    # Create headers
    headers = {
      'Cookie' => cookie,
    }
    
    # Construct the URL for the JSON request
    url = "https://admin.booking.com"
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    
    # Send the POST to update calendar
    res = http.start { |req|
      req.send_request('POST', "/hotel/hoteladmin/extranet_ng/manage/json/calendarsavedates.json?room_id=#{roomID}&roomtype_id=1&rate_id=4916606&lang=en&ses=#{token}&hotel_id=#{username}", data, headers)
    }
    
    
    # Return the reservationID or -1 in case of failure
    if res.kind_of? Net::HTTPSuccess
      puts "Your room #{roomID} was successfully updated ! Here are the update string sent :"
      puts data_string
      retval = true
    else
      puts "Error during the update process of your room #{roomID} !"
      retval = false
    end
    
    puts "---------------------------------------------------------------------"
    
    return retval
    
  end
    
end