namespace :blog do
  desc "Convert markdown posts to seed files"
  task :import, [:path] do |t, args|
    require 'yaml'
    require 'fileutils'

    path = args[:path] || '.'
    source_path = File.expand_path(path)
    abort "Error: Directory #{source_path} not found" unless Dir.exist?(source_path)

    FileUtils.mkdir_p('db/seeds')

    Dir.glob(File.join(source_path, '*.markdown')).each do |file|
      content = File.read(file)

      # Parse front matter
      if content =~ /\A(---\s*\n.*?\n?)^(---\s*$\n?)/m
        front_matter = YAML.safe_load($1, permitted_classes: [Time])
        body = content[$1.length + $2.length..-1]
      else
        puts "Skipping #{file} - no front matter found"
        next
      end

      seed_filename = "db/seeds/#{File.basename(file, '.markdown')}.rb"

      # Get excerpt from first 25 words
      excerpt = body.split(/\s+/)[0...25].join(' ').strip

      # Use URL if present, otherwise use filename
      url = if front_matter['url']
        front_matter['url']
      end

      # Process tags if present
      post_tags = if front_matter['tags'].is_a?(Array)
        front_matter['tags'].join(',')
      elsif front_matter['tags']
        front_matter['tags'].to_s
      end

      attrs = {
        title: front_matter['title'].to_json,
        created_at: front_matter['date'].to_json,
        markdown_body: body.strip.to_json,
        markdown_excerpt: excerpt.to_json
      }

      attrs[:redirect_from] = url.to_json if url
      attrs[:post_tags] = post_tags.to_json if post_tags

      attrs_string = attrs.map { |k,v| "#{k}: #{v}" }.join(",\n            ")

      seed_content = <<~RUBY
        begin
          Post.create!(
            #{attrs_string}
          )
          puts "Imported \#{#{front_matter['title'].to_json}}"
        rescue ActiveRecord::RecordInvalid => e
          puts "Error importing #{File.basename(file)}: \#{e.message}"
        rescue => e
          puts "Unexpected error importing #{File.basename(file)}: \#{e.message}"
        end
      RUBY

      File.write(seed_filename, seed_content)
      puts "Created #{seed_filename}"
    end
  end
end
