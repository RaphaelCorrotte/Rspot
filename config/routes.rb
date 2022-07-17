# frozen_string_literal: true

Rails.application.routes.draw do
  get "/login", :to => "login#login", :as => "login"
  get "/callback", :to => "login#callback", :as => "callback"
  get "/user", :to => "login#user", :as => "user"
  get "/refresh_token", :to => "login#refresh_token", :as => "refresh_token"
end
