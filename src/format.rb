require 'i18n'

class Format
	def self.tick_every(tick, locale)
		if(tick == 1)
			I18n.t('time.every.hour', :locale => locale, period: tick.to_s)
		elsif (tick < 6)
			I18n.t('time.every.hours_1', :locale => locale, period: tick.to_s)
		elsif (tick < 24)
			I18n.t('time.every.hours_2', :locale => locale, period: tick.to_s)
		elsif (tick == 24)
			I18n.t('time.every.day', :locale => locale, period: (tick/24).to_s)
		elsif (tick == 48)
			I18n.t('time.every.days', :locale => locale, period: (tick/24).to_s)
		else
			I18n.t('time.every.week', :locale => locale, period: (tick/168).to_s)	
		end
	end

	def self.word(lang, word)
		case lang
		when 'en'
			word.gsub(/((a(n)? )|(the )|(to ))/, "")
		when 'ru'
			# todo
			word
		when 'es'
			word.gsub(/((un(os|a(s)?)? )|(el )|(la(s)? )|(los ))/, "")
		when 'fr'
			# todo
			word
		else
			word
		end
	end
end