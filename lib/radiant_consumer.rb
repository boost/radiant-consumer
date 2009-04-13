require 'open-uri'

class RadiantConsumer < ActionController::Base
  cattr_accessor :options

  def self.instance
    @instance ||= RadiantConsumer.new(RadiantConsumer.options)
  end

  def initialize(options)
    @options = options || {}
  end

  def fetch_snippet(name)
    fetch('/snippets/%s' % name)
  end

  def fetch_page(name)
    fetch('/page/%s' % name)
  end

  def fetch_page_part(name, part)
    fetch('/page/%s/%s' % [name, part])
  end

  private

  def fetch(url)
    uri = @options[:radiant_url] + url
    last_cached = cache(uri) { Time.now.to_i }

    if @options[:expire_after] && Time.now.to_i > (last_cached + @options[:expire_after].to_i)
      cache_store.delete(ActiveSupport::Cache.expand_cache_key(uri, :controller))
      cache_store.delete(ActiveSupport::Cache.expand_cache_key([uri, last_cached], :controller))
      last_cached = cache(uri) { Time.now.to_i }
    end

    cache([uri, last_cached]) { URI.parse(uri).read }
  end
end