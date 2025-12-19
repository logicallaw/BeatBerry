set scriptPath to POSIX path of (path to resource "start.sh")
set quotedScriptPath to quoted form of scriptPath
set quotedScriptPath to quoted form of scriptPath

tell application "Terminal"
	activate
	do script quotedScriptPath
end tell
