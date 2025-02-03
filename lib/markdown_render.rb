require "redcarpet"
require "rouge"
require "rouge/plugins/redcarpet"

module Redcarpet
  module Render
    class TailwindHTML < ::Redcarpet::Render::HTML
      def normal_text(text)
        text
      end

      def block_code(code, language)
        <<~HTML
          <pre class="p-4 my-4 bg-gray-100 dark:bg-gray-800 rounded-lg overflow-x-auto">
            <code class="text-sm text-gray-800 dark:text-gray-200">#{code}</code>
          </pre>
        HTML
      end

      def header(title, level)
        css_classes = case level
        when 1
          "text-3xl font-bold text-gray-900 dark:text-white mb-6"
        when 2
          "text-2xl font-semibold text-gray-800 dark:text-gray-100 mb-4"
        when 3
          "text-xl font-medium text-gray-800 dark:text-gray-100 mb-3"
        end

        "<h#{level} class=\"#{css_classes}\">#{title}</h#{level}>"
      end

      def paragraph(text)
        "<p class=\"text-gray-600 dark:text-gray-300 leading-relaxed mb-4\">#{text}</p>"
      end

      def list(content, list_type)
        css_class = "space-y-2 my-4 ml-4"
        tag = list_type == :ordered ? "ol" : "ul"
        "<#{tag} class=\"#{css_class}\">#{content}</#{tag}>"
      end

      def list_item(content, list_type)
        "<li class=\"text-gray-600 dark:text-gray-300\">#{content}</li>"
      end

      def link(link, title, content)
        "<a href=\"#{link}\" class=\"text-blue-600 dark:text-blue-400 hover:underline\">#{content}</a>"
      end

      def emphasis(text)
        "<em class=\"text-gray-700 dark:text-gray-200 italic\">#{text}</em>"
      end

      def double_emphasis(text)
        "<strong class=\"text-gray-900 dark:text-white font-semibold\">#{text}</strong>"
      end
    end
  end
end

class MarkdownRender < Redcarpet::Render::TailwindHTML
  include Rouge::Plugins::Redcarpet
end
