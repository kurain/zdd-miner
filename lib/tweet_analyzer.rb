require 'pattern_miner.rb'
require 'MeCab'
require 'dbi'

module TweetAnalyzer
class Tweets
  def initialize(dsn = "dbi:Mysql:tweets:localhost", user="nobody", pass="nobody")
    @dsn, @user, @pass = dsn, user, pass
  end

  def get_tweets(start_date, end_date)
    rows = []
    begin
      dbh = DBI.connect(@dsn, @user, @pass)
      dbh.do("SET CHARACTER SET utf8")
      rows = dbh.select_all(
        "SELECT text FROM tweets WHERE timestamp BETWEEN ? AND ?",
        start_date, end_date
      ).map{|e| e[0]}
    rescue DBI::DatabaseError => e
      puts "An error occurred"
      puts "Error code: #{e.err}"
      puts "Error message: #{e.errstr}"
    ensure
      dbh.disconnect if dbh
    end
    return rows
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
