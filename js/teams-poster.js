// URL to hook into the Teams API
var webhookUrl = "https://onebbc.webhook.office.com/webhookb2/XXXXXXXX";

// Where is the data stored?
var googleSheetId = '1SAPy0tfzRN66ngdblNeEFhbGy8Q5V96C0DeC9qRo6Wc';
var googleTabName = 'Full Schedule';
var sheets = SpreadsheetApp.openById(googleSheetId);
var today = Utilities.formatDate(new Date(), "GMT+2", "yyyy-MM-dd");
var tomorrow = Utilities.formatDate(new Date(Date.now() + 1000*60*60*24), "GMT+2", "yyyy-MM-dd");

// Get the row number of tomorrow's date
function rowOfDate() {
  var data = sheets.getSheetByName(googleTabName).getDataRange().getValues();
  var rows = [];
  for (var i = 5; i < data.length; i++){
    if(Utilities.formatDate(data[i-1][4], "GMT+2", "yyyy-MM-dd") == tomorrow){
      rows.push(i);
    }
  }
  return(rows);
}

// Get the latest release
function getReleases() {
  currRel = sheets.getRangeByName("releases")
  currFlag = sheets.getRangeByName("flags")
  currImportant = sheets.getRangeByName("important")
  rowNumbers = rowOfDate();
  currReleases = [];
  for (var i = 0; i < rowNumbers.length; i++) {
    // currReleases.push(currFlag.getCell(rowNumbers[i], 1).getValue() + "[" + currRel.getCell(rowNumbers[i], 1).getValue() + "]" + "(" + currRel.getCell(rowNumbers[i], 1).getRichTextValue().getLinkUrl() + ")\n")
    currReleases.push("- " + currFlag.getCell(rowNumbers[i], 1).getValue() + (currImportant.getCell(rowNumbers[i], 1).getValue() === true ? '❗️' : '') + "[" + currRel.getCell(rowNumbers[i], 1).getValue() + "]" + "(" + currRel.getCell(rowNumbers[i], 1).getRichTextValue().getLinkUrl() + ")")
  }
  return(currReleases)
}


// What to post to Teams?
function postToSlack() {
  var release = getReleases();

  var payload = {
    "@type": "MessageCard",
    "@context": "http://schema.org/extensions",
    "themeColor": "0076D7",
    "summary": "Data release calendar",
    "sections": [{
        "activityTitle": "Data releases coming out tomorrow",
        "text": release.join("\r"),
        "markdown": true
    }]
}

  var options = {
    "method" : "post",
    "contentType" : "application/json",
    "payload" : JSON.stringify(payload)
  };

  if (release.length != 0) {
    return UrlFetchApp.fetch(webhookUrl, options)
  }

}
