require "markdown_render"

module Rendering
  extend ActiveSupport::Concern
  include Rails.application.routes.url_helpers # Include the helpers


  included do
    def render(text)
      processed_markdown = Redcarpet::Markdown.new(MarkdownRender, fenced_code_blocks: true).render(text)

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
end
