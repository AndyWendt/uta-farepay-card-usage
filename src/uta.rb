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
    @cli = HighLine.new
    @contributions = []
    @usage = []
    @total = 0
    @selected_card = nil
    @selected_time_period = nil

    Money.locale_backend = :currency

    browser.fill_in "j_username", with: credentials['username']
    browser.fill_in "j_password", with: credentials['password']
    browser.click_button "Login"

    # Update response to current response after interaction with a browser
    response = browser.current_response
    wait_for_ajax
    goto_card_activity_and_balance
    wait_for_ajax
    select_card
    wait_for_ajax
    select_time_period
    wait_for_ajax

    number = browser.find('//*[@id="displayTagDiv"]/span').text[/\d+/].to_i
    process_amounts
    pages = (number.to_f / 5.to_f).ceil
    page = 2

    while page <= pages
      links = browser.find('//*[@id="displayTagDiv"]/table[2]/tbody/tr/td/span')
      links.all('a').find { |a| a.text == page.to_s }.click
      wait_for_ajax
      process_amounts
      page += 1
    end

    contribution_total = @contributions.reduce(zero) { |sum, money| sum + money}
    usage_total =  @usage.reduce(zero) { |sum, money| sum + money}

    @cli.say("<%= color('Contributions: #{contribution_total.format}', BOLD) %>")
    @cli.say("<%= color('Usage: #{usage_total.format}', BOLD) %>")
    @cli.say("<%= color('Difference: #{(contribution_total + usage_total).format}', BOLD) %>")
  end

  def wait_for_ajax
    Timeout.timeout(Capybara.default_max_wait_time) do
      active = browser.evaluate_script('jQuery.active')
      until active == 0
        active = browser.evaluate_script('jQuery.active')
      end
    end
  end

  def process_amounts
    tr = browser.all('//*[@id="data"]/tbody/tr/td[4]')
    tr.each do |td|
      value = Monetize.parse(td.text)
      @total += 1
      @contributions.push(value) if (value > zero)
      @usage.push(value) if (value < zero)
    end
  end

  def zero
    Monetize.parse('$0.00')
  end

  private

  def select_time_period
    browser.find('//*[@id="dateRangeSeletor"]/option[2]').click
  end

  def select_card
    card_options = browser.all('//*[@id="cardSeletor"]/option')

    choices = card_options.reduce([]) do |options, option|
      if option.value.empty?
        options
      else
        options.push(option.text)
        options
      end
    end

    @cli.choose do |menu|
      menu.prompt = "Select Card"
      choices.each_with_index { |choice, index| menu.choice(choice) { @selected_card = index } }
    end

    browser.find('//*[@id="cardSeletor"]/option[' + (@selected_card + 2).to_s + ']').click
  end

  def goto_card_activity_and_balance
    browser.find('//*[@id="list-nav"]/li[4]/a').click
  end
end

UtaSpider.crawl!
