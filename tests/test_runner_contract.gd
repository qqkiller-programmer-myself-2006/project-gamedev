extends "res://tests/test_case.gd"


func test_runner_ignores_its_log_directory_for_activity() -> void:
	var script := FileAccess.get_file_as_string("res://.ai/run-agent.ps1")
	assert_true(script.contains("-and $path -notmatch") and script.contains(".ai[\\\\/]logs"),
		"status log rewrites under .ai/logs must not reset the worktree idle timer")


func test_runner_final_status_reports_the_agent_that_ran_last() -> void:
	var script := FileAccess.get_file_as_string("res://.ai/run-agent.ps1")
	assert_true(script.contains("agent = $actualAgent"))
	assert_true(script.contains("$attempts[-1].agent"))
