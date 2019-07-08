//
//  HTMLWrapper.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/4/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

struct HTMLWrapper {
	private func htmlOutputBefore(withTitle title: String, dependenciesUpADir: Bool, cssFile: String) -> String {
		return """
		<!doctype html>
		<html>
			<head>
				<meta charset="utf-8"/>
				<link rel="stylesheet" media="screen" type="text/css" href="\(dependenciesUpADir ? "../" : "")css/\(cssFile).css">
				<link href="\(dependenciesUpADir ? "../" : "")css/prism.css" rel="stylesheet" />
				<title>\(title)</title>
			</head>
			<body>
				<div id="sourceContent" style="display: none ">

		"""
	}

	private func htmlOutputAfter(dependenciesUpADir: Bool) -> String {
		return """
				</div>
				<div id="content" class="markdown-body"></div>
				<script src="\(dependenciesUpADir ? "../" : "")js/marked.min.js"></script>
				<script src="\(dependenciesUpADir ? "../" : "")js/purify.min.js"></script>
				<script>
					var sourceString = document.getElementById('sourceContent').innerHTML

					marked.setOptions({
						gfm: true,
						breaks: true,
					})

					// Let marked do its normal token generation.
					tokens = marked.lexer( sourceString );

					// Mark all code blocks as already being escaped.
					// This prevents the parser from encoding anything inside code blocks
					tokens.forEach(function( token ) {
					if ( token.type === "code" ) {
							token.escaped = true;
						}
					});

					// Let marked do its normal parsing, but without encoding the code blocks
					var markedDown = marked.parser( tokens );
					markedDown = DOMPurify.sanitize(markedDown);
					document.getElementById('content').innerHTML = markedDown;

					var codeBlocks = document.getElementById('content').getElementsByTagName('code')
					for (codeBlock of codeBlocks) {
						codeBlock.innerText = decodeURIComponent(codeBlock.innerText)
					}

					console.log("removed", DOMPurify.removed);
				</script>
				<script src="\(dependenciesUpADir ? "../" : "")js/prism.js"></script>
			</body>
		</html>
		"""
	}

	func wrapInHTML(markdownString: String, withTitle title: String, cssFile: String, dependenciesUpDir: Bool) -> String {
		return htmlOutputBefore(withTitle: title, dependenciesUpADir: dependenciesUpDir, cssFile: cssFile) + markdownString + htmlOutputAfter(dependenciesUpADir: dependenciesUpDir)
	}

	func generateIndexPage(titled title: String) -> String {

		let template = """
			<!doctype html>
			<html lang="en">
				<head>
					<meta charset="utf-8">
						<meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
					<link rel="stylesheet" href="css/bootstrap.min.css">
					<link rel="stylesheet" media="screen" type="text/css" href="css/styles.css">
					<title>\(title)</title>
				</head>
				<body>
					<nav class="navbar navbar-dark bg-dark">
						<a class="navbar-text navbar-brand" href="doclandingpage.html" target="documentationFrame">\(title) Documentation</a>
						<a class="navbar-text" href="https://github.com/mredig/SwiftyDocs">Made with SwiftyDocs</a>
					</nav>

					<div class="container-fluid">
						<div class="row">
							<div class="col-sm-3 docColumn">
								<iframe id="tableOfContents" src="contents.html" onload="fixLinks()"></iframe>
							</div>
							<div class="col-lg-9 docColumn">
								<iframe id="documentation" src="doclandingpage.html" name="documentationFrame"></iframe>
							</div>
						</div>
					</div>
					<script type="text/javascript">
						function fixLinks() {
							var iframe = document.getElementById('tableOfContents');
							var innerDoc = (iframe.contentDocument) ? iframe.contentDocument : iframe.contentWindow.document;
							//console.log("frame", iframe)
							//console.log("doc", innerDoc)
							var anchors = innerDoc.getElementsByTagName('a');
							for (var i=0; i<anchors.length; i++){
								anchors[i].setAttribute('target', 'documentationFrame');
							}
						}
					</script>
				</body>
			</html>
			"""

		return template
	}

}
