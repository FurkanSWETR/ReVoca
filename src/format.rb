class Format

	def initialize(firebase)
		@firebase = firebase
	end

	def self.word(lang, word)
		case lang
		when 'English'
			english(word)
		when 'Русский'
			russian(word)
		when 'Español'
			spanish(word)
		when 'Français'
			french(word)
		else
			
		end
	end

	def self.spanish(word)
		word.gsub(/((un(os|a(s)?)? )|(el )|(la(s)? )|(los ))/, "")
	end

	def self.english(word)
		word
	end

	def self.russian(word)
		word
	end

	def self.french(word)
		word
	end

end