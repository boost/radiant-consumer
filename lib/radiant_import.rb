require 'open-uri'

class RadiantImport < ActionController::Base
  def self.options=(value)
    @options = value
  end

  def self.options
    @options || {}
  end

  def self.instance
    @instance ||= RadiantImport.new(RadiantImport.options)
  end

  def initialize(options)
    @options = options
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
    end
    cache([uri, last_cached]) { URI.parse(uri).read }
  end
end