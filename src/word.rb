class Word
	@firebase

	def initialize(firebase)
		@firebase = firebase
	end

	def add(chat_id, v_id, data)
		@firebase.set("users/" + chat_id + "/vocs/" + v_id + "/words/" + CGI.escape(data[:word]), data)
	end

	def all(chat_id, v_id)
		words = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words").body.to_a
		return words.map { |w| { id: w[0], word: w[1]['word'], translation: w[1]['translation'].to_a, created_at: w[1]['created_at']}  }
	end

	def get(chat_id, v_id, w_id = nil)
		return @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words/" + w_id + "/word").body if w_id

		words = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words").body.to_a
		if (!words.empty?)
			w = words[rand(words.length)]
			return { id: w[0], word: w[1]['word'] }
		else
			return nil
		end
	end

	def translation(chat_id, v_id, w_id = nil)
		return @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words/" + w_id + "/translation").body.to_a if w_id

		words = @firebase.get("users/" + chat_id + "/vocs/" + v_id + "/words").body.to_a
		if (!words.empty?)
			w = words[rand(words.length)]
			translations = w[1]['translation'].to_a
			t = translations[rand(translations.length)]
			return { id: w[0], translation: t }
		else
			return nil
		end
	end
end