function init() as Void
  m.backgroundPoster = m.top.findNode("backgroundPoster")
  m.posterGrid = m.top.findNode("posterGrid")
  m.top.appendChild(m.posterGrid)
  loadGridContent()
end function

function loadGridContent() as Void
  m.jsonLoader = createObject("roSGNode", "DataLoader")
  GRID_DATA_URI = "http://telstrapoc-syddev.appglobe.accedo.tv/roku.json"
  m.jsonLoader.setField("contentUri", GRID_DATA_URI)
  m.jsonLoader.observeField("data", "onDataLoaded")
  m.jsonLoader.control = "RUN"
end function

function onDataLoaded() as Void
  gridData = parseMediaItem(m.jsonLoader.data)
  m.posterGrid.content = gridData
  m.posterGrid.setFocus(true)
end function
