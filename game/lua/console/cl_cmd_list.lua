devConsole.registerCommand('test', nil, 'Test command', function(args, argStr)
	return 'Test command: ' .. argStr
end)

devConsole.registerCommand('test_form', {'some_var', 'bebra'}, 'Test command with form', function(args, argStr)
	return 'Test command with form: ' .. argStr
end)