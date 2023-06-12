#!/usr/bin/env /Users/andras/.local/share/rtx/installs/node/18.16.0/bin/node

// ORI: #!/usr/bin/env /usr/local/bin/node

// <bitbar.title>Sentry</bitbar.title>
// <bitbar.version>v1.0</bitbar.version>
// <bitbar.author>Andras Helyes</bitbar.author>
// <bitbar.author.github>helyes</bitbar.author.github>
// <bitbar.desc>Shows your most recent error reports from Sentry (https://getsentry.com)</bitbar.desc>
// <bitbar.dependencies>node.js</bitbar.dependencies>
// <bitbar.image>TODO!</bitbar.image>

// Add secrets to .secrets.sentry.js
// Example secret file:
//const secrets =
// {
//  auth_token: "12893746128937481234",
//  organization: 'myorg-99',
//  project: 'myproject-121',
//  issue_count: 5,
// }
// module.exports = secrets;
//
const secrets = require("./.secrets.sentry.js");

// jshint asi:true
const https = require("https");

const { auth_token, organization, project, issue_count } = secrets;
const PROJECT_URL = `https://app.getsentry.com/${organization}/${project}`;
const TITLE = [organization + "/" + project, "@", "Sentry"].join(" ");

function statusColor(issue) {
  switch (issue.status) {
    case "resolved":
    case "muted":
      return "green";
    case "unresolved":
      if (issue.assignedTo !== null) {
        return "orange";
      }
  }
  return "red";
}

function timeSince(date) {
  if (typeof date !== "object") {
    date = new Date(date);
  }

  const seconds = Math.floor((new Date() - date) / 1000);
  let intervalType;

  let interval = Math.floor(seconds / 31536000);
  if (interval >= 1) {
    intervalType = "year";
  } else {
    interval = Math.floor(seconds / 2592000);
    if (interval >= 1) {
      intervalType = "month";
    } else {
      interval = Math.floor(seconds / 86400);
      if (interval >= 1) {
        intervalType = "day";
      } else {
        interval = Math.floor(seconds / 3600);
        if (interval >= 1) {
          intervalType = "hour";
        } else {
          interval = Math.floor(seconds / 60);
          if (interval >= 1) {
            intervalType = "minute";
          } else {
            interval = seconds;
            intervalType = "second";
          }
        }
      }
    }
  }
  return `${interval} ${intervalType}${interval !== 1 ? "s" : ""}`;
}

function title(issue) {
  // RuntimeException: java.lang.IllegalStateException: FragmentManager is a… | href=https://<org>.sentry.io/issues/4108196898/ size=11 color=red
  return `${issue.title} | length=80  href=${
    issue.permalink
  } size=11 color=${statusColor(issue)}`;
}

function culprit(issue) {
  // com.facebook.react.animated.NativeAnimatedModule$k in c | size=10
  if (issue.culprit && issue.culprit.length > 0) {
    return `${issue.culprit} | length=81 size=10`;
  } else {
    return "no culprit | size=10";
  }
}

function occurrences(count) {
  // 213 occurrences | size=10
  return `${count} occurence${count === 1 ? "" : "s"} | size=10`;
}

function timeStats(issue) {
  //1 hour ago - 1 month old | size=10
  const lastSeen = timeSince(new Date(issue.lastSeen)) + " ago";
  const firstSeen = timeSince(new Date(issue.firstSeen)) + " old";
  return `${lastSeen} - ${firstSeen} | size=10`;
}

function formatIssue(issue) {
  return [
    title(issue),
    culprit(issue),
    timeStats(issue),
    occurrences(issue.count),
  ].join("\n");
}

function handleResponse(body) {
  const output = body.map(formatIssue).join("\n---\n");
  console.log(
    "Sentry" + "\n---\n" + TITLE + " | href=" + PROJECT_URL + "\n---\n" + output
  );
}

const options = {
  hostname: "sentry.io",
  port: 443,
  path: `/api/0/projects/${organization}/${project}/issues/?statsPeriod=24h&limit=${issue_count}&sort=date`,
  method: "GET",
  headers: {
    Authorization: `Bearer ${auth_token}`,
  },
};

// https.get(API_URL + 'projects/' + ORGANIZATION + '/' + PROJECT + '/issues/?query=is%3Aunresolved&limit=' + issue_count + '&sort=date&statsPeriod=24h', function (res) {
https.get(options, function (res) {
  let body = "";
  res.on("data", function (data) {
    body += data;
  });
  res.on("end", function () {
    // console.log("DATA: ", body)
    handleResponse(JSON.parse(body));
  });
});
