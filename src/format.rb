class Format
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