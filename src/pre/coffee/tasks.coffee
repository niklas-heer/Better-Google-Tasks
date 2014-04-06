# PROJECT: Better-Google-Tasks
#
# AUTHOR : Niklas Heer <niklas.heer@gmail.com>, Chris Wiegman
# DATE   : 6.04.2014
# LICENSE: GPL 3.0

###
Find the current tab

@param callback a callback function
###
getTasksTab = (callback) ->
	chrome.tabs.getAllInWindow `undefined`, (tabs) ->
		i = 0
		tab = undefined

		while tab = tabs[i]
			if tab.url and TASKS_URL_RE_.test(tab.url)
				callback tab
				return
			i++
		callback null
		return

	return

###
Handle opening tasks in new window or new tab
###
openTasks = ->
	openbehavior = localStorage.getItem("com.bit51.chrome.bettergoogletasks.openbehavior") or TASKS_OPENBEHAVIOR
	defaultlist = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_list") or TASKS_DEFAULT_LIST
	if openbehavior is "1"
		unless defaultlist is ""
			chrome.windows.create url: "https://mail.google.com/tasks/canvas?listid=" + defaultlist
		else
			chrome.windows.create url: "https://mail.google.com/tasks/canvas"
	else
		unless defaultlist is ""
			chrome.tabs.create url: "https://mail.google.com/tasks/canvas?listid=" + defaultlist
		else
			chrome.tabs.create url: "https://mail.google.com/tasks/canvas"
	window.close()
	return
printTasks = ->
	getTasksTab (tab) ->
		if tab
			chrome.tabs.update tab.id,
				selected: true

		else
			chrome.tabs.create url: "/html/print.html"
		window.close()
		return

	return
closeTasks = ->
	window.close()
	return

###
setup the popup
###
getTaskFrame = ->
	chrome.extension.onConnect.addListener (port) ->
		console.assert port.name is "BGTOpen"
		return

	port = chrome.extension.connect(name: "BGT")
	port.postMessage message: "Open"
	address = undefined
	defaultlist = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_list") or TASKS_DEFAULT_LIST
	default_pop = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_pop") or TASKS_POPUP
	default_width = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_width") or TASKS_WIDTH
	default_height = localStorage.getItem("com.bit51.chrome.bettergoogletasksJSON.parseeval.default_height") or TASKS_HEIGHT
	if default_pop is "full"
		address = "https://mail.google.com/tasks/canvas"
	else
		address = "https://mail.google.com/tasks/ig"
	unless defaultlist is ""
		url = address + "?listid=" + defaultlist
	else
		url = address
	frame = document.createElement("iframe")
	frame.setAttribute "width", default_width
	frame.setAttribute "height", default_height
	frame.setAttribute "frameborder", "0"
	frame.setAttribute "src", url
	document.getElementById("content").appendChild frame
	footer = document.getElementById("footer")
	footer.style.width = (default_width - 6)
	return
$(document).ready ->
	getTaskFrame()
	openbehavior = localStorage.getItem("com.bit51.chrome.bettergoogletasks.openbehavior") or TASKS_OPENBEHAVIOR
	if openbehavior is "1"
		$("#footer").prepend "<span id=\"windowLink\" class=\"link\">Open in New Window <img src=\"/images/external.png\" alt=\"Open tasks in a new window\" /></span> | "
	else
		$("#footer").prepend "<span id=\"windowLink\" class=\"link\">Open in New Tab <img src=\"/images/external.png\" alt=\"Open tasks in a new tab\" /></span> | "
	$("#windowLink").click ->
		openTasks()
		return

	$("#printLink").click ->
		printTasks()
		return

	$("#optionsLink").click ->
		chrome.tabs.create url: chrome.extension.getURL("/html/options.html")
		return

	$("#closeLink").click ->
		closeTasks()
		return

	return
