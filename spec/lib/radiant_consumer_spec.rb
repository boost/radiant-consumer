require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))
require 'lib/radiant_consumer'

describe RadiantConsumer do
  before(:each) do
    # Reset the singleton
    RadiantConsumer.instance_variable_set('@instance', nil)
  end

  it 'should be a singleton' do
    @consumer1 = RadiantConsumer.instance
    @consumer2 = RadiantConsumer.instance
    @consumer1.should == @consumer2
  end

  describe 'instance' do
    before(:each) do
      @options = {
        :radiant_url => 'http://example.com',
        :expire_after => 0
      }

      @consumer = RadiantConsumer.new(@options)
      @consumer.stub!(:cache_store).and_return(ActiveSupport::Cache::MemoryStore.new)

      @uri = mock(:uri)
    end

    describe 'fetch_snippet' do
      it 'should fetch from url/snippets/name' do
        URI.should_receive(:parse).with('http://example.com/snippets/name').and_return(@uri)
        @uri.should_receive(:read)
        @consumer.fetch_snippet('name')
      end

      it 'should allow options' do
        URI.should_receive(:parse).once.with('http://example.com/snippets/other_name').and_return(@uri)
        @uri.should_receive(:read)

        @consumer.fetch_snippet('name', :test_content => 'Example content').should == 'Example content'
        @consumer.fetch_snippet('other_name')
      end
    end

    describe 'fetch_page' do
      it 'should fetch from url/page/name' do
        URI.should_receive(:parse).with('http://example.com/page/name').and_return(@uri)
        @uri.should_receive(:read)
        @consumer.fetch_page('name')
      end
    end

    describe 'fetch_page_part' do
      it 'should fetch from url/page/name/part' do
        URI.should_receive(:parse).with('http://example.com/page/name/part').and_return(@uri)
        @uri.should_receive(:read)
        @consumer.fetch_page_part('name', 'part')
      end
    end
  end

  describe 'environment content' do
    it 'should always return content for an environment if set' do
      cenv = RAILS_ENV
      RAILS_ENV = "staging"

      @consumer = RadiantConsumer.new(:staging_content => "Test content")
      @consumer.fetch_page('anything').should == "Test content"
      
      RAILS_ENV = cenv
    end
  end

  describe 'timeout' do

  end

  describe 'caching' do
    before(:each) do
      @options = {
        :radiant_url => 'http://example.com',
        :expire_after => 10.minutes
      }

      @consumer = RadiantConsumer.new(@options)
      @consumer.stub!(:cache_store).and_return(ActiveSupport::Cache::MemoryStore.new)

      @uri = mock(:uri, :read => 'original example content')
      URI.stub!(:parse).and_return(@uri)
    end

    it 'should fetch the content from the source the first time' do
      time_now = Time.now
      Time.should_receive(:now).at_least(:once).and_return(time_now)
      @uri.should_receive(:read).and_return('uncached example content')
      @consumer.fetch_page('name').should == 'uncached example content'
    end

    it 'should use the cached version if the last fetch was less than 10 minutes ago' do
      time_ago = Time.now.to_i - 5.minutes
      time_now = Time.now

      Time.stub!(:now).and_return(time_ago)
      @uri.should_receive(:read).once.and_return('cached example content')
      @consumer.fetch_page('name').should == 'cached example content'

      Time.stub!(:now).and_return(time_now)
      @consumer.fetch_page('name').should == 'cached example content'
    end

    it 'should refetch if the last fetch was more than 10 minutes ago' do
      time_now = Time.now.to_i
      time_ago = Time.now.to_i - 15.minutes

      Time.stub!(:now).and_return(time_ago)
      @uri.should_receive(:read).twice.and_return('cached example content', 'uncached example content')
      @consumer.fetch_page('name').should == 'cached example content'
      # Try again to make sure it is cached
      @consumer.fetch_page('name').should == 'cached example content'

      Time.stub!(:now).and_return(time_now)
      @consumer.fetch_page('name').should == 'uncached example content'
    end
  end
end