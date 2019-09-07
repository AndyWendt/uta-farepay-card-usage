require 'open-uri'
require 'openssl'
require 'mechanize'
require 'json'
require 'pry'

url = 'https://farepay.rideuta.com'

store = OpenSSL::X509::Store.new
store.add_file File.dirname(__FILE__) + '/digicert-root-ca.crt'

agent = Mechanize.new
agent.cert_store = store
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
page = agent.get(url)

login = page.links.find { |link| link.text.include? 'Log In'}

pp login.text
