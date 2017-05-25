require 'i18n'

require_relative 'format'
require_relative 'language'
require_relative 'menu'
require_relative 'translate'

FULL_HOUR_REGEX = /.((\d|\d{2}):00)/
HOUR_REGEX = /(\d{2}|\d)/

class Response
	@chat_id
	@fb
	@locale
	@message
	@voc

	def initialize(fb, message)
		@chat_id = message.chat.id.to_s
		@fb = fb
		@locale = @fb.locale(@chat_id)
		@message = message

		voc_id = @fb.vocs.active(@chat_id)
		@voc =  voc_id ? @fb.vocs.get(@chat_id, voc_id) : nil
	end

	def cancel()
		@fb.state.set(@chat_id, 'idle')
		return { text: I18n.t('main.info', :locale => @locale), markup: Menu.main_menu(@locale) }      
	end

	def creator()
		return { text: I18n.t('creator', :locale => @locale), markup: nil }      
	end

	def error()
		@fb.state.set(@chat_id, 'idle')
		return { text: I18n.t('error', :locale => @locale), markup: Menu.main_menu(@locale) }      
	end

	def games()
		case(@message.text)
		when I18n.t('menu.games.select', :locale => @locale)
			@fb.temp.game_score(@chat_id, 0)
			return play_select_question()
		when I18n.t('menu.games.translate', :locale => @locale)
			@fb.temp.game_score(@chat_id, 0)
			return play_translate_question()
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('games.help', :locale => @locale), markup: Menu.games_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale) 
			@fb.state.set(@chat_id, 'idle')
			return { text: I18n.t('main.info', :locale => @locale), markup: Menu.main_menu(@locale) }
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.games_menu(@locale) }
		end
	end
	
	def help()
		case @fb.state.now(@chat_id)
		when 'games'
			{ text: I18n.t('games.help', :locale => @locale), markup: Menu.games_menu(@locale) }
		when 'games_select'
			{ text: I18n.t('games.select.help', :locale => @locale), markup: nil }
		when 'games_translate'
			{ text: I18n.t('games.translate.help', :locale => @locale), markup: Menu.games_translate_menu(@locale) }
		when 'idle'
			{ text: I18n.t('main.help', :locale => @locale), markup: Menu.main_menu(@locale) }
		when 'settings'
			{ text: I18n.t('settings.help', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when 'settings_language'
			{ text: I18n.t('settings.language.help', :locale => @locale), markup: Menu.language_menu(@locale) } 
		when 'settings_notify'
			{ text: I18n.t('settings.notify.help', :locale => @locale), markup: Menu.notify_menu(@locale) } 
		when 'settings_sleep_daytime'
			{ text: I18n.t('settings.sleep.help', :locale => @locale), markup: Menu.daytime_menu(@locale) }
		when 'settings_sleep_hours'
			{ text: I18n.t('settings.sleep.help', :locale => @locale), markup: nil }
		when 'vocabularies'
			{ text: I18n.t('vocabularies.help', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		when 'voc_delete'
			{ text: I18n.t('vocabularies.delete.help', :locale => @locale), markup: nil }
		when 'voc_new_klang', 'voc_new_llang'
			{ text: I18n.t('vocabularies.new.help', :locale => @locale), markup: Menu.language_menu(@locale) }
		when 'voc_switch'
			{ text: I18n.t('vocabularies.switch.help', :locale => @locale), markup: nil }
		when 'words', 'word_add_word', 'word_add_translation', 'word_add_question'
			{ text: I18n.t('words.help', :locale => @locale), markup: Menu.words_menu(@locale) }
		when 'word_translate'
			{ text: I18n.t('translate.help', :locale => @locale), markup: nil }
		else
			{ text: I18n.t('help.unknown', :locale => @locale), markup: nil }
		end
	end

	def idle()
		case(@message.text)
		when I18n.t('menu.main.games', :locale => @locale)
			@fb.state.set(@chat_id, 'games')
			return { text: I18n.t('games.info', :locale => @locale), markup: Menu.games_menu(@locale) }
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('main.help', :locale => @locale), markup: Menu.main_menu(@locale) }   
		when I18n.t('menu.main.settings', :locale => @locale)
			@fb.state.set(@chat_id, 'settings')
			return { text: I18n.t('settings.info', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.main.translate', :locale => @locale)
			return word_translate_question()
		when I18n.t('menu.main.vocabulary', :locale => @locale)
			@fb.state.set(@chat_id, 'vocabularies')
			return { text: I18n.t('vocabularies.info', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }	
		when I18n.t('menu.main.word', :locale => @locale)
			@fb.state.set(@chat_id, 'words')
			return { text: I18n.t('words.info', :locale => @locale), markup: Menu.words_menu(@locale) }		
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.main_menu(@locale) }
		end
	end
	
	def play_select_answer()
		case(@message.text)
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('games.select.help', :locale => @locale), markup: nil }
		when I18n.t('menu.back', :locale => @locale) 
			@fb.state.set(@chat_id, 'games')
			return { text: I18n.t('games.info', :locale => @locale), markup: Menu.games_menu(@locale) }
		else
			answer = @fb.temp.game_answer(@chat_id)
			score = @fb.temp.game_score(@chat_id)
			if(answer.find { |a| a == @message.text.downcase })
				score += 1			
				@fb.temp.game_score(@chat_id, score)
				play_select_question(I18n.t('games.select.result.success', :locale => @locale, score: score))
			else
				@fb.temp.clear(@chat_id)
				@fb.state.set(@chat_id, 'games')
				return { text: I18n.t('games.select.result.error', :locale => @locale, score: score), markup: Menu.games_menu(@locale) }
			end
		end
	end
	
	def play_select_question(stats = nil)
		words = @fb.vocs.words.all(@chat_id, @voc[:id])
		if(words.length > 3)
			words = words.shuffle.take(4)
			word = words.first[:word]
			answers = words.map { |w| w[:translation].shuffle.first }
			@fb.temp.game_answer(@chat_id, [answers.first])
			@fb.state.set(@chat_id, 'games_select')
			lang = I18n.t('languages.flags.' + @voc[:klang], :locale => @locale) + I18n.t('languages.names.' + @voc[:klang], :locale => @locale)
			return { text: I18n.t('games.select.question', :locale => @locale, lang: lang, stats: stats, word: word), markup: Menu.games_select_menu(@locale, answers.shuffle) }			
		else
			return { text: I18n.t('game.select.not_enough', :locale => @locale), markup: Menu.games_menu(@locale) }
		end
	end

	def play_translate_answer()
		case(@message.text)
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('games.translate.help', :locale => @locale), markup: Menu.games_translate_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale) 
			@fb.state.set(@chat_id, 'games')
			return { text: I18n.t('games.info', :locale => @locale), markup: Menu.games_menu(@locale) }
		else
			answer = @fb.temp.game_answer(@chat_id)
			score = @fb.temp.game_score(@chat_id)
			if(answer.find { |a| a == @message.text.downcase })
				score += 1
				@fb.temp.game_score(@chat_id, score)
				return play_translate_question(I18n.t('games.translate.result.success', :locale => @locale, score: score))
			else
				@fb.temp.clear(@chat_id)
				@fb.state.set(@chat_id, 'games')
				return { text: I18n.t('games.translate.result.error', :locale => @locale, score: score), markup: Menu.games_menu(@locale) }
			end
		end
	end

	def play_translate_question(stats = nil)
		word = @fb.vocs.words.random(@chat_id, @voc[:id])
		if(word)
			to_klang = [true, false].sample
			@fb.temp.game_answer(@chat_id, to_klang ? word[:translation] : [word[:word]])
			lang = to_klang ? @voc[:klang] : @voc[:llang]
			lang_text = I18n.t('languages.flags.' + lang, :locale => @locale) + I18n.t('languages.names.' + lang, :locale => @locale)
			word = to_klang ? word[:word] : word[:translation].join(', ')
			@fb.state.set(@chat_id, 'games_translate')
			return { text: I18n.t('games.translate.question', :locale => @locale, lang: lang_text, stats: stats, word: word), markup: Menu.games_translate_menu(@locale) }
		else
			return { text: I18n.t('game.repeat.none', :locale => @locale), markup: Menu.games_menu(@locale) }
		end
	end

	def save()
		@fb.state.set(@chat_id, 'idle')
		word = @fb.temp.translated(@chat_id)
		if (word)
			@fb.vocs.words.add(@chat_id, @voc[:id], { word: word['word'], translation: word['translation'], created_at: Time.now})
			@fb.temp.clear(@chat_id)
			return { text: I18n.t('translate.save.result.success', :locale => @locale, word: word['word']), markup: Menu.main_menu(@locale) }
		else
			return { text: I18n.t('translate.save.none', :locale => @locale), markup: Menu.main_menu(@locale) }
		end	
	end

	def settings()
		case(@message.text)
		when I18n.t('menu.settings.info', :locale => @locale)     
			text = I18n.t('settings.summary.intro', :locale => @locale)
			n = @fb.notify.get(@chat_id)
			if(n)
				tick = Format.tick_every(n['tick'].to_i, @locale)
				text += I18n.t('settings.summary.notify.positive', :locale => @locale, tick: tick)
			else
				text += I18n.t('settings.summary.notify.negative', :locale => @locale)
			end
			sleep_hours = @fb.notify.sleep_hours(@chat_id)
			if(sleep_hours)
				text += I18n.t('settings.summary.sleep', :locale => @locale, hour_start: sleep_hours[:start], hour_end: sleep_hours[:end])
			end
			lang = I18n.t('languages.flags.' + @locale.to_s, :locale => @locale) + I18n.t('languages.names.' + @locale.to_s, :locale => @locale)
			text += I18n.t('settings.summary.language', :locale => @locale, lang: lang)
			return { text: text, markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.settings.language', :locale => @locale)
			return settings_language_question()
		when I18n.t('menu.settings.notifications', :locale => @locale)
			return settings_notification_question()
		when I18n.t('menu.settings.sleep', :locale => @locale)
			return settings_sleep()
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('settings.help', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale) 
			@fb.state.set(@chat_id, 'idle')
			return { text: I18n.t('main.info', :locale => @locale), markup: Menu.main_menu(@locale) }		
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.settings_menu(@locale) }
		end
	end

	def settings_language_answer()
		if(@message.text == I18n.t('menu.back', :locale => @locale))
			@fb.state.set(chat_id, 'settings')
			return { text: I18n.t('settings.info', :locale => @locale), markup: Menu.settings_menu(@locale) }
		elsif(@message.text == I18n.t('menu.help', :locale => @locale))
			return { text: I18n.t('settings.language.help', :locale => @locale), markup: Menu.language_menu(@locale) }
		elsif (Language.check_message(@message.text, @locale))
			locale = Language.check_message(@message.text, @locale)
			@fb.locale(@chat_id, locale)
			@fb.state.set(@chat_id, 'settings')
			return { text: I18n.t('settings.language.result.success', :locale => locale), markup: Menu.settings_menu(locale) }	
		else
			@fb.state.set(@chat_id, 'settings')
			return { text: I18n.t('settings.language.result.error', :locale => @locale), markup: Menu.settings_menu(@locale) }
		end
	end

	def settings_language_question()
		@fb.state.set(@chat_id, 'settings_language')
		return { text: I18n.t('settings.language.choice', :locale => @locale), markup: Menu.language_menu(@locale) }
	end

	def settings_notification_answer()
		@fb.state.set(@chat_id, 'settings')
		case(@message.text)
		when I18n.t('menu.notify.never', :locale => @locale)
			@fb.notify.stop(@chat_id)
			return { text: I18n.t('settings.notify.none', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.day', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 24)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.day_two', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 48)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.hour_one', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 1)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }		
		when I18n.t('menu.notify.hour_two', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 2)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.hour_four', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 4)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.hour_six', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 6)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.hour_twelve', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 12)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.notify.week', :locale => @locale)
			@fb.notify.set_tick(@chat_id, 168)
			return { text: I18n.t('settings.notify.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }			
		when I18n.t('menu.back', :locale => @locale)
			return { text: I18n.t('settings.info', :locale => @locale), markup: Menu.settings_menu(@locale) }
		else
			return { text: I18n.t('settings.notify.result.error', :locale => @locale), markup: Menu.settings_menu(@locale) }
		end
	end

	def settings_notification_question()
		if(@voc)
			@fb.state.set(@chat_id, 'settings_notify')
			return { text: I18n.t('settings.notify.info', :locale => @locale), markup: Menu.notify_menu(@locale) }
		else
			return { text: I18n.t('settings.notify.no_vocabulary', :locale => @locale), markup: Menu.settings_menu(@locale) }
		end
	end

	def settings_sleep()
		@fb.state.set(@chat_id, 'settings_sleep_daytime')
		return { text: I18n.t('settings.sleep.start.daytime', :locale => @locale), markup: Menu.daytime_menu(@locale) }	
	end

	def settings_sleep_daytime()
		text = @fb.temp.sleep_exist(@chat_id) ? I18n.t('settings.sleep.end.hour', :locale => @locale) : I18n.t('settings.sleep.start.hour', :locale => @locale)
		case(@message.text)
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('settings.sleep.help', :locale => @locale), markup: Menu.daytime_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale)
			@fb.state.set(@chat_id, 'settings')
			return { text: I18n.t('settings.info', :locale => @locale), markup: Menu.settings_menu(@locale) }
		when I18n.t('menu.daytime.night', :locale => @locale)
			@fb.state.set(@chat_id, 'settings_sleep_hours')
			return { text: text, markup: Menu.time_1_menu(@locale) }
		when I18n.t('menu.daytime.morning', :locale => @locale)
			@fb.state.set(@chat_id, 'settings_sleep_hours')
			return { text: text, markup: Menu.time_2_menu(@locale) }
		when I18n.t('menu.daytime.day', :locale => @locale)
			@fb.state.set(@chat_id, 'settings_sleep_hours')
			return { text: text, markup: Menu.time_1_menu(@locale, 12) }
		when I18n.t('menu.daytime.evening', :locale => @locale)
			@fb.state.set(@chat_id, 'settings_sleep_hours')
			return { text: text, markup: Menu.time_2_menu(@locale, 12) }		
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.daytime_menu(@locale) }
		end
	end

	def settings_sleep_hours()
		case(@message.text)
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('settings.sleep.help', :locale => @locale), markup: nil }
		when I18n.t('menu.back', :locale => @locale)
			@fb.state.set(@chat_id, 'settings')
			return { text: I18n.t('settings.info', :locale => @locale), markup: Menu.settings_menu(@locale) }
		else
			i = FULL_HOUR_REGEX =~ @message.text
			if (i)
				if(@fb.temp.sleep_exist(@chat_id))
					@fb.notify.sleep_hours(@chat_id, { start: @fb.temp.sleep_start(@chat_id), end: @message.text[/(\d{2}|\d)/].to_i })
					@fb.state.set(@chat_id, 'settings')
					@fb.temp.clear(@chat_id)
					return { text: I18n.t('settings.sleep.result.success', :locale => @locale), markup: Menu.settings_menu(@locale) }				
				else
					@fb.temp.sleep_start(@chat_id, @message.text[HOUR_REGEX])
					@fb.state.set(@chat_id, 'settings_sleep_daytime')
					return { text: I18n.t('settings.sleep.end.daytime', :locale => @locale), markup: Menu.daytime_menu(@locale) }		
				end
			else
				return { text: I18n.t('unknown', :locale => @locale), markup: nil }
			end
		end
	end

	def start()
		@fb.state.set(@chat_id, 'idle')
		return { text: I18n.t('hello', :locale => @locale),	markup: Menu.main_menu(@locale)	}
	end

	def unknown()
		return { text: I18n.t('unknown', :locale => @locale), markup: Menu.main_menu(@locale) }
	end

	def vocabularies
		case(@message.text)
		when I18n.t('menu.vocabularies.add', :locale => @locale)
			return vocabulary_new()
		when I18n.t('menu.vocabularies.delete', :locale => @locale)
			return vocabulary_delete_question()
		when I18n.t('menu.vocabularies.list', :locale => @locale) 
			return vocabulary_list()
		when I18n.t('menu.vocabularies.switch', :locale => @locale)
			return vocabulary_switch_question()
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('vocabularies.help', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale)
			@fb.state.set(@chat_id, 'idle')
			return { text: I18n.t('main.info', :locale => @locale), markup: Menu.main_menu(@locale) }
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		end
	end

	def vocabulary_delete_answer()
		@fb.state.set(@chat_id, 'vocabularies')
		if(@message.text == I18n.t('menu.back', :locale => @locale))
			return { text: I18n.t('words.info', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		else
			langs = @message.text.split('-')
			if(langs[0] != nil && langs[1] != nil)
				voc_id = @fb.vocs.id(@chat_id, { llang: Language.check_message(langs[0], @locale), klang: Language.check_message(langs[1], @locale) })
				if (voc_id)
					@fb.vocs.delete(@chat_id, voc_id)
					@fb.vocs.activate(@chat_id, @fb.vocs.all(@chat_id).first[:id])
					return { text: I18n.t('vocabularies.delete.result.success', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
				end
			end
			return { text: I18n.t('vocabularies.delete.result.error', :locale => locale),  markup: Menu.vocabularies_menu(@locale) }			
		end
	end

	def vocabulary_delete_question()
		vocs = @fb.vocs.all(@chat_id)
		if (vocs && vocs.length > 1)
			@fb.state.set(@chat_id, 'voc_delete')
			return { text: I18n.t('vocabularies.delete.list', :locale => @locale), markup: Menu.vocabulary_list_menu(vocs, @locale) }
		elsif vocs.length == 1
			return { text: I18n.t('vocabularies.delete.one', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		else
			return { text: I18n.t('vocabularies.delete.none', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		end
	end

	def vocabulary_list()
		vocs = @fb.vocs.all(@chat_id).map do |v|
			v_name = I18n.t('languages.flags.' + v[:llang], :locale => @locale) + I18n.t('languages.names.' + v[:llang], :locale => @locale) + " - " + I18n.t('languages.flags.' + v[:klang], :locale => @locale) + I18n.t('languages.names.' + v[:klang], :locale => @locale)
			v_count = @fb.vocs.words.all(@chat_id, v[:id]).length.to_s
			I18n.t('vocabularies.list.voc', :locale => @locale, name: v_name, count: v_count)
		end
		return { text: I18n.t('vocabularies.list.main', :locale => @locale, num: vocs.length.to_s, vocs: vocs.join("\n")), markup: Menu.vocabularies_menu(@locale) }
	end

	def vocabulary_new()
		@fb.state.set(@chat_id, 'voc_new_llang')
		return { text: I18n.t('vocabularies.new.learn', :locale => @locale), markup: Menu.language_menu(@locale) }	
	end

	def vocabulary_new_klang()
		if(@message.text == I18n.t('menu.back', :locale => @locale))
			@fb.state.set(@chat_id, 'vocabularies')
			return { text: I18n.t('vocabularies.info', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		elsif(@message.text == I18n.t('menu.help', :locale => @locale))
			return { text: I18n.t('vocabularies.new.help', :locale => @locale), markup: Menu.language_menu(@locale) }
		else
			llang = @fb.temp.llang(@chat_id)
			klang = Language.check_message(@message.text, @locale)
			if (!klang)
				return { text: I18n.t('vocabularies.new.wrong', :locale => @locale), markup: Menu.language_menu(@locale) }
			else
				if (llang == klang)
					res = { text: I18n.t('vocabularies.new.identical', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
				elsif (@fb.vocs.id(@chat_id, {llang: llang, klang: klang}) != nil)
					res = { text: I18n.t('vocabularies.new.exist', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
				else
					response = @fb.vocs.create(@chat_id, {llang: llang, klang: klang})
					@fb.vocs.activate(@chat_id, response.body["name"])
					res = { text: I18n.t('vocabularies.new.result.success', :locale => @locale, llang: I18n.t('languages.names.' + llang, :locale => @locale), klang: I18n.t('languages.names.' + klang, :locale => @locale)), markup: Menu.vocabularies_menu(@locale) }
				end
				@fb.temp.clear(@chat_id)
				@fb.state.set(@chat_id, 'vocabularies')
				return res
			end
		end
	end

	def vocabulary_new_llang()
		if(@message.text == I18n.t('menu.back', :locale => @locale))
			@fb.state.set(@chat_id, 'vocabularies')
			return { text: I18n.t('vocabularies.info', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }	
		elsif(@message.text == I18n.t('menu.help', :locale => @locale))
			return { text: I18n.t('vocabularies.new.help', :locale => @locale), markup: Menu.language_menu(@locale) }
		else
			lang = Language.check_message(@message.text, @locale)
			if (lang)
				@fb.temp.llang(@chat_id, lang)
				@fb.state.set(@chat_id, 'voc_new_klang')
				return { text: I18n.t('vocabularies.new.know', :locale => @locale), markup: Menu.language_menu(@locale) }
			else
				return { text: I18n.t('vocabularies.new.wrong', :locale => @locale), markup: Menu.language_menu(@locale) }
			end
		end
	end

	def vocabulary_switch_answer()
		@fb.state.set(@chat_id, 'vocabularies')
		if(@message.text == I18n.t('menu.back', :locale => @locale))	
			return { text: I18n.t('vocabularies.info', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		else
			langs = @message.text.split('-')
			if(langs[0] != nil && langs[1] != nil)
				voc_id = @fb.vocs.id(@chat_id, { llang: Language.check_message(langs[0], @locale), klang: Language.check_message(langs[1], @locale) })
				if (voc_id)
					@fb.vocs.activate(@chat_id, voc_id)
					return { text: I18n.t('vocabularies.switch.result.success', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
				end
			end
			return { text: I18n.t('vocabularies.switch.result.error', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		end
	end

	def vocabulary_switch_question()
		vocs = @fb.vocs.all(@chat_id)
		if (vocs && vocs.length > 1)
			@fb.state.set(@chat_id, 'voc_switch')
			return { text: I18n.t('vocabularies.switch.list', :locale => @locale), markup: Menu.vocabulary_list_menu(vocs, @locale) }
		elsif vocs.length == 1
			return { text: I18n.t('vocabularies.switch.one', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		else
			return { text: I18n.t('vocabularies.switch.none', :locale => @locale), markup: Menu.vocabularies_menu(@locale) }
		end
	end

	def words()
		case(@message.text)
		when I18n.t('menu.words.add', :locale => @locale)
			return word_add()
		when I18n.t('menu.words.list', :locale => @locale) 
			return word_list()
		when I18n.t('menu.help', :locale => @locale)
			return { text: I18n.t('words.help', :locale => @locale), markup: Menu.words_menu(@locale) }
		when I18n.t('menu.back', :locale => @locale) 
			@fb.state.set(@chat_id, 'idle')
			return { text: I18n.t('main.info', :locale => @locale), markup: Menu.main_menu(@locale) }	
		else
			return { text: I18n.t('unknown', :locale => @locale), markup: Menu.words_menu(@locale) }
		end
	end

	def word_add()
		@fb.state.set(@chat_id, 'word_add_word')
		return { text: I18n.t('words.new.word', :locale => @locale), markup: Menu.remove() }
	end

	def word_add_question()
		case @message.text
		when I18n.t('answer.positive', :locale => @locale)
			@fb.state.set(@chat_id, 'word_add_translation')
			return { text: I18n.t('words.new.translation', :locale => @locale), markup: Menu.remove() }	
		when I18n.t('answer.negative', :locale => @locale) 
			word = { word: @fb.temp.word(@chat_id), translation: @fb.temp.translation(@chat_id), created_at: Time.now }
			@fb.vocs.words.add(@chat_id, @voc[:id], word)
			@fb.temp.clear(@chat_id)
			@fb.state.set(@chat_id, 'words')
			return { text: I18n.t('words.new.result.success', :locale => @locale, word: word[:word]), markup: Menu.words_menu(@locale) }
		else
			return { text: I18n.t('answer.wrong', :locale => @locale), markup: Menu.yesno(@locale) }
		end
	end

	def word_add_translation()
		@fb.temp.translation(@chat_id, Format.word(@voc[:llang], @message.text.downcase))
		@fb.state.set(@chat_id, 'word_add_question')
		return { text: I18n.t('words.new.more', :locale => @locale), markup: Menu.yesno(@locale) }
	end

	def word_add_word()
		@fb.temp.word(@chat_id, Format.word(@voc[:llang], @message.text.downcase))
		te = Translator.translate(@message.text.downcase, @voc[:klang], @voc[:llang])
		@fb.state.set(@chat_id, 'word_add_translation')
		return { text: I18n.t('words.new.translation', :locale => @locale, possible_translation: te["translationText"]), markup: Menu.remove() }
	end

	def word_list()
		words = @fb.vocs.words.all(@chat_id, @voc[:id])
		text = words.map{ |w| "* " + w[:word] + " - " + w[:translation].join(', ')}.join("\n")
		return { text: I18n.t('words.list', :locale => @locale, num: words.length.to_s, llang: I18n.t('languages.names.' + @voc[:llang], :locale => @locale), klang: I18n.t('languages.names.' + @voc[:klang], :locale => @locale), words: text), markup: Menu.words_menu(@locale) }
	end

	def word_translate_answer()
		te = Translator.translate(@message.text.downcase, @voc[:klang], @voc[:llang])
		translations = te["translationText"].split(" ").map { |t| t.downcase }
		@fb.temp.translated(@chat_id, {word: @message.text.downcase, translation: translations})
		@fb.state.set(@chat_id, 'idle')
		return { text: I18n.t('translate.translation', :locale => @locale, translation: translations.join(", ")), markup: Menu.main_menu(@locale) }
	end

	def word_translate_question()
		@fb.state.set(@chat_id, 'word_translate')
		return { text: I18n.t('translate.word', :locale => @locale), markup: Menu.remove() }
	end
end