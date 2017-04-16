require 'telegram/bot'
require 'aws-sdk'
require_relative 'fb'

token = ENV.fetch('BOT_TOKEN')
base_uri = ENV.fetch('FIREBASE_URL')

languageMenu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(English Español), %w(Русский Français)], one_time_keyboard: true)
yes_no_menu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(YES), %w(NO)], one_time_keyboard: true)

def help_text(state)
  case state
  when 'idle'
    "My name is Revoca. I can help you learn new languages.\n
    First you need to create a vocabulary using \/new comand. New vocabulary will automatically become active, but if you want to switch back, use \/switch.\n
    Empty vocabularies are boring: to add a new word type \/add.\n
    To train your vocabulary type \/word to get a random word in learning language or \/translation to get a translation. Then you'll be asked to translate it.\n
    To list the words from your vocabulary type \/list.\n
    To delete a vocabulary use \/delete.\n
    To change notification settings type \/notify and follow instructions.\n
    Hope you'll enjoy working with me. But let's keep it professional."

  when 'new_1', 'new_2'
    "You're in creating vocabulary sequence. Select language you want to learn, then select language you know. That's it.\n
    If you want to cancel it, just type \/cancel"

  when 'add_1', 'add_2', 'add_3'
    "You're adding words. First add word in the language you're learning, then its translations.\n
    If you want to cancel it, just type \/cancel"

  when 'switch_1'
    "You're trying to switch vocabularies. Choose one from menu.\n
    If you want to cancel it, just type \/cancel"

  when 'word_1'
    "We are playing words. I give you a word, you give me a translation. Roger?\n
    If you want to cancel it, just type \/cancel"
    
  when 'translation_1'
    "We are playing words. I give you a translation, you give me a word. Roger?\n
    If you want to cancel it, just type \/cancel"

  end
end


Telegram::Bot::Client.run(token) do |bot|

  new_klang = ""
  new_llang = ""
  new_word = ""
  new_translation = []
  current_word_id = nil

  state = 'idle'

  bot.listen do |message|
    fb = FB.new(message.chat.id, base_uri)
    case message.text
    when '/start'
      bot.api.send_message(chat_id: message.chat.id, text: "Hello. My name is Revoca. I can help you learn new languages. But I'm not a chat-bot!")

    when '/help'
      bot.api.send_message(chat_id: message.chat.id, text: help_text(state))

    when '/cancel'
      state = 'idle'
      new_klang = ""
      new_llang = ""
      new_word = ""
      new_translation = []
      current_word_id = nil

    when '/new'
      bot.api.send_message(chat_id: message.chat.id, text: 'Select a language you want to learn:', reply_markup: languageMenu)
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
      bot.api.send_message(chat_id: message.chat.id, text: 'Enter new word: ')
      state = 'add_1'

    when '/word'
      w = fb.current.words.get()
      current_word_id = w[:id]
      bot.api.send_message(chat_id: message.chat.id, text: 'Translate to '+ fb.current.klang + ': ' + w[:word])
      state = 'word_1'

    when '/translation'
      w = fb.current.words.get_translation()
      current_word_id = w[:id]
      bot.api.send_message(chat_id: message.chat.id, text: 'Translate to '+ fb.current.llang + ': ' + w[:translation])
      state = 'translation_1'

    when '/translate'
      bot.api.send_message(chat_id: message.chat.id, text: "Sorry, it's not implemented yet.")

    when '/list'
      words = fb.current.words.all()
      text = words.length.to_s + " words in your " + fb.current.llang + "-" + fb.current.klang + " dictionary:\n"
      text += words.map{ |w| "* " + w[:word] + " - " + w[:translation].join(', ')}.join("\n")
      bot.api.send_message(chat_id: message.chat.id, text: text)

    when '/notify'
      bot.api.send_message(chat_id: message.chat.id, text: 'New!')

    else
      case state
      when 'new_1'
        new_llang = message.text
        bot.api.send_message(chat_id: message.chat.id, text: 'Select a language you know:', reply_markup: languageMenu)
        state = 'new_2'
        
      when 'new_2'
        new_klang = message.text
        if (fb.vocs.get_id(new_llang, new_klang) == nil)
          response = fb.vocs.create(new_llang, new_klang)
          fb.activate(response.body["name"])
          bot.api.send_message(chat_id: message.chat.id, text: "You've created " + new_llang + "-" + new_klang + " vocabulary. Add some words - it's empty now!")
        else
          bot.api.send_message(chat_id: message.chat.id, text: "You already have similar vocabulary. Why you would want another one?")
        end
        new_llang = new_klang = nil
        state = 'idle'

      when 'switch_1'
        langs = message.text.split('-')
        fb.activate(fb.vocs.get_id(langs[0], langs[1]))
        bot.api.send_message(chat_id: message.chat.id, text: 'Successfully switched vocabulary.')
        state = 'idle'

      when 'add_1'
        new_word = message.text.downcase
        bot.api.send_message(chat_id: message.chat.id, text: 'Good, now enter translation: ')
        state = 'add_2'

      when 'add_2'
        new_translation.push(message.text.downcase)
        bot.api.send_message(chat_id: message.chat.id, text: 'Very well, want to add more translations?', reply_markup: yes_no_menu)
        state = 'add_3'

      when 'add_3'
        case message.text.upcase
        when 'YES'
          bot.api.send_message(chat_id: message.chat.id, text: 'OK, here you go.')
          state = 'add_2'
        when 'NO'
          fb.current.words.add({ word: new_word, translation: new_translation, created_at: Time.now})
          bot.api.send_message(chat_id: message.chat.id, text: new_word + ' has been added.')
          state = 'idle'
          new_word = nil
          new_translation = []
        end

      when 'word_1'
        answer = message.text
        if (fb.current.words.get_translation(current_word_id).index(answer) != nil)
          bot.api.send_message(chat_id: message.chat.id, text: 'Correct. You\'re a star!')
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'You\'re wrong. Keep training.')
        end
        state = 'idle'

      when 'translation_1'
        answer = message.text
        if (fb.current.words.get(current_word_id) == answer)
          bot.api.send_message(chat_id: message.chat.id, text: 'Correct. You\'re a star!')
        else
          bot.api.send_message(chat_id: message.chat.id, text: 'You\'re wrong. Keep training.')
        end
        state = 'idle'

      when 'idle'
        bot.api.send_message(chat_id: message.chat.id, text: "It's not a command. I don't understand you. I can help you with learning new words, but I'm not a chat-bot, you moron!")
      end
    end
  end
end
