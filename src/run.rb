require 'kimurai'
require 'yaml'
require 'pry'
require 'monetize'
require 'highline'

class UtaSpider < Kimurai::Base
  @name = "UTA Spider"
  @engine = :selenium_chrome
  @start_urls = ['https://farepay.rideuta.com']

  def parse(response, url:, data: {})
    credentials = YAML.load_file(File.expand_path('~') + '/.uta/secret.yml')
    cli = HighLine.new
    @positive = []
    @negative = []
    @total = 0

    browser.fill_in "j_username", with: credentials['username']
    browser.fill_in "j_password", with: credentials['password']
    browser.click_button "Login"

    # Update response to current response after interaction with a browser
    response = browser.current_response
    browser.find('//*[@id="list-nav"]/li[4]/a').click
    sleep(1)
    browser.find('//*[@id="cardSeletor"]/option[2]').click
    browser.find('//*[@id="dateRangeSeletor"]/option[2]').click
    sleep(1)

    number = browser.find('//*[@id="displayTagDiv"]/span').text[/\d+/].to_i
    process_amounts
    pages = (number.to_f / 5.to_f).ceil
    page = 2

    while page <= pages
      links = browser.find('//*[@id="displayTagDiv"]/table[2]/tbody/tr/td/span')
      links.all('a').find { |a| a.text == page.to_s }.click
      sleep(1)
      process_amounts
      page += 1
    end

    positive_result = @positive.reduce(zero) { |sum, money| sum + money}
    negative_result =  @negative.reduce(zero) { |sum, money| sum + money}

    cli.say("<%= color('Contributions: #{positive_result.format}', BOLD) %>!")
    cli.say("<%= color('Usage: #{negative_result.format}', BOLD) %>!")
    cli.say("<%= color('Difference: #{(positive_result - negative_result).format}', BOLD) %>!")
  end

  def process_amounts
    tr = browser.all('//*[@id="data"]/tbody/tr/td[4]')
    tr.each do |td|
      value = Monetize.parse(td.text)
      @total += 1
      @positive.push(value) if (value > zero)
      @negative.push(value) if (value < zero)
    end
  end

  def zero
    Monetize.parse('$0.00')
  end
end

UtaSpider.crawl!
