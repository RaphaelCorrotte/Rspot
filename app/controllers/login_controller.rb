# frozen_string_literal: true

require "rest-client"
require "dotenv/load"
require "addressable/uri"

class LoginController < ApplicationController
  attr_accessor :token, :redirect_uri, :scope
  def initialize
    @redirect_uri = "http://localhost:3000/callback"
    # The needed scopes to fully access the API
    @scope = scope = "user-read-private user-read-email user-read-playback-state user-modify-playback-state user-read-recently-played user-read-playback-position user-top-read "
  end

  # The endpoint to login to Spotify
  def login
    # generates a random string of length 16
    state = proc { (0...16).map { rand(65..90).chr }.join }.call
    uri = Addressable::URI.new
    uri.query_values = ({
      :response_type => "code",
      :client_id => ENV["CLIENT_ID"],
      :scope => @scope,
      :redirect_uri => @redirect_uri,
      :state => state,
      :show_dialog => true
    })
    # redirects to the Spotify login page
    redirect_to("https://accounts.spotify.com/authorize?#{uri.query}", :allow_other_host => true)
  end

  # The endpoint to manage the connexion
  def callback
    request_body = {
      :code => params[:code],
      :redirect_uri => @redirect_uri,
      :grant_type => "authorization_code"
    }
    # Make a request to the Spotify API to get the access token
    response = RestClient.post("https://accounts.spotify.com/api/token", request_body, { :Authorization => "Basic #{Base64.strict_encode64("#{ENV["CLIENT_ID"]}:#{ENV["CLIENT_SECRET"]}")}" })
    token = JSON.parse(response.body)["access_token"]
    refresh_token = JSON.parse(response.body)["refresh_token"]
    redirect_to("/user?token=#{token}&refresh_token=#{refresh_token}?code=#{params[:code]}")
  end

  # the endpoint to display the user's profile
  def user
    # make a query to get data
    response = RestClient.get("https://api.spotify.com/v1/me", { :Authorization => "Bearer #{params[:token]}", :"Content-type" => "application/json" })

    @response = response
  rescue RestClient::Unauthorized
    redirect_to("/login")
  rescue RestClient::BadRequest
    redirect_to("/refresh_token?code=#{params[:code]}&refresh_token=#{params[:refresh_token]}")
  end

  def refresh_token
    request_body = {
      :code => params[:code],
      :redirect_uri => @redirect_uri,
      :grant_type => "refresh_token",
      :refresh_token => params[:refresh_token]
    }
    response = RestClient.post("https://accounts.spotify.com/api/token", request_body, { :Authorization => "Basic #{Base64.strict_encode64("#{ENV["CLIENT_ID"]}:#{ENV["CLIENT_SECRET"]}")}" })
    token = JSON.parse(response.body)["access_token"]
    redirect to("/user?token=#{token}&refresh_token=#{refresh_token}?code=#{params[:code]}")
  end
end
