require 'telegram/bot'
require 'aws-sdk'
require 'i18n'

require_relative 'fb'
require_relative 'format'
require_relative 'language'
require_relative 'translate'
require_relative 'menu'
require_relative 'command'

I18n.load_path = Dir['src/config/en.yml', 'src/config/ru.yml', 'src/config/es.yml', 'src/config/fr.yml']
I18n.config.available_locales = [:en, :ru, :es, :fr]
I18n.backend.load_translations

token = ENV.fetch('BOT_TOKEN')
base_uri = ENV.fetch('FIREBASE_URL')

def help_text(state, locale)
  case state
  when 'games'
    { text: I18n.t('games.help', :locale => locale), reply_markup: Menu.games_menu(locale) }
  when 'idle'
    { text: I18n.t('main.help', :locale => locale), reply_markup: Menu.main_menu(locale) }
  when 'language'
    { text: I18n.t('settings.language.help', :locale => locale), reply_markup: Menu.language_menu(locale) } 
  when 'new_1', 'new_2'
    { text: I18n.t('vocabularies.new.help', :locale => locale), reply_markup: Menu.language_menu(locale) }
  when 'notify', 'settings'
    { text: I18n.t('settings.help', :locale => locale), reply_markup: Menu.settings_menu(locale) }
  when 'repeat'
    { text: I18n.t('games.repeat.help', :locale => locale), reply_markup: Menu.games_repeat_menu(locale) }
  when 'translate'
    { text: "To Do", reply_markup: Menu.remove() }
  when 'vocabularies', 'voc_switch', 'voc_delete'
    { text: I18n.t('vocabularies.help', :locale => locale), reply_markup: Menu.vocabularies_menu(locale) }
  when 'add_1', 'add_2', 'add_3', 'words'
    { text: I18n.t('words.help', :locale => locale), reply_markup: Menu.words_menu(locale) }
  else
    I18n.t('help.unknown', :locale => locale)
  end
end

Telegram::Bot::Client.run(token) do |bot|

  fb = FB.new(base_uri)

  thr = Thread.new {
    tfb = FB.new(base_uri)
    t = Time.now
    tfb.notify.global(Time.new(t.year, t.month, t.day, t.hour))

    loop do
      notified = tfb.notify.all
      notified.each do |n| 
        chat_id = n[:id]
        locale = tfb.locale(chat_id)

        if(Time.parse(n[:next]) < Time.now) 
          tfb.notify.set(chat_id, n[:tick].to_i)
          current = tfb.vocs.get(chat_id, fb.vocs.active(chat_id))
          w = tfb.vocs.words.get(chat_id, current[:id])

          if (w)
            word = w['word']
            translations = w['translation'].to_a
            
            text = I18n.t('languages.flags.' + current[:llang], :locale => locale) + I18n.t('languages.names.' + current[:llang], :locale => locale) + ": " + word + "\n"
            text += I18n.t('languages.flags.' + current[:klang], :locale => locale) + I18n.t('languages.names.' + current[:klang], :locale => locale) + ": "
            text += translations.map.with_index {|x, i| (i+1).to_s + ") " + x }.join("; ")

            bot.api.send_message(chat_id: n[:id], text: text)
          end
        end
      end

      global_next = tfb.notify.global + 60*60
      tfb.notify.global(global_next)
      sleep(global_next - Time.now + 1)
    end
  }

  bot.listen do |message| 
    chat_id = message.chat.id.to_s
    locale = fb.locale(chat_id)

    current_id = fb.vocs.active(chat_id)
    current = current_id ? fb.vocs.get(chat_id, current_id) : nil

    case message.text
    when '/start'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('hello', :locale => locale), reply_markup: Menu.main_menu(locale))
      fb.state.set(chat_id, 'idle')

    when '/help'
      help = help_text(fb.state.now(chat_id), locale)
      bot.api.send_message(chat_id: chat_id, text:  help[:text], reply_markup: help[:reply_markup])

    when '/cancel'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
      fb.state.set(chat_id, 'idle')

    when '/new_vocabulary'
      Command.new_vocabulary(bot, fb, chat_id, locale)

    when '/switch_vocabulary'
      Command.switch_vocabulary(bot, fb, chat_id, locale)

    when '/delete_vocabulary'
      Command.delete_vocabulary(bot, fb, chat_id, locale)

    when '/add_word'
      Command.new_word(bot, fb, chat_id, locale)

    when '/translate_word'
      Command.translate(bot, fb, chat_id, locale)

    when '/list_words'
      Command.list_words(bot, fb, current, chat_id, locale)    

    when '/change_notification_settings'
      Command.change_notification_period(bot, fb, current, chat_id, locale)

    when '/change_language'
      Command.change_language(bot, fb, chat_id, locale)

    else
      state = fb.state.now(chat_id)
      case state     

      when 'games'
        case(message.text)
        when I18n.t('menu.games.guess', :locale => locale) # todo
          bot.api.send_message(chat_id: chat_id, text: I18n.t('todo', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        when I18n.t('menu.games.repeat', :locale => locale)
          fb.temp.game_score(chat_id, 0)
          Command.repeat_game(bot, fb, current, chat_id, locale)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.help', :locale => locale), reply_markup: Menu.games_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.games_menu(locale))
        end

      when 'idle'
        case(message.text)
        when I18n.t('menu.main.games', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.info', :locale => locale), reply_markup: Menu.games_menu(locale))
          fb.state.set(chat_id, 'games')
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.help', :locale => locale), reply_markup: Menu.main_menu(locale))      
        when I18n.t('menu.main.settings', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.info', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        when I18n.t('menu.main.translate', :locale => locale)
          Command.translate(bot, fb, chat_id, locale)
        when I18n.t('menu.main.vocabulary', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.info', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
          fb.state.set(chat_id, 'vocabularies')
        when I18n.t('menu.main.word', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('words.info', :locale => locale), reply_markup: Menu.words_menu(locale))
          fb.state.set(chat_id, 'words')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.main_menu(locale))
        end

      when 'language'
        if(message.text == I18n.t('menu.back', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.info', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        elsif(message.text == I18n.t('menu.help', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.language.help', :locale => locale), reply_markup: Menu.language_menu(locale))
        elsif (Language.check_message(message.text, locale))
          locale = Language.check_message(message.text, locale)
          fb.locale(chat_id, locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.language.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.language.result.error', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        end  

      when 'new_1'
        if(message.text == I18n.t('menu.back', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.info', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
          fb.state.set(chat_id, 'vocabularies')
        elsif(message.text == I18n.t('menu.help', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.help', :locale => locale), reply_markup: Menu.language_menu(locale))
        else
          lang_id = Language.check_message(message.text, locale)
          if (lang_id)
            fb.temp.llang(chat_id, lang_id)
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.know', :locale => locale), reply_markup: Menu.language_menu(locale))
            fb.state.set(chat_id, 'new_2')
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.wrong', :locale => locale), reply_markup: Menu.language_menu(locale))
          end
        end

      when 'new_2'
        if(message.text == I18n.t('menu.back', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.info', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
          fb.state.set(chat_id, 'vocabularies')
        elsif(message.text == I18n.t('menu.help', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.help', :locale => locale), reply_markup: Menu.language_menu(locale))
        else
          llang = fb.temp.llang(chat_id)
          klang = Language.check_message(message.text, locale)
          if (!klang)
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.wrong', :locale => locale), reply_markup: Menu.language_menu(locale))
          elsif (llang == klang)
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.identical', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
            fb.temp.clear(chat_id)
            fb.state.set(chat_id, 'vocabularies')
          elsif (fb.vocs.id(chat_id, {llang: llang, klang: klang}) != nil)
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.exist', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
            fb.temp.clear(chat_id)
            fb.state.set(chat_id, 'vocabularies')
          else
            response = fb.vocs.create(chat_id, {llang: llang, klang: klang})
            fb.vocs.activate(chat_id, response.body["name"])
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.result.success', :locale => locale, llang: I18n.t('languages.names.' + llang.to_s, :locale => locale), klang: I18n.t('languages.names.' + klang.to_s, :locale => locale)), reply_markup: Menu.vocabularies_menu(locale))
            fb.temp.clear(chat_id)
            fb.state.set(chat_id, 'vocabularies')
          end
        end

      when 'notify'
        case(message.text)
        when I18n.t('menu.notify.never', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.none', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.stop(chat_id)
        when I18n.t('menu.notify.day', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 24)
        when I18n.t('menu.notify.day_two', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 48)
        when I18n.t('menu.notify.hour_one', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 1)
        when I18n.t('menu.notify.hour_two', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 2)
        when I18n.t('menu.notify.hour_four', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 4)
        when I18n.t('menu.notify.hour_six', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 6)
        when I18n.t('menu.notify.hour_twelve', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 12)
        when I18n.t('menu.notify.week', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set(chat_id, 168)
        when I18n.t('menu.back', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.info', :locale => locale), reply_markup: Menu.settings_menu(locale))
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.error', :locale => locale), reply_markup: Menu.settings_menu(locale))
        end
        fb.state.set(chat_id, 'settings')

      when 'repeat'
        case(message.text)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.repeat.help', :locale => locale), reply_markup: Menu.games_repeat_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.info', :locale => locale), reply_markup: Menu.games_menu(locale))
          fb.state.set(chat_id, 'games')
        else
          answer = fb.temp.game_answer(chat_id)
          score = fb.temp.game_score(chat_id)
          if(answer.find { |a| a == message.text })
            score += 1
            bot.api.send_message(chat_id: chat_id, text: I18n.t('games.repeat.result.success', :locale => locale, score: score), reply_markup: Menu.remove())
            fb.temp.game_score(chat_id, score)
            Command.repeat_game(bot, fb, current, chat_id, locale)
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('games.repeat.result.error', :locale => locale, score: score), reply_markup: Menu.games_menu(locale))
            fb.temp.clear(chat_id)
            fb.state.set(chat_id, 'games')
          end
        end

      when 'settings'
        case(message.text)
        when I18n.t('menu.settings.info', :locale => locale)     
          text = I18n.t('settings.summary.intro', :locale => locale)

          n = fb.notify.get(chat_id)
          if(n)
            period = Format.tick_every(n['tick'].to_i, locale)
            text += I18n.t('settings.summary.notify.positive', :locale => locale, period: period)
          else
            text += I18n.t('settings.summary.notify.negative', :locale => locale)
          end

          lang = I18n.t('languages.flags.' + locale.to_s, :locale => locale) + I18n.t('languages.names.' + locale.to_s, :locale => locale)
          text += I18n.t('settings.summary.language', :locale => locale, lang: lang)

          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.settings_menu(locale))
        when I18n.t('menu.settings.language', :locale => locale)
          Command.change_language(bot, fb, chat_id, locale)
        when I18n.t('menu.settings.notifications', :locale => locale)
          Command.change_notification_period(bot, fb, current, chat_id, locale)
        when I18n.t('menu.settings.sleep', :locale => locale) # todo
          bot.api.send_message(chat_id: chat_id, text: I18n.t('todo', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.help', :locale => locale), reply_markup: Menu.settings_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.settings_menu(locale))
        end

      when 'translate' # todo
        te = Translator.translate(message.text, current[:klang], current[:llang])
        bot.api.send_message(chat_id: chat_id, text: I18n.t('translate.translation', :locale => locale, translation: te["translationText"]), reply_markup: Menu.main_menu(locale))
        fb.state.set(chat_id, 'idle')

      when 'vocabularies'
        case(message.text)
        when I18n.t('menu.vocabularies.add', :locale => locale)
          Command.new_vocabulary(bot, fb, chat_id, locale)
        when I18n.t('menu.vocabularies.delete', :locale => locale)
          Command.delete_vocabulary(bot, fb, chat_id, locale)
        when I18n.t('menu.vocabularies.list', :locale => locale) # todo
          bot.api.send_message(chat_id: chat_id, text: I18n.t('todo', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        when I18n.t('menu.vocabularies.switch', :locale => locale)
          Command.switch_vocabulary(bot, fb, chat_id, locale)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.help', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
        end

      when 'add_1'
        fb.temp.word(chat_id, Format.word(current[:llang], message.text.downcase))
        te = Translator.translate(message.text.downcase, current[:klang], current[:llang])
        bot.api.send_message(chat_id: chat_id, text: I18n.t('words.new.translation', :locale => locale, possible_translation: te["translationText"]), reply_markup: Menu.remove())
        fb.state.set(chat_id, 'add_2')

      when 'add_2'
        fb.temp.translation(chat_id, Format.word(current[:llang], message.text.downcase))
        bot.api.send_message(chat_id: chat_id, text: I18n.t('words.new.more', :locale => locale), reply_markup: Menu.yesno(locale))
        fb.state.set(chat_id, 'add_3')

      when 'add_3'
        case message.text
        when I18n.t('answer.positive', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('words.new.translation', :locale => locale), reply_markup: Menu.remove())
          fb.state.set(chat_id, 'add_2')
        when I18n.t('answer.negative', :locale => locale)
          word = fb.temp.word(chat_id)
          translation = fb.temp.translation(chat_id)
          fb.vocs.words.add(chat_id, current[:id], { word: word, translation: translation, created_at: Time.now})
          bot.api.send_message(chat_id: chat_id, text: I18n.t('words.new.result.success', :locale => locale, word: word), reply_markup: Menu.words_menu(locale))
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'words')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('answer.wrong', :locale => locale), reply_markup: Menu.yesno(locale))
        end

      when 'voc_delete'
        if(message.text == I18n.t('menu.back', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('words.info', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
          fb.state.set(chat_id, 'vocabularies')
        else
          langs = message.text.split('-')
          if(langs[0] != nil && langs[1] != nil)
            voc_id = fb.vocs.id(chat_id, {llang: Language.check_message(langs[0], locale).to_s, klang: Language.check_message(langs[1], locale).to_s})
            if (voc_id)
              fb.vocs.delete(chat_id, voc_id)
              fb.vocs.activate(chat_id, fb.vocs.all(chat_id)[0][:id])
              bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.result.success', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
              fb.state.set(chat_id, 'vocabularies')
            else
              bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.result.error', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
              fb.state.set(chat_id, 'vocabularies')
            end
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.result.error', :locale => locale),  reply_markup: Menu.vocabularies_menu(locale))
            fb.state.set(chat_id, 'vocabularies')
          end
        end

      when 'voc_switch'
        if(message.text == I18n.t('menu.back', :locale => locale))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.info', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
          fb.state.set(chat_id, 'vocabularies')
        else
          langs = message.text.split('-')
          if(langs[0] != nil && langs[1] != nil)
            voc_id = fb.vocs.id(chat_id, {llang: Language.check_message(langs[0], locale).to_s, klang: Language.check_message(langs[1], locale).to_s})
            if (voc_id)
              fb.vocs.activate(chat_id, voc_id)
              bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.result.success', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
              fb.state.set(chat_id, 'vocabularies')
            else
              bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.result.error', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
              fb.state.set(chat_id, 'vocabularies')
            end
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.result.error', :locale => locale),  reply_markup: Menu.vocabularies_menu(locale))
            fb.state.set(chat_id, 'vocabularies')
          end
        end

      when 'words'
        case(message.text)
        when I18n.t('menu.words.add', :locale => locale)
          Command.new_word(bot, fb, chat_id, locale)
        when I18n.t('menu.words.list', :locale => locale) 
          Command.list_words(bot, fb, current, chat_id, locale)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('words.help', :locale => locale), reply_markup: Menu.words_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.words_menu(locale))
        end

      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.main_menu(locale))
      end
    end
  end
end


          # when 'word_1'
      #   answer = message.text.downcase
      #   if (fb.vocs.words.translation(chat_id, current[:id], fb.temp.cw_id(chat_id)).index(answer) != nil)
      #     bot.api.send_message(chat_id: chat_id, text: I18n.t('game.random.good', :locale => locale))
      #   else
      #     bot.api.send_message(chat_id: chat_id, text: I18n.t('game.random.bad', :locale => locale))
      #   end
      #   fb.temp.clear(chat_id)
      #   fb.state.set(chat_id, 'idle')

      # when 'translation_1'
      #   answer = message.text.downcase
      #   if (fb.vocs.words.get(chat_id, current[:id], fb.temp.cw_id(chat_id)) == answer)
      #     bot.api.send_message(chat_id: chat_id, text: I18n.t('game.random.good', :locale => locale))
      #   else
      #     bot.api.send_message(chat_id: chat_id, text: I18n.t('game.random.bad', :locale => locale))
      #   end
      #   fb.temp.clear(chat_id)
      #   fb.state.set(chat_id, 'idle')