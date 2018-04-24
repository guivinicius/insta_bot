require 'capybara'
require 'capybara/dsl'
require 'logger'

require_relative 'insta_bot/version'

class InstaBot
  include Capybara::DSL

  BASE_URL = 'https://www.instagram.com/'.freeze

  Capybara.default_driver   = :selenium_chrome
  Capybara.run_server       = false
  Capybara.app_host         = BASE_URL
  Capybara.default_selector = :xpath

  def initialize(username, password, log_to = STDOUT)
    raise(ArgumentError, 'Missing username or password') unless username || password

    @username = username
    @password = password
    @logger   = Logger.new(log_to)
  end

  def login
    visit('accounts/login/')

    fill_in 'username', with: username
    fill_in 'password', with: password

    click_button 'Log in'

    logger.info("logged as #{username}")
  end

  def like_by_tags(tags, amount=50, top_posts=true)
    tags.each do |tag|
      liked_counter         = 0
      already_liked_counter = 0
      inap_counter          = 0

      logger.info("Exploring: ##{tag}")

      visit("explore/tags/#{tag}")

      links = fetch_links(tag, amount, top_posts)

      links.each do |url|
        visit(url)

        logger.info("Link: #{url}")

        if like_btn = fetch_like_btn
          sleep(2)
          like_btn.click
          sleep(0.5)
          if unlike_btn = fetch_unlike_btn
            liked_counter += 1
            logger.info('Image Liked!')
          else
            logger.info('Image was not able to get Liked! maybe blocked ?')
            sleep(120)
          end
        else
          if unlike_btn = fetch_unlike_btn
            already_liked_counter += 1
            logger.info('Image already Liked')
          end
        end
      end

      logger.info("Liked: #{liked_counter}")
      logger.info("Already Liked: #{already_liked_counter}")
      logger.info("Inappropriate: #{inap_counter}")
    end
  end

  private

  attr_reader :username, :password, :logger

  def fetch_links(tag, amount, top_posts)
    visit("explore/tags/#{tag}")

    links = []

    links << page.find('//main/article/div[1]').all('.//a').map{ |a| a[:href] } if top_posts

    while links.size < amount
      links << page.find('//main/article/div[2]').all('.//a').map{ |a| a[:href] }
      links = links.flatten.compact.uniq
      links.first(amount)

      load_more
    end

    links
  end

  def fetch_like_btn
    page.all("//a[@role='button']/span[text()='Like']/..")[0]
  end

  def fetch_unlike_btn
    page.all("//a[@role='button']/span[text()='Unlike']")[0]
  end

  def fetch_graphql
    page.execute_script("return window._sharedData.entry_data.PostPage;")
  end

  def load_more
    page.find('//a[contains(@class, "_1cr2e _epyes")]').click
  rescue Capybara::ElementNotFound
    page.execute_script("window.scrollTo(0, document.body.scrollHeight);")
  end
end
