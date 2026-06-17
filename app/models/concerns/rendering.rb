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
    # Resolve the Redcarpet renderer class to use for this request.
    #
    # Themes declare their renderer in their manifest:
    #
    #   Abbey::Theme.register(:retro) do |t|
    #     t.markdown_renderer = :minimal   # or :default, or a custom class
    #   end
    #
    # The default theme (no manifest) keeps `MarkdownRender` for backward
    # compatibility with existing imported posts that depend on its inline
    # Tailwind class output.
    def markdown_renderer
      Abbey::Theme.active.markdown_renderer
    end
  end
end
