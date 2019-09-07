require 'kimurai'
require 'yaml'
require 'pry'
require 'monetize'

class UtaSpider < Kimurai::Base
  @name = "UTA Spider"
  @engine = :selenium_chrome
  @start_urls = ['https://farepay.rideuta.com']

  def parse(response, url:, data: {})
    credentials = YAML.load_file(File.expand_path('~') + '/.uta/secret.yml')
    positive = []
    negative = []
    browser.fill_in "j_username", with: credentials['username']
    browser.fill_in "j_password", with: credentials['password']
    browser.click_button "Login"

    # Update response to current response after interaction with a browser
    response = browser.current_response
    browser.find('//*[@id="list-nav"]/li[4]/a').click
    browser.find('//*[@id="cardSeletor"]/option[2]').click
    browser.find('//*[@id="dateRangeSeletor"]/option[2]').click

    tr = browser.all('//*[@id="data"]/tbody/tr/td[4]')
    zero = Monetize.parse('$0.00')
    tr.each do |td|
      value = Monetize.parse(td.text)
      positive.push(value) if (value > zero)
      negative.push(value) if (value < zero)
    end
    pp positive.reduce(zero) { |sum, money| sum + money}
    pp negative.reduce(zero) { |sum, money| sum + money}
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      loop until finished_all_ajax_requests?
    end
  end

  def finished_all_ajax_requests?
    browser.evaluate_script('jQuery.active').zero?
  end
end

UtaSpider.crawl!
