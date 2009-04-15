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
  #     :expires_after => 10.minutes,
  #     :timeout => 5,
  #     :test_content => 'Example content'
  #   )
  def initialize(options)
    @options = options || {}
  end

  # Fetch a radiant snippet
  def fetch_snippet(name, options = {})
    fetch('/snippets/%s' % name, options)
  end

  # Fetch a radiant page
  def fetch_page(name, options = {})
    fetch('/page/%s' % name, options)
  end

  # Fetch a specifc page part on a radiant page
  def fetch_page_part(name, part, options = {})
    fetch('/page/%s/%s' % [name, part], options)
  end

  private

  # Fetch the contents at a url from the source or from the cache. Uses the
  # expires_after cache option to decide if the cache is valid.
  def fetch(url, options = {})
    @default_options = @options
    @options = @options.merge(options)

    begin
      if content = @options[('%s_content' % RAILS_ENV).to_sym]
        return content
      end

      uri = @options[:radiant_url] + url

      if cache_valid?(uri)
        cached(uri)
      else
        content = ''

        begin
          Timeout::timeout(@options[:timeout] || 10) do
            read_options = {}

            if @options[:username]
              read_options[:http_basic_authentication] = [@options[:username].to_s, @options[:password].to_s]
            end

            content = cache_content(uri, URI.parse(uri).read(read_options))
          end
        rescue Timeout::Error => e
          logger.error "Couldn't fetch content from radiant: %s due to error: %s" % [url, e.message]
        rescue Errno::ECONNREFUSED => e
          logger.error "Couldn't fetch content from radiant: %s due to error: %s" % [url, e.message]
          clear_cache(uri)
        end
      
        content
      end
    ensure
      @options = @default_options
    end
  end

  # Cache content, saving the content and the time the content was cached
  def cache_content(uri, content)
    clear_cache(uri)

    time = Time.now.to_i

    cache_store.write(cache_key(uri), time)
    cache_store.write(cache_key([uri, time]), content)
    
    content
  end

  # Return cached content
  def cached(uri)
    cache_store.read(cache_key([uri, last_cached(uri)]))
  end

  # Return the time a url was cached
  def last_cached(uri)
    cache_store.read(cache_key(uri)).to_i
  end

  # Test if the cache is valid, that it is cached and it was cached with the
  # expires_after time
  def cache_valid?(uri)
    last = last_cached(uri)
    (last > 0 && Time.now.to_i <= (last + @options[:expire_after].to_i))
  end

  # Generate a valid cache key
  def cache_key(key)
    ActiveSupport::Cache.expand_cache_key(key, :controller)
  end

  # Clear cached content and time
  def clear_cache(uri)
    if last_cached(uri) > 0
      cache_store.delete(cache_key([uri, last_cached(uri)]))
      cache_store.delete(cache_key(uri))
    end
  end
end