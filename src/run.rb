require 'open-uri'
require 'openssl'
require 'nokogiri'
require 'json'

url = 'https://farepay.rideuta.com'
html = open(url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE})

doc = Nokogiri::HTML(html)
login = doc.css('.login')
pp login.text
