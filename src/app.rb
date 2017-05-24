require 'telegram/bot'
require 'aws-sdk'
require 'i18n'

require_relative 'notifier'

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
  when 'select'
    { text: I18n.t('games.select.help', :locale => locale) }
  when 'sleep_daytime'
    { text: I18n.t('settings.sleep.help', :locale => locale), reply_markup: Menu.daytime_menu(locale) }
  when 'sleep_hours'
    { text: I18n.t('settings.sleep.help', :locale => locale) }
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

  n = Notifier.new
  n.start(bot)

  fb = FB.new(base_uri)

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

    when '/save'
      word = fb.temp.translated(chat_id)
      if (word)
        fb.vocs.words.add(chat_id, current[:id], { word: word['word'], translation: word['translation'], created_at: Time.now})
        bot.api.send_message(chat_id: chat_id, text: I18n.t('translate.save.result.success', :locale => locale, word: word['word']), reply_markup: Menu.main_menu(locale))
        fb.temp.clear(chat_id)
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('translate.save.none', :locale => locale), reply_markup: Menu.main_menu(locale))
      end
      fb.state.set(chat_id, 'idle')

    else
      state = fb.state.now(chat_id)
      case state     

      when 'games'
        case(message.text)
        when I18n.t('menu.games.guess', :locale => locale)
          fb.temp.game_score(chat_id, 0)
          Command.select_game(bot, fb, current, chat_id, locale)
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
          fb.notify.set_tick(chat_id, 24)
        when I18n.t('menu.notify.day_two', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 48)
        when I18n.t('menu.notify.hour_one', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 1)
        when I18n.t('menu.notify.hour_two', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 2)
        when I18n.t('menu.notify.hour_four', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 4)
        when I18n.t('menu.notify.hour_six', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 6)
        when I18n.t('menu.notify.hour_twelve', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 12)
        when I18n.t('menu.notify.week', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.notify.set_tick(chat_id, 168)
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

      when 'select'
        case(message.text)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.select.help', :locale => locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('games.info', :locale => locale), reply_markup: Menu.games_menu(locale))
          fb.state.set(chat_id, 'games')
        else
          answer = fb.temp.game_answer(chat_id)
          score = fb.temp.game_score(chat_id)
          if(answer.find { |a| a == message.text })
            score += 1
            bot.api.send_message(chat_id: chat_id, text: I18n.t('games.select.result.success', :locale => locale, score: score), reply_markup: Menu.remove())
            fb.temp.game_score(chat_id, score)
            Command.select_game(bot, fb, current, chat_id, locale)
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('games.select.result.error', :locale => locale, score: score), reply_markup: Menu.games_menu(locale))
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

          sleep_hours = fb.notify.sleep_hours(chat_id)
          if(sleep_hours)
            text += I18n.t('settings.summary.sleep', :locale => locale, hour_start: sleep_hours['start'], hour_end: sleep_hours['end'])
          end

          lang = I18n.t('languages.flags.' + locale.to_s, :locale => locale) + I18n.t('languages.names.' + locale.to_s, :locale => locale)
          text += I18n.t('settings.summary.language', :locale => locale, lang: lang)

          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.settings_menu(locale))
        when I18n.t('menu.settings.language', :locale => locale)
          Command.change_language(bot, fb, chat_id, locale)
        when I18n.t('menu.settings.notifications', :locale => locale)
          Command.change_notification_period(bot, fb, current, chat_id, locale)
        when I18n.t('menu.settings.sleep', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.sleep.start.daytime', :locale => locale), reply_markup: Menu.daytime_menu(locale))
          fb.state.set(chat_id, 'sleep_daytime')
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.help', :locale => locale), reply_markup: Menu.settings_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('main.info', :locale => locale), reply_markup: Menu.main_menu(locale))
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.settings_menu(locale))
        end

      when 'sleep_daytime'
        text = fb.temp.sleep_exist(chat_id) ? I18n.t('settings.sleep.end.hour', :locale => locale) : I18n.t('settings.sleep.start.hour', :locale => locale)
        case(message.text)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.sleep.help', :locale => locale), reply_markup: Menu.daytime_menu(locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.info', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        when I18n.t('menu.daytime.night', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.time_1_menu(locale))
          fb.state.set(chat_id, 'sleep_hours')
        when I18n.t('menu.daytime.morning', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.time_2_menu(locale))
          fb.state.set(chat_id, 'sleep_hours')
        when I18n.t('menu.daytime.day', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.time_1_menu(locale, 12))
          fb.state.set(chat_id, 'sleep_hours')
        when I18n.t('menu.daytime.evening', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: text, reply_markup: Menu.time_2_menu(locale, 12))
          fb.state.set(chat_id, 'sleep_hours')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale), reply_markup: Menu.daytime_menu(locale))
        end

      when 'sleep_hours'
        case(message.text)
        when I18n.t('menu.help', :locale => locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.sleep.help', :locale => locale))
        when I18n.t('menu.back', :locale => locale) 
          bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.info', :locale => locale), reply_markup: Menu.settings_menu(locale))
          fb.state.set(chat_id, 'settings')
        else
          i = /.((\d|\d{2}):00)/ =~ message.text
          if (i)
            if(fb.temp.sleep_exist(chat_id))
              fb.notify.sleep_hours(chat_id, {start: fb.temp.sleep_start(chat_id), end: message.text[/(\d{2}|\d)/].to_i})
              bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.sleep.result.success', :locale => locale), reply_markup: Menu.settings_menu(locale))
              fb.state.set(chat_id, 'settings')
              fb.temp.clear(chat_id)
            else
              bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.sleep.end.daytime', :locale => locale), reply_markup: Menu.daytime_menu(locale))
              fb.temp.sleep_start(chat_id, message.text[/(\d{2}|\d)/])
              fb.state.set(chat_id, 'sleep_daytime')
            end
          else
            bot.api.send_message(chat_id: chat_id, text: I18n.t('unknown', :locale => locale))
          end
        end

      when 'translate'
        te = Translator.translate(message.text, current[:klang], current[:llang])
        translations = te["translationText"].split(" ").map { |t| t.downcase }
        bot.api.send_message(chat_id: chat_id, text: I18n.t('translate.translation', :locale => locale, translation: translations.join(", ")), reply_markup: Menu.main_menu(locale))
        fb.temp.translated(chat_id, {word: message.text, translation: translations})
        fb.state.set(chat_id, 'idle')

      when 'vocabularies'
        case(message.text)
        when I18n.t('menu.vocabularies.add', :locale => locale)
          Command.new_vocabulary(bot, fb, chat_id, locale)
        when I18n.t('menu.vocabularies.delete', :locale => locale)
          Command.delete_vocabulary(bot, fb, chat_id, locale)
        when I18n.t('menu.vocabularies.list', :locale => locale) 
          vocs = fb.vocs.all(chat_id).map do |v|
            v_name = I18n.t('languages.flags.' + v[:llang], :locale => locale) + I18n.t('languages.names.' + v[:llang], :locale => locale) + " - " + I18n.t('languages.flags.' + v[:klang], :locale => locale) + I18n.t('languages.names.' + v[:klang], :locale => locale)
            v_count = fb.vocs.words.all(chat_id, v[:id]).length.to_s
            I18n.t('vocabularies.list.voc', :locale => locale, name: v_name, count: v_count)
          end
          bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.list.main', :locale => locale, num: vocs.length.to_s, vocs: vocs.join("\n")), reply_markup: Menu.vocabularies_menu(locale))
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