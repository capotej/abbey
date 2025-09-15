atom_feed do |feed|
  if @entries.any?
    feed.title "#{Rails.application.config.site_name} - Interesting Links Feed"
    feed.updated(@entries.first.updated_at)

    @entries.each do |entry_item|
      if entry_item.is_a?(Link)
        feed.entry(entry_item, id: entry_item.uuid, url: entry_item.url) do |entry|
          entry.title(entry_item.title)
          entry.content(entry_item.description, type: "text")
          entry.author do |author|
            author.name "N/A"
          end
        end
      else # Paper
        # Use display_url for arxiv papers, fallback to original url
        entry_url = entry_item.display_url.presence || entry_item.url
        feed.entry(entry_item, id: entry_item.uuid, url: entry_url) do |entry|
          entry.title(entry_item.title)
          entry.content(entry_item.description, type: "text")
          entry.author do |author|
            author.name "N/A"
          end
        end
      end
    end
  else
    feed.title "#{Rails.application.config.site_name} - Interesting Links Feed"
    feed.updated(Time.current)
  end
end
