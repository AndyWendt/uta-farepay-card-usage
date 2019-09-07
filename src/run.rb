require 'kimurai'
require 'yaml'

class UtaSpider < Kimurai::Base
  @name = "UTA Spider"
  @engine = :selenium_chrome
  @start_urls = ['https://farepay.rideuta.com']

  def parse(response, url:, data: {})
    credentials = YAML.load_file(File.expand_path('~') + '/.uta/secret.yml')
    browser.fill_in "j_username", with: credentials['username']
    browser.fill_in "j_password", with: credentials['password']
    browser.click_button "Login"

    # Update response to current response after interaction with a browser
    response = browser.current_response
    browser.find('//*[@id="list-nav"]/li[4]/a').click
    response = browser.current_response
    browser.select "108369", from: "cardSeletor"
    # browser.select "2", from: "dateRangeSeletor"
    # response = browser.current_response
    pp response
  end
end

UtaSpider.crawl!
