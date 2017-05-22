require 'firebase'
require_relative 'voc'
require_relative 'state'
require_relative 'temp'
require_relative 'notify'

class FB
	@@total_users = 0
	@firebase

	@vocs
	@state
	@temp
	@notify

	def initialize(firebase_url)
		@firebase = Firebase::Client.new(firebase_url)

		@vocs = Voc.new(@firebase)
		@state = State.new(@firebase)
		@temp = Temp.new(@firebase)
		@notify = Notify.new(@firebase)
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

	def notify
		@notify
	end

	def locale(chat_id, new_locale = nil)
		if (new_locale)
			@firebase.set("users/" + chat_id + "/locale", new_locale)
		else
			l = @firebase.get("users/" + chat_id + "/locale").body
			l ? l.to_sym : :en
		end
	end
end