body = %Q(
  This is your About Me page.

  You can [login](/session/new) to edit this Page. You can also and drag-and drop any image into the body to upload it and render it inline.
)

begin
  Page.create!(
    title: "About",
    markdown_body: body
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Error importing #{e.message}"
rescue => e
  puts "Unexpected error #{e.message}"
end
