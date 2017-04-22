class Language
	@@languages = {
		"ENG" => ['English', 'Английский', 'Inglés', 'Anglais'],
		"RUS" => ['Russian', 'Русский', 'Ruso', 'Russe'],
		"SPA" => ['Spanish', 'Испанский', 'Español', 'Espagnol'],
		"FRA" => ['French', 'Французский', 'Francés', 'Français']
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
		@@languages["ENG"][@@i] ? @@languages["ENG"][@@i] : @@languages["ENG"]
	end

	def self.rus
		@@languages["RUS"][@@i]
	end

	def self.spa
		@@languages["SPA"][@@i]
	end

	def self.fra
		@@languages["FRA"][@@i]
	end

	def self.name(id)
		case id
		when "ENG"
			return eng
		when "RUS"
			return rus
		when "SPA"
			return spa
		when "FRA"
			return fra
		else
			return "Unknown"
		end
	end
end