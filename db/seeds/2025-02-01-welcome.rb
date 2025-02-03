body = %Q(

_The source for this blog post is under `db/seeds/2025-02-01-welcome.rb` which gets seeded as part of `rake db:setup`, along with everything else in `db/seeds/*`._

# A Typical Blog Post

This is what a typical blog post looks like.

Markdown is supported via [redcarpet](https://github.com/vmg/redcarpet) using [rouge](https://github.com/rouge-ruby/rouge) for highlighted code blocks.

## Code Example
```go
package main

import "fmt"

func main() {
    fmt.Println("Hello, world!")
}
```
<br/>

It's tagged as [#instructions](/t/instructions), [#another-example-tag](/t/another-example-tag), and [#setup](/t/setup).

# Logging in

You can [login](/session/new) using `you@example.org` and the password `s3cr3t`. Once logged in, editable resources will have an ['Edit'](/posts/welcome-to-abbey/edit) button.

# Pages

You can add Pages by going to [New Link](/pages/new) after logging in.

Pages are like Posts except they don't have tags or an excerpt.

Also, they are not part of any feed or index and can only be accessed directly by its URL, like [p/about](/p/about).

# Adding pictures to Posts and Pages

You can drag and drop any image into a Page or Post body/excerpt to upload it and render it inline.

# Links

You can add links to the [Link blog](/links) by going to [New Link](/links/new) after logging in.

Only the URL is required as it will try get the title and description automatically using the [metainspector gem](https://github.com/jaimeiniesta/metainspector). You can edit the link afterwards and revise, if needed.

# Atom / RSS support

The [blog](/), [individual tag pages](/t/instructions), and [links](/links) are available via RSS by going to `<url>/feed`. That is, the [blog feed](/feed), [individual tag feed](/t/setup/feed), and [link feed](/links/feed), respectively.

)

begin
  Post.create!(
    title: "Welcome to Abbey!",
            created_at: "2025-02-01T00:00:00.000Z",
            markdown_body: body,
            markdown_excerpt: "This post walks you through using Abbey.",
            post_tags: "instructions,another example tag,setup"
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Error importing welcome post:  #{e.message}"
rescue => e
  puts "Unexpected error importing welcome post: #{e.message}"
end
