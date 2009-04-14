require File.expand_path(File.join(File.dirname(__FILE__), '../spec_helper'))

class RadiantConsumerController
  include RadiantConsumerHelper
end

describe RadiantConsumerController do
  before(:each) do
    @controller = RadiantConsumerController.new
    @consumer = mock(:radiant_consumer)
    RadiantConsumer.should_receive(:instance).and_return(@consumer)
  end

  it 'should fetch a radiant page' do
    @consumer.should_receive(:fetch_page).with('name', {})
    @controller.radiant_page('name')
  end

  it 'should fetch a radiant page part' do
    @consumer.should_receive(:fetch_page_part).with('name', 'part', {})
    @controller.radiant_page_part('name', 'part')
  end

  it 'should fetch a radiant snippet' do
    @consumer.should_receive(:fetch_snippet).with('name', {})
    @controller.radiant_snippet('name')
  end
end
