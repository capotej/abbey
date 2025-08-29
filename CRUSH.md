# CRUSH.md

## Commands

**Test**
- `rails test` - Run all tests except system tests
- `rails test test/models/post_test.rb` - Run specific test file
- `rails test test/models/post_test.rb:27` - Run specific test by line number
- `rails test:system` - Run system tests

**Lint/Format**
- `bundle exec rubocop` - Run linter (uses rubocop-rails-omakase)
- `bundle exec rubocop -a` - Auto-fix safe corrections
- `bundle exec brakeman` - Security analysis

**Development**
- `rails server` - Start development server
- `rails console` - Start Rails console
- `rails db:migrate` - Run migrations
- `rails db:seed` - Seed database

## Code Style

**Testing**: Uses Minitest with ActiveSupport::TestCase. Test files in `test/` directory.

**Linting**: Uses rubocop-rails-omakase (Omakase Ruby styling for Rails).

**Models**: Include concerns from `concerns/` directory. Use `validates_presence_of`, scopes, and lifecycle callbacks.

**Controllers**: Inherit from ApplicationController. Use `allow_unauthenticated_access` for public actions. Find records with `find_by_slug!` for posts.

**Naming**: Snake_case for methods/variables, CamelCase for classes. Use descriptive method names like `rendered_body` and `post_scope`.

**Structure**: Standard Rails MVC. Models in `app/models/`, controllers in `app/controllers/`, tests mirror app structure in `test/`.