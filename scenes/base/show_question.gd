extends Control

var AnswerBoxes = []

# Question
var QuestionData = null
var QuestionId = -1
var QuestionAnswers = []

var AnswerSelected = false

var SelectedAnswerId = -1
var FirstSelectedAnswerId = -1 # to mark which answer has "sure" indicator

# Timer
const TRANSITION_TIME : float = 5.5
var CurrentTime : float = 0.0

# State
enum ShowQuestionState {
	SHOW_QUESTION = 0,
	NEXT_SCENE_TIMER = 1
}
var CurrentPhase = ShowQuestionState.SHOW_QUESTION

####################################################################
#	BASE
####################################################################
func _ready():
	GameState.connect("LOGIC_CORRECT_ANSWER_RECEIVED", self, "_on_correct_answer_received")
	
	var i = 0
	for box in AnswerBoxes:
		box.connect("gui_input", self, "_on_box_clicked", [i, box])
		i += 1

func _process(delta):
	if CurrentPhase == ShowQuestionState.NEXT_SCENE_TIMER:
		self.CurrentTime -= delta
		
		if self.CurrentTime <= 0.0:
			self.queue_free()
			GameState.transition_question_to_waiting()

####################################################################
#	PUBLIC
####################################################################
func init(question):
	self.AnswerBoxes = [
		$AnswerBox1,
		$AnswerBox2,
		$AnswerBox3,
		$AnswerBox4
	]
	
	self.QuestionData = question
	self.QuestionId = question['id']
	self.QuestionAnswers = question['answers']
	
	var i = 0
	for ans in self.QuestionAnswers:
		self.AnswerBoxes[i].set_text(ans)
		i += 1

####################################################################
#	EVENTS
####################################################################
func _on_correct_answer_received(question_id, answer_id):
	# Wrong id
	if question_id != self.QuestionId:
		return
	
	# Show correct answer
	var i = 0
	for box in AnswerBoxes:
		if answer_id == i:
			box.set_correct()
		else:
			box.set_uncorrect()
		i += 1
	
	# Start timer
	CurrentPhase = ShowQuestionState.NEXT_SCENE_TIMER
	CurrentTime = TRANSITION_TIME 

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
			
			GameState.give_answer_send(QuestionId, SelectedAnswerId)
