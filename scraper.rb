require 'bundler/setup'
require 'scraperwiki'
require 'twitter'
require 'pry'
require 'dotenv'

Dotenv.load

def twitter
  @twitter ||= Twitter::REST::Client.new do |config|
    config.consumer_key        = ENV['MORPH_TWITTER_CONSUMER_KEY']
    config.consumer_secret     = ENV['MORPH_TWITTER_CONSUMER_SECRET']
    config.access_token        = ENV['MORPH_TWITTER_ACCESS_TOKEN']
    config.access_token_secret = ENV['MORPH_TWITTER_ACCESS_TOKEN_SECRET']
  end
end

# https://twitter.com/elainebyrne/lists/irish-politicians
# remove prefix "Senator" and suffixed "TD" (Teachta Dála) from names

# It might be handy to know if a name or handle indicates the type of
# membership, so save it as guess_type.

# "Sen" at the start of a string is a little bit risky, but
# appears sound for current data.
# "TD" and "MEP" at the end of the string seems safer.

regexps = {
  :td => /T\.?D\.?$/i,
  :mep =>  /M\.?E\.?P\.?$/i,
  :senator => /^Sen/i,
}

twitter.list_members('elainebyrne', 'irish-politicians').each do |person|
  guess_type = '?'
  regexps.each do |politician_type, regexp|
    if person.name.match(regexps[politician_type]) || person.screen_name.match(regexps[politician_type])
      guess_type = politician_type
      break
    end
  end
  data = {
    id: person.id,
    name: person.name.gsub(/(^Sen(ator)?\s|\sT\.?D\.?$)/, ''),
    twitter: person.screen_name,
    guess_type: guess_type.to_s
  }
  data[:image] = person.profile_image_url_https(:original).to_s unless person.default_profile_image?
  ScraperWiki.save_sqlite([:id], data)
end
