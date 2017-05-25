require 'telegram/bot'
require 'aws-sdk'
require 'i18n'

require_relative 'notifier'
require_relative 'respondent'

I18n.load_path = Dir[
  'src/config/en.yml',
  'src/config/es.yml',
  'src/config/fr.yml',
  'src/config/ru.yml'
]
I18n.config.available_locales = [:en, :es, :fr, :ru]
I18n.backend.load_translations

token = ENV.fetch('BOT_TOKEN')
creator = ENV.fetch('CREATOR')

Telegram::Bot::Client.run(token) do |bot|

  n = Notifier.new
  n.start(bot)

  bot.listen do |message| 
    r = Respondent.new(message)
    begin
      response = r.form_response()
      bot.api.send_message(chat_id: message.chat.id, text: response[:text], reply_markup: response[:markup])
    rescue Exception => e
      response = r.form_error()
      bot.api.send_message(chat_id: message.chat.id, text: response[:text], reply_markup: response[:markup])
      bot.api.send_message(chat_id: creator, text: "💣 " + e.message + "\n\n" + e.backtrace.inspect.to_s, reply_markup: nil)
    end
  end
end
