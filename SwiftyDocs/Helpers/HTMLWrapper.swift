//
//  HTMLWrapper.swift
//  SwiftyDocs
//
//  Created by Michael Redig on 7/4/19.
//  Copyright © 2019 Red_Egg Productions. All rights reserved.
//

import Foundation

struct HTMLWrapper {
	static func htmlOutputBefore(withTitle title: String, dependenciesUpADir: Bool) -> String {
		return """
		<!doctype html>
		<html>
			<head>
				<meta charset="utf-8"/>
		<link rel="stylesheet" media="screen" type="text/css" href="\(dependenciesUpADir ? "../" : "")css/markdown-alt.css">
				<title>\(title)</title>
			</head>
			<body>
				<div id="sourceContent" style="display: none ">
		"""
	}

	static func htmlOutputAfter(dependenciesUpADir: Bool) -> String {
		return """
				</div>
				<div id="content" class="markdown-body"></div>
				<script src="\(dependenciesUpADir ? "../" : "")js/marked.min.js"></script>
				<script src="\(dependenciesUpADir ? "../" : "")js/purify.min.js"></script>
				<script>
				var sourceString = document.getElementById('sourceContent').innerHTML

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

				console.log("removed", DOMPurify.removed);
				</script>
			</body>
		</html>
		"""
	}

}
