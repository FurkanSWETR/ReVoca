class Word
	@chat_id
	@v_id
	@firebase

	def initialize(chat_id, v_id, firebase)
		@chat_id = chat_id
		@v_id = v_id
		@firebase = firebase
	end

	def add(word)
		@firebase.push(@chat_id + "/vocs/" + @v_id + "/words", word)
	end

	def all()
		words = @firebase.get(@chat_id + "/vocs/" + @v_id + "/words").body.to_a
		return words.map { |w| { id: w[0], word: w[1]['word'], translation: w[1]['translation'].to_a, created_at: w[1]['created_at']}  }
	end

	def get(w_id = nil)
		return @firebase.get(@chat_id + "/vocs/" + @v_id + "/words/" + w_id + "/word").body if w_id

		words = @firebase.get(@chat_id + "/vocs/" + @v_id + "/words").body.to_a
		w = words[rand(words.length)]
		return { id: w[0], word: w[1]['word'] }
	end

	def get_translation(w_id = nil)
		return @firebase.get(@chat_id + "/vocs/" + @v_id + "/words/" + w_id + "/translation").body.to_a if w_id

		words = @firebase.get(@chat_id + "/vocs/" + @v_id + "/words").body.to_a
		w = words[rand(words.length)]
		translations = w[1]['translation'].to_a
		t = translations[rand(translations.length)]
		return { id: w[0], translation: t }
	end
end