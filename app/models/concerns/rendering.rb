require "markdown_render"
require "minimal_markdown_render"

module Rendering
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers # Include the helpers


  included do
    def render(text)
      processed_markdown = Redcarpet::Markdown.new(self.class.markdown_renderer, fenced_code_blocks: true).render(text)

      # Replace signed IDs with img tags, handling both href and src attributes
      processed_markdown.gsub!(/(href|src)="(.*?)"/) do |match|
        attribute = $1 # Capture the attribute name (href or src)
        signed_id = $2 # Capture the signed ID value
        if signed_id.present? && self.respond_to?(:markdown_body_attachments)
          begin
            blob = ActiveStorage::Blob.find_signed(signed_id)
            if blob
              "#{attribute}=\"#{blob.url}\"" # Reconstruct the attribute with the correct URL
            else
              match
            end
          rescue ActiveStorage::FileNotFoundError
            match # Return the original match if the signed ID is invalid
          end
        else
          match # Return the original match if not a signed ID or no attachments
        end
      end

      processed_markdown
    end
  end

  class_methods do
    # Themes can request the minimal renderer (semantic HTML, no inline
    # Tailwind classes) by adding their name to
    # Rails.application.config.themes_using_minimal_renderer (Array<String>).
    # The default theme keeps the original MarkdownRender for backwards
    # compatibility with existing imported posts.
    def markdown_renderer
      themes = Rails.application.config.try(:themes_using_minimal_renderer) || []
      active = Rails.application.config.try(:theme).to_s
      themes.include?(active) ? MinimalMarkdownRender : MarkdownRender
    end
  end
end
