require 'open-uri'
require 'timeout'

class RadiantConsumer < ActionController::Base
  cattr_reader :options

  # Singleton instance of RadiantConsumer
  def self.instance
    @instance ||= RadiantConsumer.new(RadiantConsumer.options)
  end

  def self.options=(value)
    verify_options(value)
    @@options = value
  end

  def self.verify_options(options)
    valid_keys = %w(radiant_url expires_after timeout raise_errors error_content username password)

    options.keys.each do |key|
      unless valid_keys.include?(key.to_s)
        if key.to_s !~ /\s*_content/
          raise ArgumentError.new("Invalid argument %s" % key.to_s)
        end
      end
    end
  end

  # Create a new RadiantConsumer with options as a hash.
  #
  # Valid option values:
  # :radiant_url:: The URL of the radiant installation. This should be the base URL.
  # :expire_after:: The amount of time, in seconds, to cache the fetched content before fetching again.
  # :timeout:: The amount of time, in seconds, to timeout the request to fetch the content.
  # :environment_content:: Content to return for an environment instead of actually fetching.
  # :username:: Will use basic authentication if set
  # :password:: Password for basic authentication
  # :error_content:: Content to return if an error occurs while fetching from radiant (like a page doesn't exist)
  # :raise_errors:: If true any errors the occur during the fetch will be raised. Otherwise they will fail silently
  #
  # Example:
  #   RadiantConsumer.new(
  #     :radiant_url => 'http://example.com',
  #     :expires_after => 10.minutes,
  #     :timeout => 5,
  #     :test_content => 'Example content',
  #     :error_content => "An error occured",
  #     :raise_errors => false
  #   )
  def initialize(options)
    @options = options || {}
    self.class.verify_options(@options)
  end

  # Fetch a radiant snippet. Options will override any options passed to #new
  def fetch_snippet(name, options = {})
    fetch('/snippets/%s' % name, options)
  end

  # Fetch a radiant page. Options will override any options passed to #new
  def fetch_page(name, options = {})
    fetch('/page/%s' % name, options)
  end

  # Fetch a specifc page part on a radiant page. Options will override any
  # options passed to #new
  def fetch_page_part(name, part, options = {})
    fetch('/page/%s/%s' % [name, part], options)
  end

  private

  # Fetch the contents at a url from the source or from the cache. Uses the
  # expires_after cache option to decide if the cache is valid.
  def fetch(url, options = {})
    @default_options = @options
    @options = @options.merge(options)
    self.class.verify_options(@options)

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
        rescue Exception => e
          logger.error "Couldn't fetch content from radiant: %s due to error: %s" % [url, e.message] if logger

          if @options[:error_content]
            content = @options[:error_content]
          else
            content = nil
          end

          fail if @options[:raise_errors] == true
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
    (last > 0 && Time.now.to_i <= (last + @options[:expires_after].to_i))
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