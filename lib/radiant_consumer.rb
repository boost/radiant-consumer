require 'open-uri'
require 'timeout'

class RadiantConsumer < ActionController::Base
  cattr_accessor :options

  # Singleton instance of RadiantConsumer
  def self.instance
    @instance ||= RadiantConsumer.new(RadiantConsumer.options)
  end

  # Create a new RadiantConsumer with options as a hash.
  #
  # Valid option values:
  #   :radiant_url => The url of the radiant installation
  #   :expires_after => Time in seconds that the content is cached for
  #
  # Example:
  #   RadiantConsumer.new(
  #     :radiant_url => 'http://example.com',
  #     :expires_after => 10.minutes
  #   )
  def initialize(options)
    @options = options || {}
  end

  # Fetch a radiant snippet
  def fetch_snippet(name)
    fetch('/snippets/%s' % name)
  end

  # Fetch a radiant page
  def fetch_page(name)
    fetch('/page/%s' % name)
  end

  # Fetch a specifc page part on a radiant page
  def fetch_page_part(name, part)
    fetch('/page/%s/%s' % [name, part])
  end

  private

  def fetch(url)
    uri = @options[:radiant_url] + url

    if cache_valid?(uri)
      cached(uri)
    else
      content = ''

      begin
        Timeout::timeout(@options[:timeout] || 10) do
          content = cache_content(uri, URI.parse(uri).read)
        end
      rescue Timeout::Error
        clear_cache(uri)
      end
      
      content
    end
  end

  def cache_content(uri, content)
    clear_cache(uri)

    time = Time.now.to_i

    cache_store.write(cache_key(uri), time)
    cache_store.write(cache_key([uri, time]), content)
    
    content
  end

  def cached(uri)
    cache_store.read(cache_key([uri, last_cached(uri)]))
  end

  def last_cached(uri)
    cache_store.read(cache_key(uri)).to_i
  end

  def cache_valid?(uri)
    last = last_cached(uri)
    !(!last || Time.now.to_i > (last + @options[:expire_after].to_i))
  end

  def cache_key(key)
    ActiveSupport::Cache.expand_cache_key(key, :controller)
  end

  def clear_cache(uri)
    if last_cached(uri)
      cache_store.delete(cache_key([uri, last_cached(uri)]))
      cache_store.delete(cache_key(uri))
    end
  end
end