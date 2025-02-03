atom_feed do |feed|
  feed.title "#{Rails.application.config.site_name} - Interesting Links Feed"
  feed.updated(@links.first.updated_at)

  @links.each do |link|
    feed.entry(link, id: link.uuid, url: link.url) do |entry|
      entry.title(link.title)
      entry.content(link.description, type: "text")
      entry.author do |author|
        author.name "N/A"
      end
    end
  end
end
