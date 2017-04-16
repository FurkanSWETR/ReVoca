require 'firebase'
require_relative 'voc'
require_relative 'state'
require_relative 'temp'

class FB
	@@total_users = 0
	@firebase

	@vocs
	@state
	@temp

	def initialize(firebase_url)
		@firebase = Firebase::Client.new(firebase_url)
		@vocs = Voc.new(@firebase)
		@state = State.new(@firebase)
		@temp = Temp.new(@firebase)

		@@total_users+=1
	end

	def set_notifications(chat_id, data = nil)
		if (data)
			@firebase.set("notifications/" + chat_id, data)
		else
			@firebase.delete("notifications/" + chat_id)
		end
	end

	def vocs
		@vocs
	end

	def state
		@state
	end

	def temp
		@temp
	end

	def total_users
		@@total_users
	end

end