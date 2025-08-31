Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  # logins
  resource :session

  # posts
  resources :posts, controller: "blog", except: :show

  get "/blog/:year/:month/:day/:id/", to: "blog#show", as: "dated_post"
  get "/blog/feed", to: "blog#feed", defaults: { format: "atom" }
  get "/post/*slug", to: "blog#redirect"

  # tags
  get "/t/:id", to: "blog#index_by_tag", as: "tag"
  get "/t/:id/feed", to: "blog#feed_by_tag", defaults: { format: "atom" }, as: "tag_feed"

  # pages
  resources :pages, except: :index, path: "p"

  # feed reader
  resources :feeds, except: :show
  resources :feed_posts, only: :index do
    post "/promote", to: "feed_posts#promote", as: "promote"
  end


  # links
  resources :links, except: :show
  get "/links/feed", to: "links#feed", defaults: { format: "atom" }

  # papers
  resources :papers, except: [ :show ] do
    get :download, on: :member
  end

  # handle old pages from capotej.com
  get "/about", to: redirect("/p/about")
  get "/projects", to: redirect("/p/projects")
  get "/presentations", to: redirect("/p/presentations")
  get "/render-image-links-directly-inside-adium", to: "blog#redirect"
  get "/finagle-with-scala-bootstrapper", to: "blog#redirect"
  get "/alfred-extension-for-creating-wunderlist-task", to: "blog#redirect"

  # home page
  root "blog#index"
end
