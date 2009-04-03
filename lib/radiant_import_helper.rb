module RadiantImportHelper
  def radiant_snippet(name, options = {})
    RadiantImport.instance.fetch_snippet(name)
  end

  def radiant_page_part(page, part, options = {})
    RadiantImport.instance.fetch_page_part(page, part)
  end

  def radiant_page(page, options = {})
    RadiantImport.instance.fetch_page(page)
  end
end