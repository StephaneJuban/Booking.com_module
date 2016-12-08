require './BookingCom_module.rb'
require 'mechanize'
require 'net/http'
require 'net/https'
require 'uri'
include BookingComModule

username = "username"
password = "password"


token, cookie = booking_login(username, password)

# Check that no error occured during the login process
if token and cookie

  # Get the roomID list
  roomID_list = get_roomID_list(username, token, cookie)
  
  
  # For test purpose, use RoomID #1
  roomID = roomID_list[0]
  
  
  # Update #1 : Update for one date
  update_calendar(username, token, cookie, roomID, "2015-04-21", "1", "250", 1)
  
  
  # Update #2 : Update for multiple dates
  dates = ["2015-04-22", "2015-04-23", "2015-04-25"]
  update_calendar(username, token, cookie, roomID, dates, "1", "250", 1)
  
  
  # Update #3 : Update only the availability
  dates = ["2015-04-24"]
  update_calendar(username, token, cookie, roomID, dates, "0", nil, nil)
  
  
  # Update #4 : Update only the price
  dates = ["2015-04-22", "2015-04-23", "2015-04-25"]
  update_calendar(username, token, cookie, roomID, dates, nil, "600", nil)
  
  
  # Update #5 : Update only the minimum stay
  dates = ["2015-04-30"]
  update_calendar(username, token, cookie, roomID, dates, nil, nil, 7)
  
  
  # Update #6 : Update only the minimum stay
  dates = ["2015-04-29"]
  update_calendar(username, token, cookie, roomID, dates, "1", nil, 6)

end
