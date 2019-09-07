require 'open-uri'
require 'openssl'
require 'mechanize'
require 'json'
require 'pry'

url = 'https://farepay.rideuta.com'

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
page = agent.get(url)

login = page.links.find { |link| link.text.include? 'Log In'}

pp login.text
