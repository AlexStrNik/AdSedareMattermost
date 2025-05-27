# frozen_string_literal: true

require "adsedare"
require "faraday"

require_relative "adsedare_mattermost/version"

module AdsedareMattermost
  class Error < StandardError; end

  class Provider < Starship::TwoFactorProvider
    include Logging

    def initialize(
      extract_2fa_code = nil
    )
      @extract_2fa_code = extract_2fa_code
      unless @extract_2fa_code
        raise Error, "Pass extract_2fa_code block"
      end

      @token = ENV["ADSEDARE_MM_TOKEN"]
      @mm_host = ENV["ADSEDARE_MM_HOST"]

      @team_id = ENV["ADSEDARE_MM_TEAM_ID"]
      team_name = ENV["ADSEDARE_MM_TEAM_NAME"]

      @channel_id = ENV["ADSEDARE_MM_CHANNEL_ID"]
      channel_name = ENV["ADSEDARE_MM_CHANNEL_NAME"]

      unless @token
        raise Error, "ADSEDARE_MM_TOKEN is not set"
      end

      unless @mm_host
        raise Error, "ADSEDARE_MM_HOST is not set"
      end

      unless team_name || @team_id
        raise Error, "ADSEDARE_MM_TEAM_NAME and ADSEDARE_MM_TEAM_ID is not set"
      end

      unless @team_id
        logger.warn "ADSEDARE_MM_TEAM_ID is not set, will find by name: #{team_name}"
        @team_id = my_teams.find { |team| team["display_name"] == team_name }["id"]
        raise Error, "Team #{team_name} not found" unless @team_id
        logger.info "Using team: #{@team_id}"
      end

      unless channel_name || @channel_id
        raise Error, "ADSEDARE_MM_CHANNEL_NAME and ADSEDARE_MM_CHANNEL_ID is not set"
      end

      unless @channel_id
        logger.warn "ADSEDARE_MM_CHANNEL_ID is not set, will find by name: #{channel_name}"
        @channel_id = my_channels.find { |channel| channel["display_name"] == channel_name }["id"]
        raise Error, "Channel #{channel_name} not found" unless @channel_id
        logger.info "Using channel: #{@channel_id}"
      end

      @timeout_seconds = ENV["ADSEDARE_MM_TIMEOUT_SECONDS"] || 5
      @retry_limit = ENV["ADSEDARE_MM_RETRY_LIMIT"] || 5
      @since = Time.now

      @retry_counter = 0
    end

    def my_teams
      response = Faraday.get("#{@mm_host}/api/v4/users/me/teams") do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
      end
      raise Error, "Failed to get teams" unless response.success?

      JSON.parse(response.body)
    end

    def my_channels
      response = Faraday.get("#{@mm_host}/api/v4/users/me/teams/#{@team_id}/channels") do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
      end
      raise Error, "Failed to get channels" unless response.success?

      JSON.parse(response.body)
    end

    def latest_posts
      response = Faraday.get("#{@mm_host}/api/v4/channels/#{@channel_id}/posts?since=#{@since.to_i}") do |req|
        req.headers["Authorization"] = "Bearer #{@token}"
      end
      raise Error, "Failed to get messages" unless response.success?

      JSON.parse(response.body)["posts"]
    end

    def retry_get_code
      if @retry_counter > @retry_limit
        return nil
      end

      logger.info "Retry #{@retry_counter} of #{@retry_limit}"
      logger.info "Waiting for #{@timeout_seconds} seconds for 2FA code..."

      sleep(@timeout_seconds)
  
      # Update before request, since we dont want to miss messages due to any network delays
      new_since = (Time.now.to_f * 1000).to_i

      latest_messages = latest_posts.values.map { |post| post["message"] }
      code = @extract_2fa_code.call(latest_messages)

      @since = new_since
      @retry_counter += 1

      return code if code

      retry_get_code
    end

    def get_code(session_id, scnt)      
      @retry_counter = 1
      # Just to be sure we dont miss messages because Apple sends it before we got there
      @since = (Time.now.to_f * 1000).to_i - 3000
      
      code = retry_get_code

      return code if code
      raise Error, "2FA code not found"
    end

    def two_factor_type
      "phone"
    end
  end
end
