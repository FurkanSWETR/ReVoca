class Voc
	@chat_id
	@firebase

	def initialize(chat_id,firebase)
		@chat_id = chat_id
		@firebase = firebase
	end

	def create(llang, klang)
		@firebase.push(@chat_id + "/vocs", { :llang => llang, :klang => klang})
	end

	def get_id(llang, klang)
		vocs = all()
		i = vocs.index { |v| v[:llang] == llang && v[:klang] == klang }
		i != nil ? vocs[i][:id] : nil
	end

	def all()
		vocs = @firebase.get(@chat_id + "/vocs").body.to_a
		return vocs.map { |v| { id: v[0], llang: v[1]['llang'], klang: v[1]['klang']} }
	end

	def get(v_id)
		v = @firebase.get(@chat_id + "/vocs/" + v_id).body
		return { id: v_id, llang: v['llang'], klang: v['klang']}
	end
end