class Format

	def initialize(firebase)
		@firebase = firebase
	end

	def self.word(lang, word)
		case lang
		when 'ENG'
			english(word)
		when 'RUS'
			russian(word)
		when 'spanish'
			spanish(word)
		when 'FRA'
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