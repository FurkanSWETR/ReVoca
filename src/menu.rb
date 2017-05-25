require 'telegram/bot'
require 'i18n'

class Menu

	def self.daytime_menu(locale)
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.daytime.morning', :locale => locale),
				I18n.t('menu.daytime.day', :locale => locale), 
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.daytime.evening', :locale => locale),
					I18n.t('menu.daytime.night', :locale => locale),  
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.games_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.games.translate', :locale => locale), 
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.games.select', :locale => locale), 
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.games_select_menu(locale, answers) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				answers[0], 
				answers[1], 
				I18n.t('menu.help', :locale => locale)
				],
				[
					answers[2], 
					answers[3], 
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.games_translate_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[ 
				I18n.t('menu.help', :locale => locale),
				I18n.t('menu.back', :locale => locale)
			]
			], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.language_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('languages.flags.en', :locale => locale) + I18n.t('languages.names.en', :locale => locale), 
				I18n.t('languages.flags.ru', :locale => locale) + I18n.t('languages.names.ru', :locale => locale), 
				I18n.t('menu.help', :locale => locale) 
				],
				[
					I18n.t('languages.flags.es', :locale => locale) + I18n.t('languages.names.es', :locale => locale), 
					I18n.t('languages.flags.fr', :locale => locale) + I18n.t('languages.names.fr', :locale => locale), 
					I18n.t('menu.back', :locale => locale), 
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.main_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.main.vocabulary', :locale => locale),
				I18n.t('menu.main.word', :locale => locale), 
				I18n.t('menu.main.settings', :locale => locale)
				],
				[
					I18n.t('menu.main.games', :locale => locale),
					I18n.t('menu.main.translate', :locale => locale),
					I18n.t('menu.help', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.notify_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.notify.hour_one', :locale => locale), 
				I18n.t('menu.notify.hour_two', :locale => locale),
				I18n.t('menu.notify.hour_four', :locale => locale), 
				I18n.t('menu.notify.hour_six', :locale => locale),
				I18n.t('menu.notify.hour_twelve', :locale => locale)				
				],
				[	 
					I18n.t('menu.notify.day', :locale => locale),
					I18n.t('menu.notify.day_two', :locale => locale), 
					I18n.t('menu.notify.week', :locale => locale),
					I18n.t('menu.notify.never', :locale => locale),
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.remove()
		return Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
	end

	def self.settings_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.settings.info', :locale => locale), 
				I18n.t('menu.settings.sleep', :locale => locale),
				I18n.t('menu.settings.notifications', :locale => locale),
				],
				[
					I18n.t('menu.settings.language', :locale => locale),
					I18n.t('menu.help', :locale => locale),
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.time_1_menu(locale, start = 0) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.hour.twelve', :locale => locale) + start.to_s + ":00", 
				I18n.t('menu.hour.one', :locale => locale) + (1+start).to_s + ":00",
				I18n.t('menu.hour.two', :locale => locale) + (2+start).to_s + ":00",
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.hour.three', :locale => locale) + (3+start).to_s + ":00",
					I18n.t('menu.hour.four', :locale => locale) + (4+start).to_s + ":00",
					I18n.t('menu.hour.five', :locale => locale) + (5+start).to_s + ":00",
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.time_2_menu(locale, start = 0) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.hour.six', :locale => locale) + (6+start).to_s + ":00", 
				I18n.t('menu.hour.seven', :locale => locale) + (7+start).to_s + ":00",
				I18n.t('menu.hour.eight', :locale => locale) + (8+start).to_s + ":00",
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.hour.nine', :locale => locale) + (9+start).to_s + ":00",
					I18n.t('menu.hour.ten', :locale => locale) + (10+start).to_s + ":00",
					I18n.t('menu.hour.eleven', :locale => locale) + (11+start).to_s + ":00",
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.vocabularies_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.vocabularies.add', :locale => locale), 
				I18n.t('menu.vocabularies.delete', :locale => locale),
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.vocabularies.list', :locale => locale), 
					I18n.t('menu.vocabularies.switch', :locale => locale), 
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.vocabulary_list_menu(vocs, locale) 
		vocs.map! { |v| Telegram::Bot::Types::KeyboardButton.new(text: I18n.t('languages.flags.' + v[:llang], :locale => locale) + I18n.t('languages.names.' + v[:llang], :locale => locale) + '-' + I18n.t('languages.flags.' + v[:klang], :locale => locale) + I18n.t('languages.names.' + v[:klang], :locale => locale)) }		
		vocs.push(Telegram::Bot::Types::KeyboardButton.new(text: I18n.t('menu.back', :locale => locale)))
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: vocs, resize_keyboard: true)
	end

	def self.words_menu(locale) 
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('menu.words.add', :locale => locale), 
				I18n.t('menu.help', :locale => locale)
				],
				[
					I18n.t('menu.words.list', :locale => locale), 
					I18n.t('menu.back', :locale => locale)
				]
				], resize_keyboard: true, one_time_keyboard: true)
	end

	def self.yesno(locale)
		return Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: [
			[
				I18n.t('answer.positive', :locale => locale), 
				I18n.t('answer.negative', :locale => locale)
			]
			], resize_keyboard: true, one_time_keyboard: true)
	end
end