class Language
	@@languages = {
		ENG: ['English', 'Английский', 'Inglés', 'Anglais'],
		RUS: ['Russian', 'Русский', 'Ruso', 'Russe'],
		SPA: ['Spanish', 'Испанский', 'Español', 'Espagnol'],
		FRA: ['French', 'Французский', 'Francés', 'Français']
	}

	def self.check(lang)
		@@languages.values.flatten.index(lang)
	end

	def self.eng
		@@languages[:ENG]
	end

	def self.rus
		@@languages[:RUS]
	end

	def self.spa
		@@languages[:SPA]
	end

	def self.fra
		@@languages[:FRA]
	end
end