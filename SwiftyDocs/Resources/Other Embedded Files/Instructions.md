# Instructions


### Deployment on remote host
This directory is ready to be hosted on any static webhost as is! (you can opt in to remove this file and the other local hosting helpers if you wish.)


### Local access
For local access, however, due to the way that cross site scripting prevention works, you need to run an actual web host for everything to function properly.

* There's a javascript function that modifies all the links in the `contents.html` frame to actually open the links in the main, documentation frame. This function can't reach into the iframe while opened as a regular file in your browser, but instead requires actually being hosted by a server. 
* Attn web devs: this would be a great contribution opportunity to find a way to fix this!
	
Here's how to do it:	

1. Start the local webserver
	* on a Mac (and probably linux), double click `startLocalServer.command`
	* No idea about Windows, but who cares about those doofuses.
1. Open your browser to [`http://localhost:8000`](http://localhost:8000)
	* for Mac, there's a `localhost.webloc` file you can just open.
