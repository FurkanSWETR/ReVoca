class Temp
	@firebase

	def initialize(firebase)
		@firebase = firebase
	end

	def clear(chat_id)
		@firebase.delete("users/" + chat_id + "/temp")
	end

	def klang(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/klang", data)
		else
			@firebase.get("users/" + chat_id + "/temp/klang").body
		end
	end

	def llang(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/llang", data)
		else
			@firebase.get("users/" + chat_id + "/temp/llang").body
		end
	end

	def word(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/word", data)
		else
			@firebase.get("users/" + chat_id + "/temp/word").body
		end
	end

	def translation(chat_id, data = nil)
		translations = @firebase.get("users/" + chat_id + "/temp/translation").body.to_a
		if(data)
			@firebase.set("users/" + chat_id + "/temp/translation/" + translations.length.to_s, data)
		else
			translations
		end
	end

	def game_answer(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/game/answer", data)
		else
			@firebase.get("users/" + chat_id + "/temp/game/answer").body.to_a
		end
	end

	def game_score(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/game/score", data)
		else
			@firebase.get("users/" + chat_id + "/temp/game/score").body.to_i
		end
	end

	def sleep_exist(chat_id)
		@firebase.get("users/" + chat_id + "/temp/sleep").body
	end

	def sleep_start(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/sleep/start", data)
		else
			@firebase.get("users/" + chat_id + "/temp/sleep/start").body.to_i
		end
	end

	def sleep_end(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/sleep/end", data)
		else
			@firebase.get("users/" + chat_id + "/temp/sleep/end").body.to_i
		end
	end

	def translated(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/translated", data)
		else
			@firebase.get("users/" + chat_id + "/temp/translated").body
		end
	end
end