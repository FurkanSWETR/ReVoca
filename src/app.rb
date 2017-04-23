require 'telegram/bot'
require 'aws-sdk'
require 'i18n'
require_relative 'fb'
require_relative 'options'
require_relative 'format'

I18n.load_path = Dir['src/config/en.yml', 'src/config/ru.yml']
I18n.config.available_locales = [:en, :ru]
I18n.backend.load_translations

token = ENV.fetch('BOT_TOKEN')
base_uri = ENV.fetch('FIREBASE_URL')

remove_kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
languageMenu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [[Language.eng, Language.rus], [Language.spa, Language.fra]], one_time_keyboard: true)
yes_no_menu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(YES NO)], one_time_keyboard: true)
tick_menu = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [%w(Hourly Daily), %w(Weekly Never)], one_time_keyboard: true)

def help_text(state, locale)
  case state
  when 'idle'
    I18n.t('help.idle', :locale => locale)
  when 'new_1', 'new_2'
    I18n.t('help.new', :locale => locale)
  when 'add_1', 'add_2', 'add_3'
    I18n.t('help.add', :locale => locale)
  when 'switch_1'
    I18n.t('help.switch', :locale => locale)
  when 'delete_1'
    I18n.t('help.delete', :locale => locale)
  when 'word_1'
    I18n.t('help.random.word', :locale => locale)
  when 'translation_1'
    I18n.t('help.random.translation', :locale => locale)
  when 'notify_1'
    I18n.t('help.notifications', :locale => locale)
  when 'language_1'
    I18n.t('help.language_change', :locale => locale)
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
        tick = n[:tick].to_i
        next_time = Time.parse(n[:next])

        if(next_time < Time.now)          
          next_time += (60*60)*tick until next_time > Time.now
          tfb.notify.set(chat_id, {next: next_time, tick: tick})

          current = tfb.vocs.get(chat_id, fb.vocs.active(chat_id))

          w = tfb.vocs.words.get(chat_id, current[:id])
          if (w)
            word = w[:word]
            translations = tfb.vocs.words.translation(chat_id, current[:id], w[:id])

            text = Language.name(current[:llang]).capitalize + ": " + word + "\n"
            text += Language.name(current[:klang]).capitalize + ": "
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
      bot.api.send_message(chat_id: chat_id, text: I18n.t('hello', :locale => locale))
      fb.state.set(chat_id, 'idle')

    when '/help'
      bot.api.send_message(chat_id: chat_id, text: help_text(fb.state.now(chat_id), locale))

    when '/admin'
      bot.api.send_message(chat_id: chat_id, text: thr.status.to_s != "" ? thr.status.to_s : "Unknown")

    when '/cancel'
      fb.state.set(chat_id, 'idle')

    when '/new_vocabulary'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.learn', :locale => locale), reply_markup: languageMenu)
      fb.state.set(chat_id, 'new_1')

    when '/switch_vocabulary'
      vocs = fb.vocs.all(chat_id)
      if (vocs && vocs.length > 1)
        vocs.map! { |v| Telegram::Bot::Types::KeyboardButton.new(text: Language.name(v[:llang]) + '-' + Language.name(v[:klang])) }
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: vocs)
        bot.api.send_message(chat_id: chat_id, text: I18n.t('switch_vocabulary.intro', :locale => locale), reply_markup: markup)
        fb.state.set(chat_id, 'switch_1')
      elsif vocs.length == 1
        bot.api.send_message(chat_id: chat_id, text: I18n.t('switch_vocabulary.one', :locale => locale))
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('switch_vocabulary.none', :locale => locale))
      end

    when '/delete_vocabulary'
      vocs = fb.vocs.all(chat_id)
      if (vocs && vocs.length > 1)
        vocs.map! { |v| Telegram::Bot::Types::KeyboardButton.new(text: Language.name(v[:llang]) + '-' + Language.name(v[:klang])) }
        markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: vocs)
        bot.api.send_message(chat_id: chat_id, text: I18n.t('delete_vocabulary.intro', :locale => locale), reply_markup: markup)
        fb.state.set(chat_id, 'delete_1')
      elsif vocs.length == 1
        bot.api.send_message(chat_id: chat_id, text: I18n.t('delete_vocabulary.one', :locale => locale))
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('delete_vocabulary.none', :locale => locale))
      end

    when '/add_word'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('add.word', :locale => locale))
      fb.state.set(chat_id, 'add_1')

    when '/random_word'
      w = fb.vocs.words.get(chat_id, current[:id])
      if(w)
        fb.temp.cw_id(chat_id, w[:id])
        bot.api.send_message(chat_id: chat_id, text: I18n.t('random.translate', :locale => locale, lang: Language.name(current[:klang]), word: w[:word]))
        fb.state.set(chat_id, 'word_1')
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('random.none', :locale => locale))
      end

    when '/random_translation'
      w = fb.vocs.words.translation(chat_id, current[:id])
      if(w)
        fb.temp.cw_id(chat_id, w[:id])
        bot.api.send_message(chat_id: chat_id, text: I18n.t('random.translate', :locale => locale, lang: Language.name(current[:llang]), word: w[:translation]))
        fb.state.set(chat_id, 'translation_1')
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('random.none', :locale => locale))
      end

    when '/translate_word'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('not_implemented', :locale => locale))

    when '/list_words'
      words = fb.vocs.words.all(chat_id, current[:id])
      text = words.map{ |w| "* " + w[:word] + " - " + w[:translation].join(', ')}.join("\n")
      bot.api.send_message(chat_id: chat_id, text: I18n.t('list', :locale => locale, num: words.length.to_s, llang: Language.name(current[:llang]), klang: Language.name(current[:klang]), words: text))

    when '/change_notification_settings'
      if(current)
        bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.intro', :locale => locale), reply_markup: tick_menu)
        fb.state.set(chat_id, 'notify_1')
      else
        bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.no_vocabulary', :locale => locale))
      end

    when '/change_language'
      bot.api.send_message(chat_id: chat_id, text: I18n.t('change_language.question', :locale => locale), reply_markup: languageMenu)
      fb.state.set(chat_id, 'language_1')

    else
      state = fb.state.now(chat_id)
      case state
      when 'new_1'
        lang_id = Language.check(message.text)
        if (lang_id)
          fb.temp.llang(chat_id, lang_id)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.know', :locale => locale), reply_markup: languageMenu)
          fb.state.set(chat_id, 'new_2')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.wrong', :locale => locale), reply_markup: languageMenu)
        end
        
      when 'new_2'
        llang = fb.temp.llang(chat_id)
        klang = Language.check(message.text)
        if (!klang)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.wrong', :locale => locale), reply_markup: languageMenu)
        elsif (llang == klang)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.identical', :locale => locale), reply_markup: remove_kb)
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        elsif (fb.vocs.id(chat_id, {llang: llang, klang: klang}) != nil)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.already_have', :locale => locale))
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        else
          response = fb.vocs.create(chat_id, {llang: llang, klang: klang})
          fb.vocs.activate(chat_id, response.body["name"])
          bot.api.send_message(chat_id: chat_id, text: I18n.t('new_vocabulary.created', :locale => locale, llang: Language.name(llang), klang: Language.name(klang)), reply_markup: remove_kb)
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        end

      when 'switch_1'
        langs = message.text.split('-')
        voc_id = fb.vocs.id(chat_id, {llang: Language.check(langs[0]), klang: Language.check(langs[1])})
        if (voc_id)
          fb.vocs.activate(chat_id, voc_id)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('switch_vocabulary.success', :locale => locale), reply_markup: remove_kb)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('switch_vocabulary.error', :locale => locale))
        end

      when 'delete_1'
        langs = message.text.split('-')
        voc_id = fb.vocs.id(chat_id, {llang: Language.check(langs[0]), klang: Language.check(langs[1])})
        if (voc_id)
          fb.vocs.delete(chat_id, voc_id)
          fb.vocs.activate(chat_id, fb.vocs.all(chat_id)[0][:id])
          bot.api.send_message(chat_id: chat_id, text: I18n.t('delete_vocabulary.success', :locale => locale), reply_markup: remove_kb)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('delete_vocabulary.error', :locale => locale))
        end

      when 'add_1'
        fb.temp.word(chat_id, Format.word(current[:llang], message.text.downcase))
        bot.api.send_message(chat_id: chat_id, text: I18n.t('add.translation', :locale => locale))
        fb.state.set(chat_id, 'add_2')

      when 'add_2'
        fb.temp.translation(chat_id, Format.word(current[:llang], message.text.downcase))
        bot.api.send_message(chat_id: chat_id, text: I18n.t('add.more.question', :locale => locale), reply_markup: yes_no_menu)
        fb.state.set(chat_id, 'add_3')

      when 'add_3'
        case message.text.upcase
        when 'YES'
          bot.api.send_message(chat_id: chat_id, text: I18n.t('add.more.positive', :locale => locale), reply_markup: remove_kb)
          fb.state.set(chat_id, 'add_2')
        when 'NO'
          word = fb.temp.word(chat_id)
          translation = fb.temp.translation(chat_id)
          fb.vocs.words.add(chat_id, current[:id], { word: word, translation: translation, created_at: Time.now})
          bot.api.send_message(chat_id: chat_id, text: I18n.t('add.more.negative', :locale => locale, word: word), reply_markup: remove_kb)
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('fail', :locale => locale))
        end

      when 'word_1'
        answer = message.text.downcase
        if (fb.vocs.words.translation(chat_id, current[:id], fb.temp.cw_id(chat_id)).index(answer) != nil)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('random.good', :locale => locale))
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('random.bad', :locale => locale))
        end
        fb.temp.clear(chat_id)
        fb.state.set(chat_id, 'idle')

      when 'translation_1'
        answer = message.text.downcase
        if (fb.vocs.words.get(chat_id, current[:id], fb.temp.cw_id(chat_id)) == answer)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('random.good', :locale => locale))
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('random.bad', :locale => locale))
        end
        fb.temp.clear(chat_id)
        fb.state.set(chat_id, 'idle')

      when 'notify_1'
        case message.text.downcase
        when 'never'
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.none', :locale => locale), reply_markup: remove_kb)
          fb.notify.stop(chat_id)
          fb.state.set(chat_id, 'idle')
        when 'hourly'
          fb.temp.tick(chat_id, 1)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.selected_period', :locale => locale, period: message.text[0..-3].downcase), reply_markup: remove_kb)
          fb.state.set(chat_id, 'notify_2')
        when 'daily'
          fb.temp.tick(chat_id, 24)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.selected_period', :locale => locale, period: message.text[0..-3].downcase), reply_markup: remove_kb)
          fb.state.set(chat_id, 'notify_2')
        when 'weekly'
          fb.temp.tick(chat_id, 168)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.selected_period', :locale => locale, period: message.text[0..-3].downcase), reply_markup: remove_kb)
          fb.state.set(chat_id, 'notify_2')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('fail', :locale => locale))
        end

      when 'notify_2'
        n = Integer(message.text) rescue nil
        if (n && n.between?(1, 30))
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.success', :locale => locale))
          hours = n * fb.temp.tick(chat_id)
          t = Time.now
          t = Time.new(t.year, t.month, t.day, t.hour) + (60*60*hours)
          fb.notify.set(chat_id, {next: t, tick: hours})
          fb.temp.clear(chat_id)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('notification.error', :locale => locale))
        end

      when 'language_1'
        lang_id = Language.check(message.text)
        if (lang_id)
          case lang_id
          when 'ENG' 
            Language.i = 0
            locale = :en
          when 'RUS' 
            Language.i = 1
            locale = :ru
          when 'SPA' 
            Language.i = 2
            locale = :en
          when 'FRA' 
            Language.i = 3
            locale = :en
          else 
            Language.i = 0
            locale = :en
          end
          fb.locale(chat_id, locale)
          bot.api.send_message(chat_id: chat_id, text: I18n.t('change_language.success', :locale => locale), reply_markup: remove_kb)
          fb.state.set(chat_id, 'idle')
        else
          bot.api.send_message(chat_id: chat_id, text: I18n.t('change_language.error', :locale => locale), reply_markup: languageMenu)
        end

      when 'idle'
        bot.api.send_message(chat_id: chat_id, text: I18n.t('not_a_comand', :locale => locale))
      end
    end
  end



end
