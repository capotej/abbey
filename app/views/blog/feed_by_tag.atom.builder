atom_feed(id: @tag.name) do |feed|
  feed.title "#{Rails.application.config.site_name} - Posts tagged #{@tag.name}"
  feed.updated(@posts.first.updated_at)

  @posts.each do |post|
    feed.entry(post, id: post.uuid, url: dated_post_url(year: post.year, day: post.day, month: post.month, id: post)) do |entry|
      entry.title(post.title)
      entry.content(post.rendered_body, type: 'html')
      entry.author do |author|
        author.name "Julio Capote"
      end
    end
  end
end
