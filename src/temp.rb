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

	def cw_id(chat_id, data = nil)
		if(data)
			@firebase.set("users/" + chat_id + "/temp/cw_id", data)
		else
			@firebase.get("users/" + chat_id + "/temp/cw_id").body
		end
	end
end