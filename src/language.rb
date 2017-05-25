require 'i18n'

class Language
	def self.check_message(message, locale)
		flags = I18n.t('languages', :locale => locale)[:flags]
		names = I18n.t('languages', :locale => locale)[:names]
		lang = names.find { |k, n| (flags[k] + n) == message}
		return lang ? lang[0].to_s : nil
	end
end