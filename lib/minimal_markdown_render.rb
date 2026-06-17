require "redcarpet"
require "rouge"
require "rouge/plugins/redcarpet"

# Renderer that emits plain semantic HTML — no inline Tailwind utility
# classes — so themes can style markdown output entirely from a wrapper
# scope (e.g. `.prose-retro`). Used by any theme that registers itself as
# `Rails.application.config.theme_uses_minimal_renderer = true`, or
# explicitly chosen by the Rendering concern.
module Redcarpet
  module Render
    class MinimalHTML < ::Redcarpet::Render::HTML
      def normal_text(text)
        text
      end

      def block_code(code, language)
        %(<pre class="highlight #{language}"><code>#{code}</code></pre>)
      end

      def header(title, level)
        "<h#{level}>#{title}</h#{level}>"
      end

      def paragraph(text)
        "<p>#{text}</p>"
      end

      def list(content, list_type)
        tag = list_type == :ordered ? "ol" : "ul"
        "<#{tag}>#{content}</#{tag}>"
      end

      def list_item(content, _list_type)
        "<li>#{content}</li>"
      end

      def link(link, title, content)
        title_attr = title ? %( title="#{title}") : ""
        %(<a href="#{link}"#{title_attr}>#{content}</a>)
      end

      def emphasis(text)
        "<em>#{text}</em>"
      end

      def double_emphasis(text)
        "<strong>#{text}</strong>"
      end

      def block_quote(quote)
        "<blockquote>#{quote}</blockquote>"
      end

      def hrule
        "<hr/>"
      end

      def image(link, title, alt_text)
        title_attr = title ? %( title="#{title}") : ""
        %(<img src="#{link}" alt="#{alt_text}"#{title_attr}/>)
      end
    end
  end
end

class MinimalMarkdownRender < Redcarpet::Render::MinimalHTML
  include Rouge::Plugins::Redcarpet
end
