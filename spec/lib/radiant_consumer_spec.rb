require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

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
        :radiant_url => 'http://example.com'
      }

      @consumer = RadiantConsumer.new(@options)
      @uri = mock(:uri)
    end

    describe 'fetch_snippet' do
      it 'should fetch from url/snippets/name' do
        URI.should_receive(:parse).with('http://example.com/snippets/name').and_return(@uri)
        @uri.should_receive(:read)
        @consumer.fetch_snippet('name')
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

  describe 'caching' do
    before(:each) do
      @options = {
        :radiant_url => 'http://example.com',
        :expire_after => 10.minutes
      }

      @consumer = RadiantConsumer.new(@options)
      @uri = mock(:uri, :read => 'example content')
      URI.stub!(:parse).and_return(@uri)
    end

    describe 'uncached' do
      it 'should cache the current time in the url key' do
        Time.should_receive(:now).at_least(:twice).and_return(134)
        @uri.should_receive(:read).and_return('example content')

        @consumer.should_receive(:cache).with('http://example.com/page/name').and_yield.and_return(134)
        @consumer.should_receive(:cache).with(['http://example.com/page/name', 134]).and_yield
        @consumer.should_not_receive(:cache_store)
        @consumer.fetch_page('name')
      end

      it 'should use the cached version if the last fetch was less than 10 minutes ago' do
        time_ago = Time.now.to_i - 5.minutes
        @consumer.should_receive(:cache).with('http://example.com/page/name').and_return(time_ago)
        @consumer.should_receive(:cache).with(['http://example.com/page/name', time_ago]).and_return('example content cached')
        @consumer.fetch_page('name').should == 'example content cached'
      end

      it 'should refetch if the last fetch was more than 10 minutes ago' do
        time_now = Time.now.to_i
        Time.stub!(:now).and_return(time_now)
        time_ago = Time.now.to_i - 15.minutes

        mock_store = mock(:cache_store)
        @consumer.should_receive(:cache).with('http://example.com/page/name').twice.and_return(time_ago, time_now)
        @consumer.should_receive(:cache_store).twice.and_return(mock_store)

        mock_store.should_receive(:delete).with('controller/http://example.com/page/name/%d.0' % time_ago).once
        mock_store.should_receive(:delete).with('controller/http://example.com/page/name').once

        @consumer.should_receive(:cache).with(['http://example.com/page/name', time_now]).and_return('example content')
        
        @consumer.fetch_page('name').should == 'example content'
      end
    end
  end
end