# frozen_string_literal: true

require 'telegram/bot'

module TgBot
  class Action
    attr_reader :params, :message, :meta

    def initialize(message:, params:, meta: nil)
      @params = params
      @message = message
      @meta = meta
    end

    def call
      handle
      true
    rescue => e
      handle_exception(e)
      false
    end

    private

    def user
      @user ||= User.find_by(uuid: message.chat.id)
    end

    def client
      @client ||= Telegram::Bot::Api.new(ENV['BOT_TOKEN'])
    end

    def send_message(data)
      client.send_message(data.merge(chat_id: message.chat.id))
    end

    def edit_message_text(data)
      client.edit_message_text(data.merge(chat_id: message.chat.id, message_id: message[:message_id]))
    end

    def block_converastion(blockers:, lifetime: 24.hours.to_i)
      BlockConversation.new(uuid: message.chat.id, blockers: blockers, lifetime: :infinite).call
    end

    def handle_exception(exception)
      return send_message(text: exception.message) if exception.is_a? Bot::Error

      # Raven.capture_exception(exception)
      send_message text: I18n.t('bot.default_error')
    end
  end
end
