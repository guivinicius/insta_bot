require_relative 'lib/insta_bot'

username = ENV['INSTABOT_USERNAME'] || ''
password = ENV['INSTABOT_PASSWORD'] || ''

session = InstaBot.new(username, password)
session.login

# Like by tags
session.like_by_tags(['coffee', 'drone'], 10, top_posts=true)
