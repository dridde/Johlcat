# The famous @johlcat script, generated as a birthday present for @johl.
# Extended by @dridde to retweet @plomlompom
# The script requires the following gems: twitter, lolspeak, whatlanguage and rtranslate.
# It reads all tweets tweeted in the last five minutes, translates them to english
# and retweets them to another twitter account, but in lolspeak.
# 
# Have phun!
#
# Author: Svenja Schroeder
# github: http://github.com/svenja
# twitter: http://www.twitter.com/sv

#!/usr/bin/env ruby

require 'rubygems'
gem 'twitter'
require 'twitter'
require 'lolspeak'
require 'rtranslate'

screen_name = 'johlcat' # the one and original, the target account
password = '***'
# this is supposed to be an 5 minutly cronjob, feel free to change the amount of minutes!
$fiveminsago = Time.at(Time.now.to_i - 300) # 5 minutes ago

httpauth = Twitter::HTTPAuth.new( screen_name, password, @options = { :ssl => true })
client = Twitter::Base.new(httpauth)

begin
	client.user_timeline( :screen_name => 'retweeted_screen_name' ).reverse.each do | tweet |
		if Time.parse(tweet.created_at) > $fiveminsago 
			# since rtranslate fails when encountering & and returns html-escaped strings, which we dont want...
			translate = tweet.text.gsub("&", "und")
			translate = RTranslate.t(translate, 'de', 'en')
			translate = CGI.unescapeHTML(translate)
			client.update(translate.to_lolspeak.upcase.delete('@'))
		end
	end
rescue Twitter::Unavailable, Twitter::InformTwitter, OpenSSL::SSL::SSLError, Errno::ETIMEDOUT => error
	sleep(60) # wait for 60 seconds then retry
	retry
end
