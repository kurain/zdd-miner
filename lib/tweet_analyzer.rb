# -*- encoding: utf-8 -*-
require 'MeCab'
require 'dbi'
require 'mysql'
require 'mysql2-cs-bind'

module TweetAnalyzer
class Tweets
  def initialize(dsn = "dbi:Mysql:tweets:localhost", user="nobody", pass="nobody")
    @dsn, @user, @pass = dsn, user, pass
  end

  def get_tweets(start_date, end_date)
    db = @dsn.split(':')[2]
    host = @dsn.split(':')[3]

    client = Mysql2::Client.new(
                                :host => host,
                                :username => @user,
                                :password => @pass,
                                :database => db,
                                :encoding => 'utf8'

                                )
    return client.xquery('SELECT text FROM tweets WHERE timestamp BETWEEN ? AND ?',
                  start_date, end_date)
  end
end

class Tagger
  def initialize(dic_path)
    @model = MeCab::Model.new("--userdic=\"#{dic_path}\"")
    @tagger = @model.createTagger()
  end

  def hatena_keyword(str)
    keywords = []
    n = @tagger.parseToNode(str)
    while n do
      feature = n.feature.force_encoding(Encoding::UTF_8)
      keywords.push n.surface if feature.include?('はてなキーワード')
      n = n.next
    end
    keywords
  end
end
end
