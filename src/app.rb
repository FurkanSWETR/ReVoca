require 'telegram/bot'
require 'aws-sdk'
require_relative 'fb'

token = ENV.fetch('BOT_TOKEN')
base_uri = ENV.fetch('FIREBASE_URL')

languageMenu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(English Español), %w(Русский Français)], one_time_keyboard: true)

Telegram::Bot::Client.run(token) do |bot|

  new_klang = ""
  new_llang = ""

  state = 'idle'

  bot.listen do |message|
    fb = FB.new(message.chat.id, base_uri)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello. My name is Revoca. I can help you learn new languages. But I'm not a chat-bot!")

    when '/new'
      bot.api.send_message(chat_id: message.chat.id, text: 'Select a language you know:', reply_markup: languageMenu)
      state = 'new_1'

    when '/switch'
      vocs = fb.vocs.all 
      if (vocs && vocs.length > 1)
        vocs.map! { |v| Telegram::Bot::Types::KeyboardButton.new(text: v[:llang] + '-' + v[:klang]) }
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: vocs)
        bot.api.send_message(chat_id: message.chat.id, text: 'Select a vocabulary:', reply_markup: markup)
        state = 'switch_1'
      elsif vocs.length == 1
        bot.api.send_message(chat_id: message.chat.id, text: 'Sorry, you have just one vocabulary. If you want to switch, create a new one.')
      else
        bot.api.send_message(chat_id: message.chat.id, text: 'Actually, you have no vocabularies yet. Better create one now.')
      end

    when '/add'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    when '/word'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    when '/translation'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    when '/translate'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    when '/list'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    when '/notify'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')
    else
      case state
      when 'new_1'
        new_klang = message.text
        bot.api.send_message(chat_id: message.chat.id, text: 'Select a language you want to learn:', reply_markup: languageMenu)
        state = 'new_2'

      when 'new_2'
        new_llang = message.text
        if (fb.vocs.get_id(new_llang, new_klang) == nil)
          response = fb.vocs.create(new_llang, new_klang)
          fb.activate(response.body["name"])
          bot.api.send_message(chat_id: message.chat.id, text: "You've created " + new_llang + "-" + new_klang + " vocabulary. Add some words - it's empty now!")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "You already have similar vocabulary. Why you would want another one?")
        end
        state = 'idle'

      when 'switch_1'
        langs = message.text.split('-')
        fb.activate(fb.vocs.get_id(langs[0], langs[1]))
        bot.api.send_message(chat_id: message.chat.id, text: 'Successfully switched vocabulary.')
        state = 'idle'

      when 'idle'
        bot.api.send_message(chat_id: message.chat.id, text: "It's not a command. I don't understand you. I can help you with learning new words, but I'm not a chat-bot, you moron!")
      end
    end
  end
end
