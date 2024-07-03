#!/usr/bin/env bash

# Hide cursor and disable echo immediately
tput civis
stty -echo

# Restore cursor and echo on exit
trap 'tput cnorm; stty echo; exit 0' EXIT INT TERM

# Check for required commands
for cmd in tmux figlet boxes lolcat; do
	if ! command -v $cmd &>/dev/null; then
		echo "Error: $cmd is required but not installed. Please install it and try again." >&2
		exit 1
	fi
done

# Function to get the dimensions of the current tmux pane
get_pane_dimensions() {
	tmux display-message -p '#{pane_width} #{pane_height}'
}

# Function to clear the screen and position the cursor
clear_and_position() {
	local height=$1
	local mid_row=$2
	printf '\033[2J\033[3J\033[H' # Clear screen and scrollback buffer
	tput cup $mid_row 0
}

# Function to center the text
center_text() {
	local text="$1"
	local width=$2
	local padding=$(((width - ${#text}) / 2))
	printf "%${padding}s%s\n" "" "$text"
}

# Function to display question and answers
display_question() {
	local question="$1"
	local answers="$2"
	local width=$3
	local height=$4
	local show_answer=$5

	clear_and_position "$height" $((height / 2 - 4))

	center_text "$question" "$width"
	echo

	if [ -n "$answers" ]; then
		IFS=';' read -ra ANSWERS <<<"$answers"
		local max_length=0
		for answer in "${ANSWERS[@]}"; do
			answer=${answer//||/} # Remove || if present
			[[ ${#answer} -gt $max_length ]] && max_length=${#answer}
		done

		local total_width=$((max_length + 4)) # 4 for "x) " and a space
		local padding=$(((width - total_width) / 2))
		local letter='a'
		for answer in "${ANSWERS[@]}"; do
			local display_answer
			if [[ $answer == \|\|*\|\| ]]; then
				answer=${answer//||/} # Remove ||
				[[ $show_answer == true ]] && display_answer="$letter) $answer <--" || display_answer="$letter) $answer"
			else
				display_answer="$letter) $answer"
			fi
			printf "%${padding}s%s\n" "" "$display_answer"
			letter=$(echo "$letter" | tr "a-z" "b-za")
		done
	fi
}

# Main countdown function with quiz
countdown_quiz() {
	local question="$1"
	local answers="$2"
	local dimensions
	local width
	local height

	read -r width height <<<"$(get_pane_dimensions)"

	display_question "$question" "$answers" "$width" "$height" false
	sleep 2

	for i in {5..1}; do
		clear_and_position "$height" $((height / 2 - 4))

		# Generate figlet text, put it in a box, center it, and colorize it
		figlet_output=$(echo "$i" | figlet -f standard)
		boxed_output=$(echo "$figlet_output" | boxes -d stone -p a2v1)
		centered_output=$(echo "$boxed_output" | while IFS= read -r line; do
			center_text "$line" "$width"
		done)
		echo -e "$centered_output" | lolcat -f -s 100 2>/dev/null

		sleep 1
	done

	display_question "$question" "$answers" "$width" "$height" true
	sleep 5
}

# Check if the questions file path is provided
if [ $# -lt 1 ]; then
	echo "Usage: $0 <path_to_questions_file>" >&2
	exit 1
fi

questions_file="$1"

# Check if the file exists
if [ ! -f "$questions_file" ]; then
	echo "Error: Questions file not found at $questions_file" >&2
	exit 1
fi

# Read and process each question
while IFS= read -r line || [[ -n "$line" ]]; do
	eval "question_data=($line)" # This safely parses the line into an array
	if [ ${#question_data[@]} -eq 2 ]; then
		countdown_quiz "${question_data[0]}" "${question_data[1]}"
	fi
done <"$questions_file"

# Clear the screen after all questions
printf '\033[2J\033[3J\033[H'
