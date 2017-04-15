require 'firebase'
require_relative 'voc'
require_relative 'current'

class FB
	@@totalusers = 0

	@chat_id
	@firebase

	@vocs
	@current
	@active

	def initialize(chat_id,firebase_url)
		@chat_id = chat_id.to_s
		@firebase = Firebase::Client.new(firebase_url)

		@active = @firebase.get(@chat_id + "/active").body
		@vocs = Voc.new(@chat_id, @firebase)
		@current = @active ? Current.new(@chat_id, @firebase, @vocs.get(@active)) : nil

		@@totalusers+=1
	end

	def activate(voc_id)
		@firebase.set(@chat_id + "/active", voc_id)
		@active = voc_id
		@current = Current.new(@chat_id, @firebase, @vocs.get(@active))
	end

	def vocs
		@vocs
	end

	def current
		@current
	end

end