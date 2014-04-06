# PROJECT: Better-Google-Tasks
#
# AUTHOR : Niklas Heer <niklas.heer@me.com>, Chris Wiegman
# DATE   : 6.04.2014
# LICENSE: GPL 3.0


#array of google tasks lists
#Array of individual tasks
#Number of tasks to display in the badge
#Number of tasks due today
#Number of overdue tasks
#number of lists parsed

###
Retrieves the manifest file for use in the extension

@param callback
###
getManifest = (callback) ->
	xhr = new XMLHttpRequest()
	xhr.onload = ->
		callback JSON.parse(xhr.responseText)
		return

	xhr.open "GET", "/manifest.json", true
	xhr.send null
	return

###
Gets task and objects counts from Google server
###
updateData = ->
	default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") or TASKS_COUNT #figure out how we should count tasks
	countinterval = localStorage.getItem("com.bit51.chrome.bettergoogletasks.countinterval") or TASKS_COUNTINTERVAL #interval to refresh the badge count
	count_list = localStorage.getItem("com.bit51.chrome.bettergoogletasks.count_list") or TASKS_LIST #show only the lists they want
	default_list = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_list") or TASKS_DEFAULT_LIST #The default tasks list
	updateTaskInterval = countinterval * (1000 * 60)
	badgeCount = 0
	tasksDueToday = 0
	tasksOverdue = 0
	tasks = null
	taskLists = null

	#Set the badge color to grey
	chrome.browserAction.setBadgeBackgroundColor color: [
		200
		200
		200
		153
	]

	#display an "X" in badge count
	chrome.browserAction.setBadgeText text: "..."

	#set the badge popup to let the user know they're not logged in
	chrome.browserAction.setTitle title: "Loading Google Tasks"
	xhr = new XMLHttpRequest()
	xhr.onreadystatechange = ->
		if xhr.readyState is 4 and xhr.status is 200 #success
			taskLists = new Array()
			html = xhr.responseText

			#make sure we have a tasks form to parse
			unless html.indexOf("<form method=\"GET\" action=\"https://mail.google.com/tasks/m\">") is -1
				startpos = undefined
				strlength = undefined
				str = undefined
				currid = undefined
				currtitle = undefined
				i = undefined
				str = html
				strlength = html.length
				startpos = html.indexOf("<option value=")
				i = 0
				while strlength > 0 and startpos > -1
					str = str.substr(startpos + 15, strlength)
					strlength = str.length
					currid = str.substr(0, str.indexOf("\""))
					str = str.substr(str.indexOf(">") + 1, strlength)
					currtitle = str.substr(0, str.indexOf("</option>"))
					strlength = str.length
					startpos = str.indexOf("<option value=")
					if (count_list is "def" and currid is default_list) or count_list is "all"
						if taskLists.length > 0
							j = 0

							while j < taskLists.length
								currid = -1  if taskLists[j].id is currid
								j++
						else
							taskLists[i] =
								id: currid
								title: currtitle
						unless currid is -1
							taskLists[i] =
								id: currid
								title: currtitle
						i++
			if taskLists isnt null and taskLists.length > 0
				checkComplete = ->
					if listCount is taskLists.length
						updateBadge()
						getNotifications()
					else
						chrome.extension.getBackgroundPage()
						window.setTimeout (->
							checkComplete()
							return
						), 1000
					return
				tasks = new Array()
				listCount = 0
				j = 0

				while j < taskLists.length
					getTasks taskLists[j]
					j++
				checkComplete()
		else if xhr.readyState is 4 and xhr.status isnt 200 #status isn't 200: user probably not logged in

			#Set the badge color to grey
			chrome.browserAction.setBadgeBackgroundColor color: [
				200
				200
				200
				153
			]

			#display an "X" in badge count
			chrome.browserAction.setBadgeText text: "X"

			#set the badge popup to let the user know they're not logged in
			chrome.browserAction.setTitle title: "Better Google Tasks - Not Logged In"
			address = "https://mail.google.com/tasks/m"
			window.setTimeout (->
				dataError()
				return
			), 5000
		return

	xhr.open "GET", "https://mail.google.com/tasks/m?pli=1&cache=" + Math.random(), true
	xhr.timeout = 5000
	xhr.send null
	window.setTimeout (->
		updateData()
		return
	), updateTaskInterval
	return
dataError = ->
	frame = document.createElement("iframe")
	frame.setAttribute "src", address
	frame.setAttribute "id", "tasksPage"
	$("#tasksPage").replaceWith frame
	updateData()
	return

###
Get individual tasks
@param array list array of task lists
###
getTasks = (list) ->
	default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") or TASKS_COUNT #figure out how we should count tasks
	todays_date = todaysDate()
	xhr = new XMLHttpRequest()
	xhr.onreadystatechange = ->
		if xhr.readyState is 4 and xhr.status is 200 #success
			html = xhr.responseText
			if html.match(/_setup\((.*)\)\}/)
				data = JSON.parse(RegExp.$1)
				$.each data.t.tasks, (i, val) ->
					if (val.name.length > 0 or (val.notes and val.notes.length > 0) or (val.task_date and val.task_date.length > 0)) and val.completed is false
						tasks.push val
						badgeCount++  if default_count is "all" or (default_count is "today" and val.task_date is todays_date) or (default_count is "past" and parseInt(val.task_date) < parseInt(todays_date)) or (default_count is "presentpast" and parseInt(val.task_date) <= parseInt(todays_date)) or (default_count is "alldates" and (typeof val.task_date isnt "undefined"))
						tasksOverdue++  if parseInt(val.task_date) < parseInt(todays_date)
						tasksDueToday++  if parseInt(val.task_date) is parseInt(todays_date)
					return

			listCount++
		return

	xhr.open "GET", "https://mail.google.com/tasks/ig?listid=" + list.id, true
	xhr.timeout = 5000
	xhr.send null
	return

###
Update the badge count
###
updateBadge = ->
	default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") or TASKS_COUNT #figure out how we should count tasks
	unless default_count is "none"
		if taskLists is null #task lists are invalid. User probably isn't logged in.

			#Set the badge color to grey
			chrome.browserAction.setBadgeBackgroundColor color: [
				200
				200
				200
				153
			]

			#display an "X" in badge count
			chrome.browserAction.setBadgeText text: "X"

			#set the badge popup to let the user know they're not logged in
			chrome.browserAction.setTitle title: "Better Google Tasks - Not Logged In"
			window.setTimeout (->
				updateTasks()
				return
			), 10000
		else #update the badge accordingly
			if badgeCount > 0 #there are tasks

				#make the badge red to show unfinished tasks
				chrome.browserAction.setBadgeBackgroundColor color: [
					153
					0
					0
					153
				]

				#push the task count to the badge
				chrome.browserAction.setBadgeText text: badgeCount.toString()

				#set the badge popup title to number of tasks
				chrome.browserAction.setTitle title: TASKS_TITLE + badgeCount.toString()
			else #there are no tasks
				hide_zero = localStorage.getItem("com.bit51.chrome.bettergoogletasks.hide_zero") or TASKS_ZERO #do we hide the zero count or not

				#set badge color to zero
				chrome.browserAction.setBadgeBackgroundColor color: [
					0
					0
					255
					153
				]

				#set badge popup title to something neutral
				chrome.browserAction.setTitle title: "Google Tasks"
				if hide_zero is "0" #we're supposed to set the badge count
					chrome.browserAction.setBadgeText text: "0"
				else #delete the badge count
					chrome.browserAction.setBadgeText text: ""
	else #the user doesn't want a badge

		#delete the badge text by setting to en empty string
		chrome.browserAction.setBadgeText text: ""

		#set a neutral title
		chrome.browserAction.setTitle title: "Google Tasks"
	return

###
Setup notifications
###
getNotifications = ->
	lastNotify = localStorage.getItem("com.bit51.chrome.bettergoogletasks.last_notify") or 0 #the time of the last update
	if lastNotify < (new Date().getTime() - (1000 * 60 * 60 * 12))
		notify = localStorage.getItem("com.bit51.chrome.bettergoogletasks.notify") or TASKS_NOTIFY #The user selected option for notifications
		localStorage.setItem "com.bit51.chrome.bettergoogletasks.last_notify", new Date().getTime()
		if notify > 0
			ttitle = undefined
			primaryMessage = undefined
			if tasksDueToday > 0 or tasksOverdue > 0
				if tasksDueToday > 0 and tasksOverdue > 0
					if tasksDueToday > 1
						dtt = "Tasks"
						dtm = "tasks"
					else
						dtt = "Task"
						dtm = "task"
					if tasksOverdue > 1
						odt = "Tasks"
						odm = "tasks"
					else
						odt = "Task"
						odm = "task"
					ttitle = "Overdue " + odt + " and " + dtt + " Due Today"
					primaryMessage = "You have " + tasksOverdue + " overdue " + odm + " & " + tasksDueToday + " " + dtm + " due today."
				else if tasksDueToday > 0
					if tasksDueToday > 1
						dtt = "Tasks"
						dtm = "tasks"
					else
						dtt = "Task"
						dtm = "task"
					ttitle = dtt + " Due Today"
					primaryMessage = "You have " + tasksDueToday + " " + dtm + " due today."
				else
					if tasksOverdue > 1
						odt = "Tasks"
						odm = "tasks"
					else
						odt = "Task"
						odm = "task"
					ttitle = "Overdue " + odt
					primaryMessage = "You have " + tasksOverdue + " overdue " + odm + "."
			notificationOptions =
				type: "basic"
				title: ttitle
				message: primaryMessage
				iconUrl: "/images/icon.png"

			chrome.notifications.create "BGT", notificationOptions, ->

	return

###
Returns today's date in the format yyyy/mm/dd
@returns {string}
###
todaysDate = ->
	today = new Date()
	yy = today.getYear()
	mm = today.getMonth() + 1
	dd = today.getDate()

	#y2k safe... really?
	yy += 1900  if yy < 2000

	#pad the month
	mm = "0" + mm  if mm < 10

	#pad the day
	dd = "0" + dd  if dd < 10
	yy.toString() + mm.toString() + dd.toString()
inOpen = ->
	port = chrome.extension.getViews(type: "popup")
	if port.length > 0
		window.setTimeout (->
			inOpen()
			return
		), 5000
	else
		updateData()
	return
taskLists = null
tasks = null
badgeCount = 0
tasksDueToday = 0
tasksOverdue = 0
listCount = 0