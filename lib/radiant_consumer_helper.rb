module RadiantConsumerHelper
  def radiant_snippet(name, options = {})
    RadiantConsumer.instance.fetch_snippet(name)
  end

  def radiant_page_part(page, part, options = {})
    RadiantConsumer.instance.fetch_page_part(page, part)
  end

  def radiant_page(page, options = {})
    RadiantConsumer.instance.fetch_page(page)
  end
end