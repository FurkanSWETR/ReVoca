class Word
	@firebase

	def initialize(firebase)
		@firebase = firebase
	end

	def add(chat_id, v_id, data)
		w_id = CGI.escape(data[:word])
		@firebase.set("users/" + chat_id + "/vocs/" + v_id + "/words/" + w_id, data)
	end

	def all(chat_id, v_id)
		words = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words").body.to_a
		return words.map { |word| { 
			id: word[0],
			created_at: Time.parse(word[1]['created_at']),
			translation: word[1]['translation'].to_a,
			word: word[1]['word']
		} 
	}
	end

	def get(chat_id, v_id, w_id)
		word = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words/" +  CGI.escape(w_id)).body if w_id
		return word ? {
			id: w_id,
			created_at: Time.parse(word['created_at']),
			translation: word['translation'].to_a,
			word: word['word']
		} : nil
	end

	def random(chat_id, v_id)
		words = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words").body.to_a
		word = !words.empty? ? words[rand(words.length)] : nil
		return word ? {
			id: word[0],
			created_at: Time.parse(word[1]['created_at']),
			translation: word[1]['translation'].to_a,
			word: word[1]['word']
			} : nil
	end
end