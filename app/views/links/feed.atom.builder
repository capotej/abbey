atom_feed do |feed|
  feed.title "#{Rails.application.config.site_name} - Interesting Links Feed"
  feed.updated(@entries.first.updated_at) if @entries.any?

  @entries.each do |entry|
    # Determine the URL to use for the entry
    url = if entry.is_a?(Paper)
      entry.arxiv? ? entry.arxiv_pdf_url : entry.url
    else
      entry.url
    end

    # Generate a unique ID for the entry
    id = entry.uuid

    feed.entry(entry, id: id, url: url) do |feed_entry|
      feed_entry.title(entry.title)
      feed_entry.content(entry.description, type: "text")
      feed_entry.author do |author|
        author.name "N/A"
      end
    end
  end
end
