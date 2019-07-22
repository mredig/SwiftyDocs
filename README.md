# SwiftyDocs

I wanted to generate some documentation for my Swift projects, but wasn't satisfied with the available tools. Here's what I came up with!

If you like it, it would be wonderful if you would [purchase a compiled copy](https://redeggproductions.com/downloads/swiftydocs/). Even if you just download and build it yourself, it would show appreciation for my work in developing this. If you're strapped for cash, unsatisfied with the product, or just otherwise just don't want to, that's fine too. You are welcome to download a copy of the source and build it yourself at no charge. 

If you have any ideas or enhancements you'd like to contribute, please make a pull request.


### Instructions
![screenshot](https://redeggproductions.com/wp-content/uploads/edd/2019/07/Screen-Shot-2019-07-21-at-12.37.20-AM-768x498.png)

1. Simply open an Xcode project written in Swift (there's no reason it shouldn't be able to work in any other language support by Xcode, but only Swift has been tested/supported officially)
1. Rename the project if desired. This will change the title of the documentation when exporting.
1. Select the minimum access level that should be accounted for during export.
1. The exported items popup will display the resulting selection. This is a read only output.
1. Determine if you want a single page of documentation or a separate page for each entity accessible on the global namespace.
1. Determine if you want raw markdown output, a folder of HTML for easy hosting wherever, or a Dash docset (note that the Dash docset inherently requires a single file of output).
1. Hit export and save your documentation!
