# frozen_string_literal: true

require 'omniauth-oauth2'
require 'multi_json'

module OmniAuth
  module Strategies
    class Strava < OmniAuth::Strategies::OAuth2
      option :name, 'strava'
      option :client_options, {
        :site => 'https://strava.com/',
        :authorize_url => 'https://www.strava.com/oauth/authorize',
        :token_url => 'https://www.strava.com/oauth/token'
      }

      # Options
      # - scope
      #  The requested scopes of the eventual token, as a comma delimited string of `view_private` and/or `write`. By default, applications can only view a user’s public data. The scope parameter can be used to request more access. It is recommended to only requested the minimum amount of access necessary.
      # `public`: default, private activities are not returned, privacy zones are respected in stream requests.
      # `write`: modify activities, upload on the user’s behalf.
      # `view_private`: view private activities and data within privacy zones.
      # `view_private,write`:both ‘view_private’ and ‘write’ access.
      # - approval_prompt
      # `force` or `auto`, use `force` to always show the authorization prompt even if the user has already authorized the current application, default is ‘auto’.
      option :authorize_options, [:scope, :approval_prompt]

      def authorize_params
        super.tap do |params|
          params[:approval_prompt] = params['approval_prompt'].presence || 'auto'
          params[:scope] = params['scope'].presence || 'public'
        end
      end

      def request_phase
        super
      end

      def callback_phase
        super
      end

      uid { "#{athlete['id']}" }

      extra do
        {
          recent_ride_totals: athlete['recent_ride_totals'],
          ytd_ride_totals: athlete['ytd_ride_totals'],
          all_ride_totals: athlete['all_ride_totals'],
          raw_info: athlete
        }
      end

      info do
        {
          name: "#{athlete['firstname']} #{athlete['lastname']}",
          first_name: athlete['firstname'],
          last_name: athlete['lastname'],
          email: athlete['email'],
          location: "#{athlete['city']} #{athlete['state']}",
          image: athlete['profile']
        }
      end

      def athlete
        access_token.options[:mode] = :query
        access_token.options[:param_name] = :access_token
        @athlete ||= MultiJson.load(access_token.get('/api/v3/athlete', { access_token: access_token.token }).body)
      end

    end
  end
end
