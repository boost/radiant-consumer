module RadiantConsumerHelper
  def radiant_snippet(name, options = {})
    RadiantConsumer.instance.fetch_snippet(name, options)
  end

  def radiant_page_part(page, part, options = {})
    RadiantConsumer.instance.fetch_page_part(page, part, options)
  end

  def radiant_page(page, options = {})
    RadiantConsumer.instance.fetch_page(page, options)
  end
end