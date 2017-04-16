require 'telegram/bot'
require 'aws-sdk'
require_relative 'fb'

token = ENV.fetch('BOT_TOKEN')
base_uri = ENV.fetch('FIREBASE_URL')

languageMenu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(English Español), %w(Русский Français)], one_time_keyboard: true)
yes_no_menu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(YES), %w(NO)], one_time_keyboard: true)
tick_menu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(Hourly), %w(Daily), %(Weekly), %(Never)], one_time_keyboard: true)

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

  fb = FB.new(base_uri)

  bot.listen do |message| 
    chat_id = message.chat.id.to_s
    current_id = fb.vocs.active(chat_id)
    current = current_id ? fb.vocs.get(chat_id, fb.vocs.active(chat_id)) : nil

    case message.text
    when '/start'
      bot.api.send_message(chat_id: chat_id, text: "Hello. My name is Revoca. I can help you learn new languages. But I'm not a chat-bot!")
      fb.state.set(chat_id, 'idle')

    when '/help'
      bot.api.send_message(chat_id: chat_id, text: help_text(fb.state.now(chat_id)))

    when '/admin'
      bot.api.send_message(chat_id: chat_id, text: fb.total_users)

    when '/cancel'
      fb.state.set(chat_id, 'idle')

    when '/new'
      bot.api.send_message(chat_id: chat_id, text: 'Select a language you want to learn:', reply_markup: languageMenu)
      fb.state.set(chat_id, 'new_1')

    when '/switch'
      vocs = fb.vocs.all(chat_id)
      if (vocs && vocs.length > 1)
        vocs.map! { |v| Telegram::Bot::Types::KeyboardButton.new(text: v[:llang] + '-' + v[:klang]) }
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: vocs)
        bot.api.send_message(chat_id: chat_id, text: 'Select a vocabulary:', reply_markup: markup)
        fb.state.set(chat_id, 'switch_1')
      elsif vocs.length == 1
        bot.api.send_message(chat_id: chat_id, text: 'Sorry, you have just one vocabulary. If you want to switch, create a new one.')
      else
        bot.api.send_message(chat_id: chat_id, text: 'Actually, you have no vocabularies yet. Better create one now.')
      end

    when '/add'
      bot.api.send_message(chat_id: chat_id, text: 'Enter new word: ')
      fb.state.set(chat_id, 'add_1')

    when '/word'
      w = fb.vocs.words.get(chat_id, current[:id])
      fb.temp.cw_id(chat_id, w[:id])
      bot.api.send_message(chat_id: chat_id, text: 'Translate to '+ current[:klang] + ': ' + w[:word])
      fb.state.set(chat_id, 'word_1')

    when '/translation'
      w = fb.vocs.words.translation(chat_id, current[:id])
      fb.temp.cw_id(chat_id, w[:id])
      bot.api.send_message(chat_id: chat_id, text: 'Translate to '+ current[:llang] + ': ' + w[:translation])
      fb.state.set(chat_id, 'translation_1')

    when '/translate'
      bot.api.send_message(chat_id: chat_id, text: "Sorry, it's not implemented yet.")

    when '/list'
      words = fb.vocs.words.all(chat_id, current[:id])
      text = words.length.to_s + " words in your " + current[:llang] + "-" + current[:klang] + " dictionary:\n"
      text += words.map{ |w| "* " + w[:word] + " - " + w[:translation].join(', ')}.join("\n")
      bot.api.send_message(chat_id: chat_id, text: text)

    when '/notify'
      bot.api.send_message(chat_id: chat_id, text: 'First, how often you want my notifications: ', reply_markup: tick_menu)
      fb.state.set(chat_id, 'notify_1')

    else
      state = fb.state.now(chat_id)
      case state
      when 'new_1'
        fb.temp.llang(chat_id, message.text)
        bot.api.send_message(chat_id: chat_id, text: 'Select a language you know:', reply_markup: languageMenu)
        fb.state.set(chat_id, 'new_2')
        
      when 'new_2'
        llang = fb.temp.llang(chat_id)
        klang = message.text
        if (fb.vocs.id(chat_id, {llang: llang, klang: klang}) == nil)
          response = fb.vocs.create(chat_id, {llang: llang, klang: klang})
          fb.vocs.activate(chat_id, response.body["name"])
          fb.temp.clear(chat_id)
          bot.api.send_message(chat_id: chat_id, text: "You've created " + llang + "-" + klang + " vocabulary. Add some words - it's empty now!")
        else
          bot.api.send_message(chat_id: chat_id, text: "You already have similar vocabulary. Why you would want another one?")
        end
        fb.state.set(chat_id, 'idle')

      when 'switch_1'
        langs = message.text.split('-')
        fb.vocs.activate(chat_id, fb.vocs.id(chat_id, {llang: langs[0], klang: langs[1]}))
        bot.api.send_message(chat_id: chat_id, text: 'Successfully switched vocabulary.')
        fb.state.set(chat_id, 'idle')

      when 'add_1'
        fb.temp.word(chat_id, message.text.downcase)
        bot.api.send_message(chat_id: chat_id, text: 'Good, now enter translation: ')
        fb.state.set(chat_id, 'add_2')

      when 'add_2'
        fb.temp.translation(chat_id, message.text.downcase)
        bot.api.send_message(chat_id: chat_id, text: 'Very well, want to add more translations?', reply_markup: yes_no_menu)
        fb.state.set(chat_id, 'add_3')

      when 'add_3'
        case message.text.upcase
        when 'YES'
          bot.api.send_message(chat_id: chat_id, text: 'OK, here you go.')
          fb.state.set(chat_id, 'add_2')
        when 'NO'
          word = fb.temp.word(chat_id)
          translation = fb.temp.translation(chat_id)
          fb.vocs.words.add(chat_id, current[:id], { word: word, translation: translation, created_at: Time.now})
          bot.api.send_message(chat_id: chat_id, text: word + ' has been added.')
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        end

      when 'word_1'
        answer = message.text
        if (fb.vocs.words.translation(chat_id, current[:id], fb.temp.cw_id(chat_id)).index(answer) != nil)
          bot.api.send_message(chat_id: chat_id, text: 'Correct. You\'re a star!')
        else
          bot.api.send_message(chat_id: chat_id, text: 'You\'re wrong. Keep training.')
        end
        fb.temp.clear(chat_id)
        fb.state.set(chat_id, 'idle')

      when 'translation_1'
        answer = message.text
        if (fb.vocs.words.get(chat_id, current[:id], fb.temp.cw_id(chat_id)) == answer)
          bot.api.send_message(chat_id: chat_id, text: 'Correct. You\'re a star!')
        else
          bot.api.send_message(chat_id: chat_id, text: 'You\'re wrong. Keep training.')
        end
        fb.temp.clear(chat_id)
        fb.state.set(chat_id, 'idle')

      when 'notify_1'
        case message.text
        when 'Never'
          bot.api.send_message(chat_id: chat_id, text: 'Okay, no notification then.')
          fb.set_notifications(chat_id)
          fb.state.set(chat_id, 'idle')
        else
          case message.text
          when 'Hourly'
            fb.temp.tick(chat_id, 1)
          when 'Daily'
            fb.temp.tick(chat_id, 24)
          when 'Weekly'
            fb.temp.tick(chat_id, 168)
          end
          bot.api.send_message(chat_id: chat_id, text: 'Now, how many ' + message.text[0..-3].downcase + 's you want between my notifications?')
          fb.state.set(chat_id, 'notify_2')
        end

      when 'notify_2'
        n = Integer(message.text) rescue nil
        if (n && n.between?(0, 30))
          bot.api.send_message(chat_id: chat_id, text: "Notification settings have been changed.")
          t = Time.now
          t = Time.new(t.year, t.month, t.day, t.hour)
          fb.set_notifications(chat_id, {start: t, tick: n * fb.temp.tick(chat_id)})
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: "Something is wrong. I don't understand. Probably it'st not an integer, less than 0 or bigger than 30. Try again.")
        end

      when 'idle'
        bot.api.send_message(chat_id: chat_id, text: "It's not a command. I don't understand you. I can help you with learning new words, but I'm not a chat-bot, you moron!")
      end
    end
  end
end
