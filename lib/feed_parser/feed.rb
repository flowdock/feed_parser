class FeedParser
  class Feed
    attr_reader :type

    def initialize(feed_xml)
      @feed = Nokogiri::XML(feed_xml)
      @feed.remove_namespaces!
      @type = ((@feed.xpath('/rss')[0] && :rss) || (@feed.xpath('/feed')[0] && :atom)) || (@feed.xpath('/RDF')[0] && :rdf)
      raise FeedParser::UnknownFeedType.new("Unknown feed type") unless @type
      self
    end

    def title
      @title = @feed.xpath(Dsl[@type][:title]).text
    end

    def url
      _url = case @type
        when :rss, :rdf
          @feed.xpath(Dsl[@type][:url])
        when :atom
          @feed.xpath(Dsl[@type][:url]).first && @feed.xpath(Dsl[@type][:url]).attribute("href") ||
          @feed.xpath(Dsl[@type][:alternate_url]).first && @feed.xpath(Dsl[@type][:alternate_url]).attribute("href")
        else
          nil
      end
      @url = _url && _url.text || ""
    end

    def items
      klass = case @type
        when :rss then RssItem
        when :atom then AtomItem
        when :rdf then RdfItem
      end

      @items ||= @feed.xpath(Dsl[@type][:item]).map do |item|
        klass.new(item)
      end
    end

    def as_json
      {
        :title => title,
        :url => url,
        :items => items.map(&:as_json)
      }
    end
  end
end
