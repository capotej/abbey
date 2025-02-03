body = %Q(
A place to link out to your projects.

You can [login](/session/new) to edit this Page. You can also and drag-and drop any image into the body to upload it and render it inline.

# Project 1

About project 1

# Project 2

Something about project 2

)

begin
  Page.create!(
    title: "Projects",
    markdown_body: body
  )
rescue ActiveRecord::RecordInvalid => e
  puts "Error importing #{e.message}"
rescue => e
  puts "Unexpected error #{e.message}"
end
