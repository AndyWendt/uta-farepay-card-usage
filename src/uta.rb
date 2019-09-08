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
    initialize_defaults

    login
    goto_card_activity_and_balance
    select_card
    select_date_range
    process_card_activity_pages
    display_end_totals
  end

  private

  def process_first_page_activity_amounts
    process_amounts
  end

  def initialize_defaults
    @cli = HighLine.new
    @contributions = []
    @usage = []
    @total = 0
    @selected_card = nil
    @selected_time_period = nil

    Money.locale_backend = :currency
  end

  def login
    credentials = YAML.load_file(File.expand_path('~') + '/.uta/secret.yml')
    browser.fill_in "j_username", with: credentials['username']
    browser.fill_in "j_password", with: credentials['password']
    browser.click_button "Login"

    # Update response to current response after interaction with a browser
    response = browser.current_response
    wait_for_ajax
  end

  def process_card_activity_pages
    process_first_page_activity_amounts

    transactions_total = browser.find('//*[@id="displayTagDiv"]/span').text[/\d+/].to_i
    pages = (transactions_total.to_f / 5.to_f).ceil
    page = 2

    while page <= pages
      page_links = browser.find('//*[@id="displayTagDiv"]/table[2]/tbody/tr/td/span')
      page_links.all('a').find { |a| a.text == page.to_s }.click
      wait_for_ajax
      process_amounts
      page += 1
    end
  end

  def display_end_totals
    contribution_total = @contributions.reduce(zero) { |sum, money| sum + money }
    usage_total = @usage.reduce(zero) { |sum, money| sum + money }

    @cli.say("<%= color('Contributions: #{contribution_total.format}', BOLD) %>")
    @cli.say("<%= color('Usage: #{usage_total.format}', BOLD) %>")
    @cli.say("<%= color('Difference: #{(contribution_total + usage_total).format}', BOLD) %>")
  end

  def select_date_range
    date_range_options = browser.all('//*[@id="dateRangeSeletor"]/option')
    choices = get_option_choices(date_range_options)
    @cli.choose do |menu|
      menu.prompt = "Select Date Range"
      choices.each_with_index { |choice, index| menu.choice(choice) { @selected_time_period = index } }
    end

    browser.find('//*[@id="dateRangeSeletor"]/option[' + (@selected_time_period + 1).to_s + ']').click
    wait_for_ajax
  end

  def select_card
    card_options = browser.all('//*[@id="cardSeletor"]/option')

    choices = get_option_choices(card_options)

    @cli.choose do |menu|
      menu.prompt = "Select Card"
      choices.each_with_index { |choice, index| menu.choice(choice) { @selected_card = index } }
    end

    browser.find('//*[@id="cardSeletor"]/option[' + (@selected_card + 2).to_s + ']').click
    wait_for_ajax
  end

  def get_option_choices(option_elements)
    option_elements.reduce([]) do |options, option|
      if option.value.empty?
        options
      else
        options.push(option.text)
        options
      end
    end
  end

  def goto_card_activity_and_balance
    browser.find('//*[@id="list-nav"]/li[4]/a').click
    wait_for_ajax
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
end

UtaSpider.crawl!
