require 'telegram/bot'
require 'aws-sdk'

token = ENV.fetch('BOT_TOKEN')

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message.text
      when '/hello'
        kb = [Telegram::Bot::Types::KeyboardButton.new(text: 'Show me your location', request_location: true)]
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: kb)
        bot.api.send_message(chat_id: message.chat.id, text: 'Hey!', reply_markup: markup)
    end
  end
end
