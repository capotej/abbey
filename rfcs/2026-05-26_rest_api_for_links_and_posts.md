# REST API for Links and Posts

**Date:** 2026-05-26
**Status:** Proposed

## Goal

Add a JSON REST API to Abbey for creating, editing, and managing draft/published state of links and posts. This enables programmatic content management (e.g., from agents, scripts, or external tools) without going through the HTML form interface.

## Motivation

Currently all content creation and editing happens through the browser UI. Adding a REST API allows:

- Automated posting from agents and scripts
- Quick link saving via API calls (e.g., from a bookmarklet or mobile device)
- Programmatic draft management (create drafts, edit, publish when ready)
- Future integrations with other tools and services

## Proposed Endpoints

### Authentication

All API endpoints require an API key passed as a Bearer token in the `Authorization` header:

```text
Authorization: Bearer <api_key>
```

API keys are generated per-user and stored in the database. The key is not the session cookie — it's a separate token specifically for API access.

### Posts

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/api/posts` | List posts (respecting draft status for unauthenticated) | Optional |
| `GET` | `/api/posts/:slug` | Get a single post by slug | Optional |
| `POST` | `/api/posts` | Create a new post | Required |
| `PATCH` | `/api/posts/:slug` | Update an existing post | Required |
| `DELETE` | `/api/posts/:slug` | Delete a post | Required |

### Links

| Method | Endpoint | Description | Auth |
|--------|----------|-------------|------|
| `GET` | `/api/links` | List links | Optional |
| `POST` | `/api/links` | Create a new link (auto-fetches title/description) | Required |
| `PATCH` | `/api/links/:id` | Update a link's title, description, or URL | Required |
| `DELETE` | `/api/links/:id` | Delete a link | Required |

### Request/Response Shapes

#### Create Post

```json
// POST /api/posts
{
  "title": "My New Post",
  "markdown_body": "Hello world...",
  "markdown_excerpt": "A short excerpt",
  "post_tags": "ruby,rails,api",
  "draft": true
}

// Response: 201 Created
{
  "slug": "my-new-post",
  "title": "My New Post",
  "excerpt": "A short excerpt",
  "tags": ["ruby", "rails", "api"],
  "draft": true,
  "created_at": "2026-05-26T00:00:00Z",
  "updated_at": "2026-05-26T00:00:00Z",
  "url": "/blog/2026/05/26/my-new-post/"
}
```

#### Update Post

```json
// PATCH /api/posts/my-new-post
{
  "title": "Updated Title",
  "draft": false
}

// Response: 200 OK
{
  "slug": "updated-title",
  "title": "Updated Title",
  "excerpt": "A short excerpt",
  "tags": ["ruby", "rails", "api"],
  "draft": false,
  "created_at": "2026-05-26T00:00:00Z",
  "updated_at": "2026-05-26T00:01:00Z",
  "url": "/blog/2026/05/26/updated-title/"
}
```

#### Create Link

```json
// POST /api/links
{
  "url": "https://example.com/article"
}

// Response: 201 Created
{
  "id": 42,
  "title": "Auto-fetched from page",
  "description": "Auto-fetched meta description",
  "url": "https://example.com/article",
  "created_at": "2026-05-26T00:00:00Z"
}
```

#### Update Link

```json
// PATCH /api/links/42
{
  "title": "Custom Title",
  "description": "Custom description"
}

// Response: 200 OK
{
  "id": 42,
  "title": "Custom Title",
  "description": "Custom description",
  "url": "https://example.com/article",
  "created_at": "2026-05-26T00:00:00Z"
}
```

### Draft State

Draft state is controlled via the `draft` boolean field on posts:

- `"draft": true` — post is not visible in public feeds or listings
- `"draft": false` (or omitted) — post is published and publicly visible
- Updating `draft` from `true` to `false` publishes the post
- The `published_at` timestamp should be set when a post is first published (draft → non-draft transition)

Links do not have a draft state — they are always publicly visible once created.

### Error Responses

All errors return a JSON body with a descriptive message:

```json
// 401 Unauthorized
{ "error": "Invalid or missing API key" }

// 404 Not Found
{ "error": "Post not found" }

// 422 Unprocessable Entity
{ "error": "Validation failed", "details": { "title": ["can't be blank"] } }
```

## Technical Details

### API Key Model

New `ApiKey` model:

- `id` — primary key
- `user_id` — belongs to user
- `name` — human-readable label (e.g., "Hermes Agent")
- `token_digest` — SHA256 hash of the raw token (never stored plaintext)
- `last_used_at` — timestamp of last API request
- `created_at`, `expires_at` — lifecycle timestamps
- Raw token is shown only once at creation time

### Routing

API routes live under `/api` namespace in `config/routes.rb`:

```ruby
namespace :api do
  resources :posts, only: %i[index show create update destroy], param: :slug
  resources :links, only: %i[index create update destroy]
end
```

### Controllers

New `Api::PostsController` and `Api::LinksController` in `app/controllers/api/`. These are separate from the existing `BlogController` and `LinksController` to keep concerns separated. They share model logic but have their own rendering (JSON instead of HTML).

### Authentication Middleware

API authentication uses a concern similar to the existing `Authentication` concern, but checking for Bearer token instead of session cookies. The `ApiController` base class skips the `request_authentication` redirect and returns `401 JSON` instead.

### Existing Behavior Unchanged

- The HTML UI controllers (`BlogController`, `LinksController`) are untouched
- Public routes (`/blog/*`, `/links`, feeds) continue to work as before
- Session-based authentication for the admin UI is unchanged
- The `Post.published` scope still gates public visibility

## Implementation Checklist

- [ ] Create `ApiKey` model and migration
- [ ] Create `app/controllers/api/application_controller.rb` with Bearer token auth
- [ ] Create `app/controllers/api/posts_controller.rb` with CRUD + draft state
- [ ] Create `app/controllers/api/links_controller.rb` with CRUD
- [ ] Add API routes to `config/routes.rb`
- [ ] Add view/UI for generating and managing API keys in the admin area
- [ ] Set `published_at` on draft → published transitions
- [ ] Add tests for all API endpoints (creation, editing, draft state, auth, errors)
- [ ] Update `AGENTS.md` with new commands and API documentation
