#More complex components and loading external data

Today I’m going to introduce a `PosterGrid` and how to populate it using external feeds. `PosterGrids` are possibly what you will be using in the majority of apps you develop. I will also introduce `Tasks` - which use Roku’s new multithreaded architecture.

We’ll start with part of what we used yesterday, the background image - but get rid of the menu. What we plan to do is have a `PosterGrid` that when you click on it it updates the background image.

We'll start with something like the following in `MainScene.xml`.

```
<?xml version="1.0" encoding="utf-8" ?>

<component name="MainScene" extends="Scene" >
    <interface>
    </interface>

    <children>

      <Poster
      id="backgroundPoster"
      uri=""
      width="1280"
      height="720"
      translation="[0,0]" />

    </children>
    <script type="text/brightscript" uri="pkg://components/mainScene/MainScene.brs" />
</component>
```

Next we need to add our [PosterGrid](http://sdkdocs.roku.com/display/sdkdoc/PosterGrid) to our Scene. Remember as we want The `PosterGrid` to to be on top of our background image we should put it below in the nesting order, so it gets rendered last.

```
<?xml version="1.0" encoding="utf-8" ?>

<component name="MainScene" extends="Scene" >
    <interface>
    </interface>

    <children>

      <Poster
        id="backgroundPoster"
        uri=""
        width="1280"
        height="720"
        translation="[0, 0]" />

      <PosterGrid
        id="posterGrid"
        translation="[100, 100]"
        basePosterSize="[214, 308]"
        itemSpacing="[15, 32]"
        numColumns="6"
        numRows="1"
        />

    </children>
    <script type="text/brightscript" uri="pkg://components/mainScene/MainScene.brs" />
</component>

```

##Using Tasks
If you run this now you’re going to have the most boring app ever. We need to load in some external data. Let’s load in a json file that contains some info we can use (from a previous project). The files location is `http://telstrapoc-syddev.appglobe.accedo.tv/roku.json`. To load this in we are going to use a `Task`. When a `Task` is instantiated it is spawned in a different thread. This means we can write non-blocking synchronous code for loading data etc - whereas previously this kind of call would’ve had to have been watched for in an event loop - comparing source identities. Here’s a `Task` for loading in data.

```
<component name="DataLoader" extends="Task">

  <interface>
    <field id="contentUri" type="string"/>
    <field id="data" type="assocArray"/>
  </interface>

  <script type="text/brightscript" ><![CDATA[

    function init() as Void
      m.top.functionName = "getContent"
    end function

    function getContent() as Void
      dataTransfer = createObject("roUrlTransfer")
      dataTransfer.setUrl(m.top.contentUri)
      m.top.data = parseJSON(dataTransfer.getToString())
    end function

    ]]></script>

</component>
```

Let’s break it down as `Tasks` can be a little quirky at first. As you can see I have included both xml and Brightscript in the code of the task. I feel this is ok - as it is a bunch of functionality that works together - whereas separating a view from it’s business logic is usually a good idea. In the interface we have the `contentUri` property and the `data` property. The `contentUri` is what we set with the URI of the json file we wish to load and the `data` field is what we will `observe` outside of the `Task` to let us know our data has been loaded.

In the `init` method (again this is like a constructor) we specify the function to call when the `Task` is run - we do this with this line `m.top.functionName = "getContent"`. In the `getContent` function we use a `roUrlTransfer` object to load the data from `m.top.contentUrl` and then set our `data` interface field to the value that was loaded. Note the use of `top` again to access the fields in the interface.

Now we need to run our `Task`. We’ll do this in our `MainScene.brs` file.

```
function init() as Void
  m.backgroundPoster = m.top.findNode("backgroundPoster")
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
  ? m.jsonLoader.data
end function
```

Firstly lets have a look at how we run a `Task` in the `loadGridContent` function. The first line of the function, `createObject("roSGNode", "DataLoader")` creates a SceneGraph node of type `DataLoader`. You'll end up using this method of creating a type of SceneGraph node often when creating elements dynamically.

We then set the interface field `contentUri` to that of the json file we wish to load. If you remember back to our `Task` code above this is used in the `getContent` call.

The line `m.jsonLoader.observeField("data", "onDataLoaded")` sets up an observer on the `data` field and tells that to call the `onDataLoaded` function when this field changes. This was what our `Task` updates when it loads data in.

Finally we tell our task to run with the line `m.jsonLoader.control = "RUN"`. This way of getting a `Task` to run always seems a bit strange to me, I would've thought it'd be a method call - but a lot of the architecture is built around observable fields and native components seem no different.

For the time being in the `onDataLoaded` function we just trace out the loaded data.

##Parsing the data for the PosterGrid

To parse the data I created a parsing function in a different file (`source/parsers/DataParser.brs`). The function looks like this:

```
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
```
This function returns a `ContentNode` as this is what the PosterGrid accepts. To use this function in `MainScene.brs` we need to include the file - so we pop this in `MainScene.xml` - `<script type="text/brightscript" uri="pkg://source/parsers/DataParser.brs" />`. The only item I've set is the `hdgridposterurl` at present.

##Getting the PosterGrid to actually work

Now modify the `MainScene.brs` to look like this:

```
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
```

In the `init` function we find the `PosterGrid` as per usual - `m.posterGrid = m.top.findNode("posterGrid")`. For some reason I had to write `m.top.appendChild(m.posterGrid)` - this appears to be a Roku bug and shouldn't really be needed.

in the `onDataLoaded` function we set our parsed data as the `PosterGrid` content. If we run this all together we get a single row carousel of images.

##Challenges
 - have the movie titles appear over the images of their respective movies
 - update the background image with the `bg-2x` image of its movie. Have it stretched fullscreen (even though the loaded images aren't `1280 x 720`).
 - have the background image fade in
 - split the posters so they are on multiple lines with a maximum of 4 images per row
 - write your own Task to pull in text each time you switch movies. Use something like `http://www.randomtext.me/api/` or whatever you fancy. Show the text on a multiline text field.
