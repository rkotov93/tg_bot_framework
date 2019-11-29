# frozen_string_literal: true

require 'redis'

module Bot
  class BlockConversation
    attr_reader :uuid, :blockers, :lifetime

    def initialize(uuid:, blockers:, lifetime: 24.hours.to_i)
      @uuid = uuid
      @blockers = Array.wrap(blockers).map(&:to_json)
      @lifetime = lifetime
    end

    def call
      redis = Redis.new
      redis.rpush(key, blockers)
      redis.expire(key, lifetime) unless lifetime == :infinite
    end

    private

    def key
      "user_#{uuid}_blocked_by"
    end
  end
end
