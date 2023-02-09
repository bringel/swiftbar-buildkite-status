#!/usr/bin/env ruby
# frozen_string_literal: true

require 'net/http'
require 'json'

class BuildKiteService
  def initialize(org_name:, api_token:)
    @hostname = 'api.buildkite.com'
    @org_name = org_name
    @api_token = api_token
  end

  def user
    @user ||= JSON.parse(Net::HTTP.get(URI::HTTPS.build(host: @hostname, path: '/v2/user'), request_headers))
  end

  def all_user_builds
    res = Net::HTTP.get_response(
      URI::HTTPS.build(
        host: @hostname,
        path: "/v2/organizations/#{@org_name}/builds/",
        query: "creator=#{user['id']}"
      ),
      request_headers
    )

    JSON.parse(res.body)
  end

  def branch_builds(branch:)
    query = if branch.is_a?(Array)
              "branch[]=#{branch.join('&branch[]=')}"
            else
              "branch=#{branch}"
            end

    res = Net::HTTP.get_response(
      URI::HTTPS.build(
        host: @hostname,
        path: "/v2/organizations/#{@org_name}/builds/",
        query: query
      ),
      request_headers
    )

    JSON.parse(res.body)
  end

  private

  def request_headers
    {
      Authorization: "Bearer #{@api_token}",
      Accept: 'application/json'
    }
  end
end
