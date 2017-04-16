require_relative 'word'

class Voc
	@firebase
	@words

	def initialize(firebase)
		@firebase = firebase
		@words = Word.new(@firebase)
	end

	def create(chat_id, data)
		@firebase.push("users/" + chat_id + "/vocs", data)
	end

	def active(chat_id)
		@firebase.get("users/" + chat_id + "/active").body
	end

	def activate(chat_id, voc_id)
		@firebase.set("users/" + chat_id + "/active", voc_id)
	end

	def all(chat_id)
		vocs = @firebase.get("users/" + chat_id + "/vocs").body.to_a
		return vocs.map { |v| { id: v[0], llang: v[1]['llang'], klang: v[1]['klang']} }
	end

	def get(chat_id, v_id)
		v = @firebase.get("users/" + chat_id + "/vocs/" + v_id).body
		return { id: v_id, llang: v['llang'], klang: v['klang']}
	end

	def id(chat_id, data)
		vocs = all(chat_id)
		i = vocs.index { |v| v[:llang] == data[:llang] && v[:klang] == data[:klang] }
		i != nil ? vocs[i][:id] : nil
	end

	def delete(chat_id, v_id)
		@firebase.delete("users/" + chat_id + "/vocs/" + v_id)
	end

	def words
		@words
	end
end