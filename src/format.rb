class Format

	def initialize(firebase)
		@firebase = firebase
	end

	def self.word(lang, word)
		case lang
		when 'en'
			english(word)
		when 'ru'
			russian(word)
		when 'es'
			spanish(word)
		when 'fr'
			french(word)
		else
			word
		end
	end

	def self.spanish(word)
		word.gsub(/((un(os|a(s)?)? )|(el )|(la(s)? )|(los ))/, "")
	end

	def self.english(word)
		word.gsub(/((a(n)? )|(the )|(to ))/, "")
	end

	def self.russian(word)
		word
	end

	def self.french(word)
		word
	end

end