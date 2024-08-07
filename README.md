# AstroPix

## Steps to build
1. Clone repo as normal
2. Open *AstroPix.xcodeproj* in XCode
3. Within XCode, **Manage Schemes**, and add the basic AstroPix scheme. (Lack of this probably means I've excluded some important XCode project config from what's in github)
4. Select a delpoyment target, either an actual device you have or a simulator.
5. **Build**
Similarly for running the tests, need to manually add the AstroPixTests or UI tests (currently unused) schemes before you can run those.

## What Would I Have Done Differently?
...if I was doing it all over again, or in less of a rush. In no particular order.
* Probably different name for the app!
* Write docstrings as I go along, instead of leaving them all to do now
* More git commits along the way
* More tests

## Caveats
#### API Key Security
The API key I use to access APOD is not stored in the app, but is not very well hidden either. It's hosted (with some very superficial scrambling) on a server. Not secure. Any even slightly more sensitive usage, such as any form of personal data, would require more careful treatment.

#### YouTube link
Normally pressing on the YouTube logo at the bottom-right of the embedded player (in other apps) opens the video in at-least YouTube in the browser, or (if installed) in the YouTube app. That does not work in my webview player and I don't know why. Possibly some inter-app permissions entitlement missing?

#### Post-processing of info returned from API
Some of the text info returned from the APOD API is a bit messy. There's a minimal attempt to clean this up as follows:
###### Leading spaces
Some of the entires for explanation, or copyright have leading whitespace ('_Like this') which makes the alighment of the text not look quite right. Have made some attempts to remove those.
###### Extraneous info in the explanation
In a slightly unpredctable way, the explanation text sometimes ends in a kind of notice or details which aren't really an explanation of the image. For example: [this image (31st of July)](https://apod.nasa.gov/apod/ap240731.html) has the text "New Mirror: APOD is now available from Brazil in Portuguese" included at the end of the 'explanation' field returned by the API. This seems to be separated from the main explanation by three spaces. There are other places where there are three spaces in explanations, sometimes with some old header-labels (Image Credit, Explanation, etc.). To attempt to clean this up I split the text up into chunks at the places where there are three spaces, then decide that the largest of the chunks is *the* explanation. Better approach would be to either commit a fix to the API itself, or download all the entries and analyse them.

###### Double-spaces in the explanation
Easier to deal with. Also some triple-spaces, which are also removed (see above).

## Would like to build
Some things I thought about while building what I have so far, but didn't, as I'm trying not to get side-tracked, and stick to the brief.
* A scrolling view which lazy-loads the small images. Tapping one of those would take you to the normal view
* Favourites feature
* Sharing feature
* Polling around the publishing time, and notifications for when new image/video is available
* Better error messaging to user on failures
* Localisation of strings
* Fall-back to parsing/fetching direct from APOD in case that the API fails (basically bypassing the API)
* Intention, not *quite* achieved was that the APODContentCache and APODNetworkAccessor would have the same APIs, so you could drop the network accessor in instead of the cache, and have a working app (with no cache). Not beneficial enough to get this working as I'd hoped.
* If we (here) try to access the image for "today", on Friday at 3am, it's still Thursday in the US, so no Friday image is published available yet. Would be nice to code some feedback about that into the app.

## Resources used
* https://blog.jakelee.co.uk/an-introduction-to-the-nasa-apod-api/ -- Good overview of the API with some interesting wrinkles pointed out
* https://www.swiftbysundell.com/articles/caching-in-swift/ -- Did not end up using this approach to caching in the end, but would be better, easier to manage, approach if caching more than one image.
* https://www.swiftyplace.com/blog/swiftui-sheets-modals-bottom-sheets-fullscreen-presentation-in-ios -- Useful primer/refresher on sheets
* https://stackoverflow.com/a/67577296/16966757 -- Using a PDFKit as a way to have a zoomable/dragable full-size image, which seems to be non-trivial (judging from other responses on that question) to get working in pure SwiftUI. Using this approach meant using a UIImage instead of a (more SwiftUI) Image and only converting to an Image when SwiftUI needed one.
* https://sarunw.com/posts/swiftui-webview/ -- WebView which embeds a YouTube player
* https://swiftsenpai.com/swift/async-await-network-requests/ -- I wrote everything using URLSession functions with callbacks. That got painful quickly when trying to deal with cache failures and network failures separately. Re-wrote them with async/await after re-reading this article.
* https://stackoverflow.com/a/27766320/16966757 -- Nice explanation of syntax for docstrings in XCode
