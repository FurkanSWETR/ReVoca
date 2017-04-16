class State
	@firebase

	def initialize(firebase)
		@firebase = firebase
	end

	def now(chat_id)
		@firebase.get("users/" + chat_id + "/state").body
	end

	def set(chat_id, state)
		@firebase.set("users/" + chat_id + "/state", state)	
	end
end