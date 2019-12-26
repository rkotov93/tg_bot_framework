# frozen_string_literal: true

Dir["../app/tg_bot/**/*.rb"].each { |path| require path }

module TgBot
  class WebhookHandler
    attr_reader :params, :message

    def initialize(params)
      @params = params
      @message = Telegram::Bot::Types::Update.new(params).current_message
    end

    def call
      return if message.edited_message # Do nothing if message edited
      return find_callback.call if message.callback_query
      return find_command.call unless redis.exists(blocker_key)

      success = find_blocker.call
      redis.lpop(blocker_key) if success
    end

    private

    def find_blocker
      meta = JSON.parse(redis.lindex(blocker_key, 0))
      name = meta.delete('name')
      klass = "blockers/#{name}_blocker".camelize.constantize
      klass.new(message: message, params: params, meta: meta)
    end

    def find_command
      text = message.text.split(' ').first
      name = COMMANDS.find { |command| text == "/#{command}" }
      return Bot::Commands::UnknownCommand.new(params) unless name

      klass = "commands/#{name}_command".camelize.constantize
      klass.new(message: message, params: params)
    end

    def find_callback
      data = JSON.parse(message.callback_query.data)
      name = data.delete('command')
      klass = "callbacks/#{name}_callback".camelize.constantize
      klass.new(message: message, params: params, meta: data)
    end

    def redis
      @redis ||= Redis.new
    end

    def blocker_key
      @blocker_key ||= "user_#{message.from.uuid}_blocked_by"
    end
  end
end
