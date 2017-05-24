require 'i18n'
require_relative 'menu'

class Command

	def self.change_language(bot, fb, chat_id, locale)
		bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.language.choice', :locale => locale), reply_markup: Menu.language_menu(locale))
		fb.state.set(chat_id, 'language')
	end

	def self.change_notification_period(bot, fb, current, chat_id, locale)
		if(current)
			bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.info', :locale => locale), reply_markup: Menu.notify_menu(locale))
			fb.state.set(chat_id, 'notify')
		else
			bot.api.send_message(chat_id: chat_id, text: I18n.t('settings.notify.no_vocabulary', :locale => locale), reply_markup: Menu.settings_menu(locale))
		end
	end

	def self.select_game(bot, fb, current, chat_id, locale)
		words = fb.vocs.words.all(chat_id, current[:id])
		if(words.length > 3)
			selected = (0...words.length).to_a.shuffle.take(4)
			lang = I18n.t('languages.flags.' + current[:llang], :locale => locale) + I18n.t('languages.names.' + current[:llang], :locale => locale)
			
			i = selected.slice!(0)
			word = words[i][:word]
			answer = words[i][:translation].shuffle.first
			answers = [answer]
			fb.temp.game_answer(chat_id, [answer])

			selected.each{|s| answers.push(words[s][:translation].shuffle.first)}

			bot.api.send_message(chat_id: chat_id, text: I18n.t('games.select.question', :locale => locale, lang: lang, word: word), reply_markup: Menu.games_select_menu(locale, answers.shuffle))
			fb.state.set(chat_id, 'select')
		else
			bot.api.send_message(chat_id: chat_id, text: I18n.t('game.select.not_enough', :locale => locale), reply_markup: Menu.games_menu(locale))
		end
	end

	def self.repeat_game(bot, fb, current, chat_id, locale)
		word = fb.vocs.words.get(chat_id, current[:id])[1]
		if(word)
			if([true, false].sample)
				fb.temp.game_answer(chat_id, word['translation'].to_a)
				lang = I18n.t('languages.flags.' + current[:llang], :locale => locale) + I18n.t('languages.names.' + current[:llang], :locale => locale)
				bot.api.send_message(chat_id: chat_id, text: I18n.t('games.repeat.question', :locale => locale, lang: lang, word: word['word']), reply_markup: Menu.games_repeat_menu(locale))
			else
				fb.temp.game_answer(chat_id, [word['word']])
				lang = I18n.t('languages.flags.' + current[:klang], :locale => locale) + I18n.t('languages.names.' + current[:klang], :locale => locale)
				bot.api.send_message(chat_id: chat_id, text: I18n.t('games.repeat.question', :locale => locale, lang: lang, word: word['translation'].to_a.join(', ')), reply_markup: Menu.games_repeat_menu(locale))
			end
			fb.state.set(chat_id, 'repeat')
		else
			bot.api.send_message(chat_id: chat_id, text: I18n.t('game.repeat.none', :locale => locale), reply_markup: Menu.games_menu(locale))
		end
	end

	def self.translate(bot, fb, chat_id, locale)
		bot.api.send_message(chat_id: chat_id, text: I18n.t('translate.word', :locale => locale), reply_markup: Menu.remove())
		fb.state.set(chat_id, 'translate')
	end

	# vocabularies

	def self.delete_vocabulary(bot, fb, chat_id, locale)
		vocs = fb.vocs.all(chat_id)
		if (vocs && vocs.length > 1)
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.list', :locale => locale), reply_markup: Menu.vocabulary_list_menu(vocs, locale))
			fb.state.set(chat_id, 'voc_delete')
		elsif vocs.length == 1
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.one', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
		else
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.delete.none', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
		end
	end

	def self.new_vocabulary(bot, fb, chat_id, locale)
		bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.new.learn', :locale => locale), reply_markup: Menu.language_menu(locale))
		fb.state.set(chat_id, 'new_1')
	end

	def self.switch_vocabulary(bot, fb, chat_id, locale)
		vocs = fb.vocs.all(chat_id)
		if (vocs && vocs.length > 1)
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.list', :locale => locale), reply_markup: Menu.vocabulary_list_menu(vocs, locale))
			fb.state.set(chat_id, 'voc_switch')
		elsif vocs.length == 1
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.one', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
		else
			bot.api.send_message(chat_id: chat_id, text: I18n.t('vocabularies.switch.none', :locale => locale), reply_markup: Menu.vocabularies_menu(locale))
		end
	end

	def self.list_words(bot, fb, current, chat_id, locale)
		words = fb.vocs.words.all(chat_id, current[:id])
		text = words.map{ |w| "* " + w[:word] + " - " + w[:translation].join(', ')}.join("\n")
		bot.api.send_message(chat_id: chat_id, text: I18n.t('words.list', :locale => locale, num: words.length.to_s, llang: I18n.t('languages.names.' + current[:llang], :locale => locale), klang: I18n.t('languages.names.' + current[:klang], :locale => locale), words: text), reply_markup: Menu.words_menu(locale))
	end

	def self.new_word(bot, fb, chat_id, locale)
		bot.api.send_message(chat_id: chat_id, text: I18n.t('words.new.word', :locale => locale), reply_markup: Menu.remove())
		fb.state.set(chat_id, 'add_1')
	end

end

