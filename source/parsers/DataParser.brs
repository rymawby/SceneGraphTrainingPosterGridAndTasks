function parseMediaItem(data as Object) as Object
  parsedContent = createObject("roSGNode", "ContentNode")
  baseURL = data.baseURL
  for i = 0 to data.mediaItems.count() -1
    gridPoster = createObject("roSGNode", "ContentNode")
    gridPoster.hdgridposterurl = baseURL + data.mediaItems[i].images["2x"]
    parsedContent.appendChild(gridPoster)
  end for
  return parsedContent
end function
