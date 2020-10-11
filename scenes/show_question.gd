extends Control

var AnswerBoxes = []

var QuestionId = -1
var QuestionAnswers = []
var AnswerSelected = false

var SelectedAnswerId = -1
var FirstSelectedAnswerId = -1 # to mark which answer has "sure" indicator

func _ready():
	GameState.connect("LOGIC_CORRECT_ANSWER_RECEIVED", self, "_on_correct_answer_received")
	
	self.AnswerBoxes = [
		$AnswersBox/AnswerBox1,
		$AnswersBox/AnswerBox2,
		$AnswersBox/AnswerBox3,
		$AnswersBox/AnswerBox4,
	]
	
	var i = 0
	for box in AnswerBoxes:
		box.connect("gui_input", self, "_on_box_clicked", [i, box])

func init(question_id, answers):
	self.QuestionId = question_id
	self.QuestionAnswers = answers
	
	var i = 0
	for ans in self.QuestionAnswers:
		self.AnswerBoxes[i].set_text(ans)
		i += 1

#
#	EVENTS
#
func _on_correct_answer_received(question_id, answer_id):
	if question_id != self.QuestionId:
		return
		
	var i = 0
	for box in AnswerBoxes:
		if answer_id == i:
			box.set_correct()
		else:
			box.set_uncorrect()
		i += 1

func _on_box_clicked(event, box_id, box_ref):
	if event is InputEventMouseButton and event.pressed and event.button_index == BUTTON_LEFT:
		# It is already choosen
		if AnswerSelected:
			return
		
		# Clear sure indicators
		if FirstSelectedAnswerId != box_id:
			for box in AnswerBoxes:
				box.clear_sure_mode()
			FirstSelectedAnswerId = box_id

		# Select answer
		if box_ref.click_on_answer():
			# Set selected answer id
			self.SelectedAnswerId = box_id
			self.AnswerSelected = true
