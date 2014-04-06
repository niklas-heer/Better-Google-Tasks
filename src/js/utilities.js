/*
Retrieves the manifest file for use in the extension

@param callback
*/


(function() {
  var badgeCount, dataError, getManifest, getNotifications, getTasks, inOpen, listCount, taskLists, tasks, tasksDueToday, tasksOverdue, todaysDate, updateBadge, updateData;

  getManifest = function(callback) {
    var xhr;
    xhr = new XMLHttpRequest();
    xhr.onload = function() {
      callback(JSON.parse(xhr.responseText));
    };
    xhr.open("GET", "/manifest.json", true);
    xhr.send(null);
  };

  /*
  Gets task and objects counts from Google server
  */


  updateData = function() {
    var badgeCount, count_list, countinterval, default_count, default_list, taskLists, tasks, tasksDueToday, tasksOverdue, updateTaskInterval, xhr;
    default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") || TASKS_COUNT;
    countinterval = localStorage.getItem("com.bit51.chrome.bettergoogletasks.countinterval") || TASKS_COUNTINTERVAL;
    count_list = localStorage.getItem("com.bit51.chrome.bettergoogletasks.count_list") || TASKS_LIST;
    default_list = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_list") || TASKS_DEFAULT_LIST;
    updateTaskInterval = countinterval * (1000 * 60);
    badgeCount = 0;
    tasksDueToday = 0;
    tasksOverdue = 0;
    tasks = null;
    taskLists = null;
    chrome.browserAction.setBadgeBackgroundColor({
      color: [200, 200, 200, 153]
    });
    chrome.browserAction.setBadgeText({
      text: "..."
    });
    chrome.browserAction.setTitle({
      title: "Loading Google Tasks"
    });
    xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      var address, checkComplete, currid, currtitle, html, i, j, listCount, startpos, str, strlength;
      if (xhr.readyState === 4 && xhr.status === 200) {
        taskLists = new Array();
        html = xhr.responseText;
        if (html.indexOf("<form method=\"GET\" action=\"https://mail.google.com/tasks/m\">") !== -1) {
          startpos = void 0;
          strlength = void 0;
          str = void 0;
          currid = void 0;
          currtitle = void 0;
          i = void 0;
          str = html;
          strlength = html.length;
          startpos = html.indexOf("<option value=");
          i = 0;
          while (strlength > 0 && startpos > -1) {
            str = str.substr(startpos + 15, strlength);
            strlength = str.length;
            currid = str.substr(0, str.indexOf("\""));
            str = str.substr(str.indexOf(">") + 1, strlength);
            currtitle = str.substr(0, str.indexOf("</option>"));
            strlength = str.length;
            startpos = str.indexOf("<option value=");
            if ((count_list === "def" && currid === default_list) || count_list === "all") {
              if (taskLists.length > 0) {
                j = 0;
                while (j < taskLists.length) {
                  if (taskLists[j].id === currid) {
                    currid = -1;
                  }
                  j++;
                }
              } else {
                taskLists[i] = {
                  id: currid,
                  title: currtitle
                };
              }
              if (currid !== -1) {
                taskLists[i] = {
                  id: currid,
                  title: currtitle
                };
              }
              i++;
            }
          }
        }
        if (taskLists !== null && taskLists.length > 0) {
          checkComplete = function() {
            if (listCount === taskLists.length) {
              updateBadge();
              getNotifications();
            } else {
              chrome.extension.getBackgroundPage();
              window.setTimeout((function() {
                checkComplete();
              }), 1000);
            }
          };
          tasks = new Array();
          listCount = 0;
          j = 0;
          while (j < taskLists.length) {
            getTasks(taskLists[j]);
            j++;
          }
          checkComplete();
        }
      } else if (xhr.readyState === 4 && xhr.status !== 200) {
        chrome.browserAction.setBadgeBackgroundColor({
          color: [200, 200, 200, 153]
        });
        chrome.browserAction.setBadgeText({
          text: "X"
        });
        chrome.browserAction.setTitle({
          title: "Better Google Tasks - Not Logged In"
        });
        address = "https://mail.google.com/tasks/m";
        window.setTimeout((function() {
          dataError();
        }), 5000);
      }
    };
    xhr.open("GET", "https://mail.google.com/tasks/m?pli=1&cache=" + Math.random(), true);
    xhr.timeout = 5000;
    xhr.send(null);
    window.setTimeout((function() {
      updateData();
    }), updateTaskInterval);
  };

  dataError = function() {
    var frame;
    frame = document.createElement("iframe");
    frame.setAttribute("src", address);
    frame.setAttribute("id", "tasksPage");
    $("#tasksPage").replaceWith(frame);
    updateData();
  };

  /*
  Get individual tasks
  @param array list array of task lists
  */


  getTasks = function(list) {
    var default_count, todays_date, xhr;
    default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") || TASKS_COUNT;
    todays_date = todaysDate();
    xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function() {
      var data, html;
      if (xhr.readyState === 4 && xhr.status === 200) {
        html = xhr.responseText;
        if (html.match(/_setup\((.*)\)\}/)) {
          data = JSON.parse(RegExp.$1);
          $.each(data.t.tasks, function(i, val) {
            if ((val.name.length > 0 || (val.notes && val.notes.length > 0) || (val.task_date && val.task_date.length > 0)) && val.completed === false) {
              tasks.push(val);
              if (default_count === "all" || (default_count === "today" && val.task_date === todays_date) || (default_count === "past" && parseInt(val.task_date) < parseInt(todays_date)) || (default_count === "presentpast" && parseInt(val.task_date) <= parseInt(todays_date)) || (default_count === "alldates" && (typeof val.task_date !== "undefined"))) {
                badgeCount++;
              }
              if (parseInt(val.task_date) < parseInt(todays_date)) {
                tasksOverdue++;
              }
              if (parseInt(val.task_date) === parseInt(todays_date)) {
                tasksDueToday++;
              }
            }
          });
        }
        listCount++;
      }
    };
    xhr.open("GET", "https://mail.google.com/tasks/ig?listid=" + list.id, true);
    xhr.timeout = 5000;
    xhr.send(null);
  };

  /*
  Update the badge count
  */


  updateBadge = function() {
    var default_count, hide_zero;
    default_count = localStorage.getItem("com.bit51.chrome.bettergoogletasks.default_count") || TASKS_COUNT;
    if (default_count !== "none") {
      if (taskLists === null) {
        chrome.browserAction.setBadgeBackgroundColor({
          color: [200, 200, 200, 153]
        });
        chrome.browserAction.setBadgeText({
          text: "X"
        });
        chrome.browserAction.setTitle({
          title: "Better Google Tasks - Not Logged In"
        });
        window.setTimeout((function() {
          updateTasks();
        }), 10000);
      } else {
        if (badgeCount > 0) {
          chrome.browserAction.setBadgeBackgroundColor({
            color: [153, 0, 0, 153]
          });
          chrome.browserAction.setBadgeText({
            text: badgeCount.toString()
          });
          chrome.browserAction.setTitle({
            title: TASKS_TITLE + badgeCount.toString()
          });
        } else {
          hide_zero = localStorage.getItem("com.bit51.chrome.bettergoogletasks.hide_zero") || TASKS_ZERO;
          chrome.browserAction.setBadgeBackgroundColor({
            color: [0, 0, 255, 153]
          });
          chrome.browserAction.setTitle({
            title: "Google Tasks"
          });
          if (hide_zero === "0") {
            chrome.browserAction.setBadgeText({
              text: "0"
            });
          } else {
            chrome.browserAction.setBadgeText({
              text: ""
            });
          }
        }
      }
    } else {
      chrome.browserAction.setBadgeText({
        text: ""
      });
      chrome.browserAction.setTitle({
        title: "Google Tasks"
      });
    }
  };

  /*
  Setup notifications
  */


  getNotifications = function() {
    var dtm, dtt, lastNotify, notificationOptions, notify, odm, odt, primaryMessage, ttitle;
    lastNotify = localStorage.getItem("com.bit51.chrome.bettergoogletasks.last_notify") || 0;
    if (lastNotify < (new Date().getTime() - (1000 * 60 * 60 * 12))) {
      notify = localStorage.getItem("com.bit51.chrome.bettergoogletasks.notify") || TASKS_NOTIFY;
      localStorage.setItem("com.bit51.chrome.bettergoogletasks.last_notify", new Date().getTime());
      if (notify > 0) {
        ttitle = void 0;
        primaryMessage = void 0;
        if (tasksDueToday > 0 || tasksOverdue > 0) {
          if (tasksDueToday > 0 && tasksOverdue > 0) {
            if (tasksDueToday > 1) {
              dtt = "Tasks";
              dtm = "tasks";
            } else {
              dtt = "Task";
              dtm = "task";
            }
            if (tasksOverdue > 1) {
              odt = "Tasks";
              odm = "tasks";
            } else {
              odt = "Task";
              odm = "task";
            }
            ttitle = "Overdue " + odt + " and " + dtt + " Due Today";
            primaryMessage = "You have " + tasksOverdue + " overdue " + odm + " & " + tasksDueToday + " " + dtm + " due today.";
          } else if (tasksDueToday > 0) {
            if (tasksDueToday > 1) {
              dtt = "Tasks";
              dtm = "tasks";
            } else {
              dtt = "Task";
              dtm = "task";
            }
            ttitle = dtt + " Due Today";
            primaryMessage = "You have " + tasksDueToday + " " + dtm + " due today.";
          } else {
            if (tasksOverdue > 1) {
              odt = "Tasks";
              odm = "tasks";
            } else {
              odt = "Task";
              odm = "task";
            }
            ttitle = "Overdue " + odt;
            primaryMessage = "You have " + tasksOverdue + " overdue " + odm + ".";
          }
        }
        notificationOptions = {
          type: "basic",
          title: ttitle,
          message: primaryMessage,
          iconUrl: "/images/icon.png"
        };
        chrome.notifications.create("BGT", notificationOptions, function() {});
      }
    }
  };

  /*
  Returns today's date in the format yyyy/mm/dd
  @returns {string}
  */


  todaysDate = function() {
    var dd, mm, today, yy;
    today = new Date();
    yy = today.getYear();
    mm = today.getMonth() + 1;
    dd = today.getDate();
    if (yy < 2000) {
      yy += 1900;
    }
    if (mm < 10) {
      mm = "0" + mm;
    }
    if (dd < 10) {
      dd = "0" + dd;
    }
    return yy.toString() + mm.toString() + dd.toString();
  };

  inOpen = function() {
    var port;
    port = chrome.extension.getViews({
      type: "popup"
    });
    if (port.length > 0) {
      window.setTimeout((function() {
        inOpen();
      }), 5000);
    } else {
      updateData();
    }
  };

  taskLists = null;

  tasks = null;

  badgeCount = 0;

  tasksDueToday = 0;

  tasksOverdue = 0;

  listCount = 0;

}).call(this);
