require_relative 'word'

class CurrentVoc
	@chat_id
	@firebase

	@words

	@id
	@klang
	@llang

	def initialize(chat_id, firebase, voc)
		@chat_id = chat_id
		@firebase = firebase

		@id = voc.id
		@klang = voc.klang
		@llang = voc.llang

		@words = new Word(@chat_id, @id, @firebase)
	end
end