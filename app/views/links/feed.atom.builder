atom_feed do |feed|
  feed.title "#{Rails.application.config.site_name} - Interesting Links Feed"
  feed.updated(@items.first&.updated_at || Time.current)

  @items.each do |item|
    if item.is_a?(Link)
      feed.entry(item, id: item.uuid, url: item.url) do |entry|
        entry.title(item.title)
        entry.content(item.description, type: "text")
        entry.author do |author|
          author.name "N/A"
        end
      end
    elsif item.is_a?(Paper)
      # Use display_url for arXiv papers, otherwise use the paper's url
      entry_url = item.arxiv? ? item.display_url : item.url
      feed.entry(item, id: "paper-#{item.id}", url: entry_url) do |entry|
        entry.title(item.title)
        entry.content(item.description, type: "text")
        entry.author do |author|
          author.name "N/A"
        end
      end
    end
  end
end
