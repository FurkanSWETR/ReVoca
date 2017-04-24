class Language
	@@languages = {
		"en" => ['English', 'Английский', 'Inglés', 'Anglais'],
		"ru" => ['Russian', 'Русский', 'Ruso', 'Russe'],
		"es" => ['Spanish', 'Испанский', 'Español', 'Espagnol'],
		"fr" => ['French', 'Французский', 'Francés', 'Français']
	}

	@@i = 0

	def self.check(lang)
		@@languages.each {|k, v| return k if v.index(lang) }
		return nil
	end

	def self.i=(i)
		@@i = i
	end

	def self.eng
		@@languages["en"][@@i]
	end

	def self.rus
		@@languages["ru"][@@i]
	end

	def self.spa
		@@languages["es"][@@i]
	end

	def self.fra
		@@languages["fr"][@@i]
	end

	def self.name(id)
		case id
		when "en"
			return eng
		when "ru"
			return rus
		when "es"
			return spa
		when "fr"
			return fra
		else
			return "Unknown"
		end
	end
end