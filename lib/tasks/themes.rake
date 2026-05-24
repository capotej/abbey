# frozen_string_literal: true

# Per-theme Tailwind builds.
#
# The default Abbey bundle (app/assets/tailwind/application.css) compiles
# to app/assets/builds/tailwind.css and explicitly EXCLUDES every theme
# folder from its @source scan. Each theme owns a self-contained
# app/themes/<name>/assets/tailwind.css that compiles to
# app/assets/builds/tailwind-<name>.css and is loaded only when that
# theme is active.
#
#   bin/rails tailwindcss:build   # default bundle + every theme bundle
#   bin/rails themes:tailwind:build
#   bin/rails themes:tailwind:watch   # one watcher per theme (for bin/dev)

require "tailwindcss/ruby"
require "tailwindcss/commands"

namespace :themes do
  namespace :tailwind do
    desc "Build a Tailwind bundle for every registered theme"
    task build: :environment do
      Abbey::Theme.load_all!
      builds = Abbey::Theme.registry.values.filter_map do |theme|
        input = theme.assets_path&.join("tailwind.css")
        next unless input&.exist?
        [theme.name.to_s, input, theme_output_path(theme.name)]
      end

      if builds.empty?
        puts "[themes] No theme tailwind.css inputs found, skipping."
        next
      end

      builds.each do |name, input, output|
        FileUtils.mkdir_p(output.dirname)
        cmd = build_command(input, output)
        puts "[themes] Building #{name}: #{output.relative_path_from(Rails.root)}"
        system(*cmd, exception: true)
      end
    end

    desc "Watch & rebuild every theme's Tailwind bundle (one process per theme)"
    task watch: :environment do
      Abbey::Theme.load_all!
      pids = []

      Abbey::Theme.registry.each do |name, theme|
        input  = theme.assets_path&.join("tailwind.css")
        next unless input&.exist?

        output = theme_output_path(name)
        FileUtils.mkdir_p(output.dirname)

        cmd = build_command(input, output, minify: false) + [ "-w" ]
        puts "[themes] Watching #{name}: #{output.relative_path_from(Rails.root)}"
        pids << Process.spawn(*cmd)
      end

      if pids.empty?
        puts "[themes] No theme tailwind.css inputs to watch."
        next
      end

      shutdown = ->(_sig) {
        pids.each { |pid| Process.kill("TERM", pid) rescue nil }
      }
      trap("INT",  shutdown)
      trap("TERM", shutdown)
      Process.waitall
    rescue Interrupt
      pids.each { |pid| Process.kill("TERM", pid) rescue nil }
    end

    desc "Remove every theme's compiled Tailwind bundle"
    task clobber: :environment do
      Abbey::Theme.load_all!
      Abbey::Theme.registry.each_key do |name|
        path = theme_output_path(name)
        if path.exist?
          puts "[themes] Removing #{path.relative_path_from(Rails.root)}"
          path.delete
        end
      end
    end
  end
end

# After the default tailwindcss:build runs, build every theme bundle too.
# `enhance(&block)` registers the block as an *after* action.
if Rake::Task.task_defined?("tailwindcss:build")
  Rake::Task["tailwindcss:build"].enhance do
    Rake::Task["themes:tailwind:build"].invoke
  end
end

if Rake::Task.task_defined?("tailwindcss:clobber")
  Rake::Task["tailwindcss:clobber"].enhance do
    Rake::Task["themes:tailwind:clobber"].invoke
  end
end

# Helpers — defined at the top level so the tasks above can call them.

def theme_output_path(name)
  Rails.root.join("app/assets/builds/tailwind-#{name}.css")
end

def build_command(input, output, minify: true)
  cmd = [ Tailwindcss::Ruby.executable, "-i", input.to_s, "-o", output.to_s ]
  cmd << "--minify" if minify && minify_default?
  postcss = Rails.root.join("postcss.config.js")
  cmd += [ "--postcss", postcss.to_s ] if postcss.exist?
  cmd
end

def minify_default?
  return false if ENV["TAILWINDCSS_DEBUG"].present?
  !Tailwindcss::Commands.rails_css_compressor?
end
