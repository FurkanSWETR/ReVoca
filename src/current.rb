require_relative 'word'

class Current
	@chat_id
	@firebase

	@words

	@id
	@klang
	@llang

	def initialize(chat_id, firebase, voc)
		@chat_id = chat_id
		@firebase = firebase

		@id = voc[:id]
		@klang = voc[:klang]
		@llang = voc[:llang]

		@words = Word.new(@chat_id, @id, @firebase)
	end

	def words
		@words
	end

	def llang
		@llang
	end

	def klang
		@klang
	end

end