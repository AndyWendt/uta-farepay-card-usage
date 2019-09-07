require 'open-uri'
require 'openssl'
require 'mechanize'
require 'json'
require 'pry'
require 'highline'

cli = HighLine.new
username = cli.ask("Enter your username:")
password = cli.ask("Enter your password: ") { |q| q.echo = false }

url = 'https://farepay.rideuta.com'

agent = Mechanize.new
agent.verify_mode = OpenSSL::SSL::VERIFY_NONE
page = agent.get(url)

# loginLink = page.links.find { |link| link.text.include? 'Log In'}

form = page.forms.find { |form| form.action.include? '/resources/j_spring_security_check' }

form.j_username = username
form.j_password = password

page = agent.submit(form)
pp page
