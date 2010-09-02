#! /usr/local/bin/ruby -w
require 'rubygems'
require 'open-uri'
require 'rss'
require 'twitter'
require 'oauth'
require 'cgi'
require 'sequel'

CONSUMER_KEY        = 'CHANGE THIS'
CONSUMER_SECRET     = 'CHANGE THIS'
ACCESS_TOKEN        = 'CHANGE THIS'
ACCESS_TOKEN_SECRET = 'CHANGE THIS'

Sequel::Model.plugin(:schema)
DB = Sequel.connect('sqlite://diet.db')

class Post < Sequel::Model
  unless table_exists?
    set_schema do
      primary_key :id
      string :title
      text :body
      string :url
      timestamp :date
    end
    create_table
  end
end

feed = open('http://sorosorhonkidasu.blog31.fc2.com/?xml') do |file| 
  RSS::Parser.parse(file.read) 
end

feed.items.each_with_index do |post, i|
  body   = post.content_encoded
  title  = post.title
  url    = post.link
  date   = post.dc_date

  if post = Post.filter(:url => url).first
    puts "あった。次へいく"
    puts post.title
    next
  else
    puts "なかった. DBにいれて、投稿する"
    new_post = Post.create(
      :body  => body,
      :title => title,
      :url   => url,
      :date  => date
    )
  end

  sentences = body.split('。')
  @posted = false
  sentences.each do |sentence|
    next if sentence =~ /目標/
    if sentence =~ /(\d{2}(\.\d*)?kg)/
      weight = $1
      next unless 60.0 < weight.to_f
      text = "#{weight}なう : 「#{title}」#{url}"

      oauth = Twitter::OAuth.new(CONSUMER_KEY, CONSUMER_SECRET)
      oauth.authorize_from_access(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
      client = Twitter::Base.new(oauth)
      client.update(text)
      @posted = true
      break
    else
      puts "N/A"
    end
  end

  unless @posted
    text = "体重書ぃてないょ... : 「#{title}」#{url}"

    oauth = Twitter::OAuth.new(CONSUMER_KEY, CONSUMER_SECRET)
    oauth.authorize_from_access(ACCESS_TOKEN, ACCESS_TOKEN_SECRET)
    client = Twitter::Base.new(oauth)
    client.update(text)
  end

  sleep 1
end


