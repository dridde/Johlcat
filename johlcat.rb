# The famous @johlcat script, generated as a birthday present for @johl.
# Extended by @dridde to retweet @plomlompom
# The script requires the following gems: twitter, lolspeak and rtranslate.
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
#require 'whatlanguage'

#Config
keepHashtags = 1
keepMentions = 0
upcaseFactor = 0.5
retweetWho = 'retweetet_screen_name'
screen_name = 'johlcat' # the one and original, the target account

# this is supposed to be an 5 minutly cronjob, feel free to change the amount of minutes!
$fiveminsago = Time.at(Time.now.to_i - 300) # 5 minutes ago

# The OAuth stuff follows...
require 'yaml'
begin 
  config = YAML.load_file("secret.yaml")
  @oauth_token = config["oauth_token"]
  @oauth_token_secret = config["oauth_token_secret"]
  @api_key = config["api_key"]
  @api_secret = config["api_secret"]
rescue
  # Fill in your data for your own bot here here
  @oauth_token = ""
  @oauth_token_secret = ""
  @api_key = ""
  @api_secret = ""
end

def prepare_access_token(oauth_token, oauth_token_secret)
  consumer = OAuth::Consumer.new(@api_key, @api_secret,
    { :site => "http://api.twitter.com",
      :scheme => :header
    })
  # now create the access token object from passed values
  token_hash = { :oauth_token => oauth_token,
                 :oauth_token_secret => oauth_token_secret
               }
  access_token = OAuth::AccessToken.from_hash(consumer, token_hash )
  return access_token
end

oauth = prepare_access_token(@oauth_token, @oauth_token_secret)
client = Twitter::Base.new(oauth)

# Back to our regular Johlcat...


begin
	client.user_timeline( :screen_name => retweetWho ).reverse.each do | tweet |
		mentions = ''
		hashtags = ''
		if Time.parse(tweet.created_at) > $fiveminsago 
			tweettext = tweet.text.dup
			tweet.text.each(' ') { |part|
				if (keepHashtags == 1) 
					if (part.index('#') == 0) 
						hashtags += part
						tweettext.gsub!(part,"")
					end
				end
				if (keepMentions == 1)
					if ((part.index('@') == 0) || (part.index('.@') == 0)) 
						mentions += part
						tweettext.gsub!(part,"")
					end
				end
			}
			# since rtranslate fails when encountering & and returns html-escaped strings, which we dont want...
			translate = tweettext.gsub("&", "und")
			translate = RTranslate.t(translate, 'de', 'en')
			translate = CGI.unescapeHTML(translate)
			translate = translate.to_lolspeak
			translate.gsub!("@","")
			if (mentions.length > 0) 
				translate = mentions + translate
			end
			if (hashtags.length > 0) 
				translate += " " + hashtags
			end
			if (rand() <= upcaseFactor) 
				translate.upcase!
			end
			client.update(translate)
		end
	end
rescue Twitter::Unavailable, Twitter::InformTwitter, OpenSSL::SSL::SSLError, Errno::ETIMEDOUT => error
	sleep(60) # wait for 60 seconds then retry
	retry
end
